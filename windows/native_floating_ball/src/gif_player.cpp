#include "gif_player.h"
#include <propvarutil.h>

static UINT DelayFromFrame(IWICBitmapFrameDecode* pFrame) {
  IWICMetadataQueryReader* pReader = nullptr;
  if (FAILED(pFrame->GetMetadataQueryReader(&pReader)) || !pReader) return 100;
  PROPVARIANT prop; PropVariantInit(&prop);
  UINT ms = 100; // default 100ms
  // GIF frame delay located at /grctlext/Delay, unit = 10ms
  if (SUCCEEDED(pReader->GetMetadataByName(L"/grctlext/Delay", &prop))) {
    if (prop.vt == VT_UI2 || prop.vt == VT_UI4 || prop.vt == VT_I4) {
      UINT cs = prop.uintVal; // centiseconds
      ms = (cs * 10u);
      if (ms < 10) ms = 100; // clamp to 100ms minimal
    }
  }
  PropVariantClear(&prop);
  pReader->Release();
  return ms;
}

GifPlayer::~GifPlayer() {
  for (auto* f : m_frames) if (f) f->Release();
}

bool GifPlayer::Load(IWICImagingFactory* pFactory, const std::wstring& path) {
  IWICBitmapDecoder* pDecoder = nullptr;
  if (FAILED(pFactory->CreateDecoderFromFilename(path.c_str(), nullptr, GENERIC_READ, WICDecodeMetadataCacheOnLoad, &pDecoder)))
    return false;
  UINT count = 0; pDecoder->GetFrameCount(&count);
  if (count == 0) { pDecoder->Release(); return false; }

  for (UINT i = 0; i < count; ++i) {
    IWICBitmapFrameDecode* pFrame = nullptr;
    if (SUCCEEDED(pDecoder->GetFrame(i, &pFrame)) && pFrame) {
      if (i == 0) {
        pFrame->GetSize(&m_width, &m_height);
      }
      m_frames.push_back(pFrame);
      m_delaysMs.push_back(DelayFromFrame(pFrame));
    }
  }
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

