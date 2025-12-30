#pragma once
#include <windows.h>
#include <d2d1.h>
#include <wincodec.h>
#include <memory>
#include <string>
#include "gif_player.h"
#include "bubble_wnd.h"

#pragma comment(lib, "d2d1.lib")
#pragma comment(lib, "windowscodecs.lib")

class BallWindow {
public:
  static ATOM Register(HINSTANCE hInst);
  static HWND Create(HINSTANCE hInst, int x, int y, int diameter);

private:
  explicit BallWindow(HINSTANCE hInst);
  ~BallWindow();

  static LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);
  LRESULT HandleMessage(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

  bool InitializeD2D();
  bool CreateRenderTarget(D2D1_RENDER_TARGET_TYPE type);
  void Render();
  void PresentLayered();

  void OnDpiChanged(HWND hWnd, WPARAM wParam, LPARAM lParam);
  void PositionBottomRight();
  void PositionInitial();
  bool LoadSavedPosition(POINT* ptOut);
  void SaveCurrentPosition();
  void ClampToWorkArea(POINT* ptInOut);
  std::wstring GetSettingsPath() const;
  std::wstring GetLogPath() const;
  void LogLine(const std::wstring& line) const;
  void LogHr(const wchar_t* where, HRESULT hr) const;
  void LogLastError(const wchar_t* where) const;
  void EnsureBorderlessStyle();
  void LoadGifs();
  void SelectGifByUnread();
  void OpenMainApp();

private:
  HINSTANCE m_hInst{};
  HWND m_hWnd{};
  int m_diameter{120};
  UINT m_frameIndex{0};
  UINT m_timerId{1};
  GifPlayer m_gifUnread;
  GifPlayer m_gifDynamic;
  GifPlayer* m_activeGif{nullptr};
  int m_unreadCount{0};
  HWND m_hwndBubble{nullptr};
  std::unique_ptr<BubbleWindow> m_bubble;
  void EnsureBubble();
  void ShowBubble();
  void HideBubble();

  // D2D / WIC
  ID2D1Factory* m_pD2DFactory{nullptr};
  ID2D1DCRenderTarget* m_pRT{nullptr};
  IWICImagingFactory* m_pWIC{nullptr};
  D2D1_RENDER_TARGET_TYPE m_rtType{D2D1_RENDER_TARGET_TYPE_SOFTWARE};

  // Back buffer (GDI)
  HBITMAP m_hDIB{nullptr};
  HDC m_hMemDC{nullptr};
  void* m_pBits{nullptr};
};
