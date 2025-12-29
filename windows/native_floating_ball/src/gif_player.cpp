#include "gif_player.h"
#include <propvarutil.h>
#include <algorithm>
#include <cstdint>
#include <cstring>

static bool MetadataUInt(IWICMetadataQueryReader* reader, const wchar_t* name, UINT* out) {
  if (!reader || !name || !out) return false;
  PROPVARIANT prop;
  PropVariantInit(&prop);
  const HRESULT hr = reader->GetMetadataByName(name, &prop);
  if (FAILED(hr)) {
    PropVariantClear(&prop);
    return false;
  }
  bool ok = true;
  switch (prop.vt) {
  case VT_UI1: *out = prop.bVal; break;
  case VT_UI2: *out = prop.uiVal; break;
  case VT_UI4: *out = prop.ulVal; break;
  case VT_I4:  *out = (prop.lVal < 0) ? 0u : (UINT)prop.lVal; break;
  default: ok = false; break;
  }
  PropVariantClear(&prop);
  return ok;
}

static UINT DelayFromFrame(IWICBitmapFrameDecode* frame) {
  IWICMetadataQueryReader* reader = nullptr;
  if (FAILED(frame->GetMetadataQueryReader(&reader)) || !reader) return 100;
  UINT cs = 0;
  // GIF frame delay located at /grctlext/Delay, unit = 10ms
  const bool ok = MetadataUInt(reader, L"/grctlext/Delay", &cs);
  reader->Release();
  if (!ok) return 100;
  UINT ms = cs * 10u;
  if (ms < 10) ms = 100; // 很多 GIF 用 0/1 表示“默认速度”
  return ms;
}

static UINT DisposalFromFrame(IWICBitmapFrameDecode* frame) {
  IWICMetadataQueryReader* reader = nullptr;
  if (FAILED(frame->GetMetadataQueryReader(&reader)) || !reader) return 0;
  UINT disp = 0;
  MetadataUInt(reader, L"/grctlext/Disposal", &disp);
  reader->Release();
  return disp;
}

static void BlendPremultipliedBGRA(
    std::vector<BYTE>& canvas,
    UINT canvasW,
    UINT canvasH,
    const BYTE* src,
    UINT srcW,
    UINT srcH,
    UINT left,
    UINT top) {
  const UINT canvasStride = canvasW * 4u;
  const UINT srcStride = srcW * 4u;

  const UINT maxW = std::min(srcW, (left < canvasW) ? (canvasW - left) : 0u);
  const UINT maxH = std::min(srcH, (top < canvasH) ? (canvasH - top) : 0u);
  if (maxW == 0 || maxH == 0) return;

  for (UINT y = 0; y < maxH; ++y) {
    BYTE* dstRow = canvas.data() + (top + y) * canvasStride + left * 4u;
    const BYTE* srcRow = src + y * srcStride;
    for (UINT x = 0; x < maxW; ++x) {
      const BYTE sb = srcRow[x * 4u + 0];
      const BYTE sg = srcRow[x * 4u + 1];
      const BYTE sr = srcRow[x * 4u + 2];
      const BYTE sa = srcRow[x * 4u + 3];
      if (sa == 0) continue;
      if (sa == 255) {
        dstRow[x * 4u + 0] = sb;
        dstRow[x * 4u + 1] = sg;
        dstRow[x * 4u + 2] = sr;
        dstRow[x * 4u + 3] = sa;
        continue;
      }

      const BYTE db = dstRow[x * 4u + 0];
      const BYTE dg = dstRow[x * 4u + 1];
      const BYTE dr = dstRow[x * 4u + 2];
      const BYTE da = dstRow[x * 4u + 3];

      const UINT invA = 255u - (UINT)sa;
      dstRow[x * 4u + 0] = (BYTE)((UINT)sb + ((UINT)db * invA + 127u) / 255u);
      dstRow[x * 4u + 1] = (BYTE)((UINT)sg + ((UINT)dg * invA + 127u) / 255u);
      dstRow[x * 4u + 2] = (BYTE)((UINT)sr + ((UINT)dr * invA + 127u) / 255u);
      dstRow[x * 4u + 3] = (BYTE)((UINT)sa + ((UINT)da * invA + 127u) / 255u);
    }
  }
}

static void ClearRectPremultipliedBGRA(
    std::vector<BYTE>& canvas,
    UINT canvasW,
    UINT canvasH,
    UINT left,
    UINT top,
    UINT width,
    UINT height) {
  const UINT canvasStride = canvasW * 4u;
  const UINT maxW = std::min(width, (left < canvasW) ? (canvasW - left) : 0u);
  const UINT maxH = std::min(height, (top < canvasH) ? (canvasH - top) : 0u);
  if (maxW == 0 || maxH == 0) return;

  for (UINT y = 0; y < maxH; ++y) {
    BYTE* dstRow = canvas.data() + (top + y) * canvasStride + left * 4u;
    std::fill(dstRow, dstRow + maxW * 4u, (BYTE)0);
  }
}

GifPlayer::~GifPlayer() {
  for (auto* f : m_frames) if (f) f->Release();
}

