#pragma once
#include <wincodec.h>
#include <vector>
#include <string>

class GifPlayer {
public:
  GifPlayer() = default;
  ~GifPlayer();

  bool Load(IWICImagingFactory* pFactory, const std::wstring& path);
  UINT FrameCount() const { return (UINT)m_frames.size(); }
  UINT GetDelayMs(UINT frameIndex) const; // per frame

  // Creates a converter for the requested frame in 32bppPBGRA
  bool CreateConvertedFrame(IWICImagingFactory* pFactory, UINT frameIndex, IWICFormatConverter** ppConv);

  UINT Width() const { return m_width; }
  UINT Height() const { return m_height; }

private:
  // 预合成后的整帧（已按 GIF 的 FrameRect/Disposal 规则叠加），用于直接绘制。
  std::vector<IWICBitmap*> m_frames;
  std::vector<UINT> m_delaysMs;
  UINT m_width{0}, m_height{0};
};