bool GifPlayer::Load(IWICImagingFactory* pFactory, const std::wstring& path) {
  for (auto* f : m_frames) if (f) f->Release();
  m_frames.clear();
  m_delaysMs.clear();
  m_width = 0;
  m_height = 0;

  IWICBitmapDecoder* pDecoder = nullptr;
  if (FAILED(pFactory->CreateDecoderFromFilename(path.c_str(), nullptr, GENERIC_READ, WICDecodeMetadataCacheOnLoad, &pDecoder)))
    return false;
  UINT count = 0; pDecoder->GetFrameCount(&count);
  if (count == 0) { pDecoder->Release(); return false; }

  // 先尝试读取 GIF 逻辑画布大小（避免只看到“线条/局部更新”）。
  IWICBitmapFrameDecode* firstFrame = nullptr;
  if (FAILED(pDecoder->GetFrame(0, &firstFrame)) || !firstFrame) {
    pDecoder->Release();
    return false;
  }
  UINT canvasW = 0, canvasH = 0;
  {
    IWICMetadataQueryReader* reader = nullptr;
    if (SUCCEEDED(firstFrame->GetMetadataQueryReader(&reader)) && reader) {
      MetadataUInt(reader, L"/logscrdesc/Width", &canvasW);
      MetadataUInt(reader, L"/logscrdesc/Height", &canvasH);
      reader->Release();
    }
  }
  if (canvasW == 0 || canvasH == 0) firstFrame->GetSize(&canvasW, &canvasH);
  if (canvasW == 0 || canvasH == 0) {
    firstFrame->Release();
    pDecoder->Release();
    return false;
  }
  m_width = canvasW;
  m_height = canvasH;

  std::vector<BYTE> canvas(canvasW * canvasH * 4u, (BYTE)0);
  std::vector<BYTE> prevCanvas;

  for (UINT i = 0; i < count; ++i) {
    IWICBitmapFrameDecode* frame = nullptr;
    if (FAILED(pDecoder->GetFrame(i, &frame)) || !frame) continue;

    UINT left = 0, top = 0;
    UINT disp = DisposalFromFrame(frame);
    UINT frameW = 0, frameH = 0;
    frame->GetSize(&frameW, &frameH);

    IWICMetadataQueryReader* reader = nullptr;
    if (SUCCEEDED(frame->GetMetadataQueryReader(&reader)) && reader) {
      MetadataUInt(reader, L"/imgdesc/Left", &left);
      MetadataUInt(reader, L"/imgdesc/Top", &top);
      reader->Release();
    }

    m_delaysMs.push_back(DelayFromFrame(frame));

    if (disp == 3) {
      prevCanvas = canvas;
    }

    // 解码为 32bppPBGRA，并按 FrameRect 叠加到整张画布上。
    IWICFormatConverter* conv = nullptr;
    if (SUCCEEDED(pFactory->CreateFormatConverter(&conv)) && conv) {
      if (SUCCEEDED(conv->Initialize(frame, GUID_WICPixelFormat32bppPBGRA, WICBitmapDitherTypeNone, nullptr, 0.f, WICBitmapPaletteTypeCustom))) {
        const UINT srcStride = frameW * 4u;
        std::vector<BYTE> src(frameH * srcStride);
        if (SUCCEEDED(conv->CopyPixels(nullptr, srcStride, (UINT)src.size(), src.data()))) {
          BlendPremultipliedBGRA(canvas, canvasW, canvasH, src.data(), frameW, frameH, left, top);
        }
      }
      conv->Release();
    }

    // 把“当前整帧”复制成 IWICBitmap 保存下来（用于后续绘制）。
    IWICBitmap* composed = nullptr;
    if (SUCCEEDED(pFactory->CreateBitmap(canvasW, canvasH, GUID_WICPixelFormat32bppPBGRA, WICBitmapCacheOnLoad, &composed)) && composed) {
      WICRect rect{ 0, 0, (INT)canvasW, (INT)canvasH };
      IWICBitmapLock* lock = nullptr;
      if (SUCCEEDED(composed->Lock(&rect, WICBitmapLockWrite, &lock)) && lock) {
        UINT cb = 0;
        BYTE* data = nullptr;
        UINT stride = 0;
        lock->GetStride(&stride);
        if (SUCCEEDED(lock->GetDataPointer(&cb, &data)) && data && stride >= canvasW * 4u) {
          const UINT rowBytes = canvasW * 4u;
          for (UINT y = 0; y < canvasH; ++y) {
            memcpy(data + y * stride, canvas.data() + y * rowBytes, rowBytes);
          }
        }
        lock->Release();
      }
      m_frames.push_back(composed);
    }

    // 处理 Disposal：对“显示后的下一帧”生效
    if (disp == 2) {
      ClearRectPremultipliedBGRA(canvas, canvasW, canvasH, left, top, frameW, frameH);
    } else if (disp == 3 && prevCanvas.size() == canvas.size()) {
      canvas.swap(prevCanvas);
    }

    frame->Release();
  }

  firstFrame->Release();
  pDecoder->Release();
  return !m_frames.empty();
}

UINT GifPlayer::GetDelayMs(UINT frameIndex) const {
  if (frameIndex >= m_delaysMs.size()) return 100;
  return m_delaysMs[frameIndex];
}

bool GifPlayer::CreateConvertedFrame(IWICImagingFactory* pFactory, UINT frameIndex, IWICFormatConverter** ppConv) {
  if (frameIndex >= m_frames.size()) return false;
  IWICFormatConverter* pConv = nullptr;
  if (FAILED(pFactory->CreateFormatConverter(&pConv))) return false;
  if (FAILED(pConv->Initialize(m_frames[frameIndex], GUID_WICPixelFormat32bppPBGRA, WICBitmapDitherTypeNone, nullptr, 0.f, WICBitmapPaletteTypeCustom))) {
    pConv->Release();
    return false;
  }
  *ppConv = pConv;
  return true;
}
