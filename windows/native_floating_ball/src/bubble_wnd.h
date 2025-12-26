#pragma once
#include <windows.h>
#include <d2d1.h>
#include <dwrite.h>
#include <vector>
#include <string>

class BubbleWindow {
public:
  static ATOM Register(HINSTANCE hInst);
  static HWND Create(HINSTANCE hInst, int x, int y, int w, int h);

  static LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
  LRESULT HandleMessage(HWND, UINT, WPARAM, LPARAM);

  void SetItems(const std::vector<std::wstring>& items);
  void ShowNoActivate(int x, int y, int w, int h);
  void Hide();
  bool IsVisible() const { return m_visible; }

  BubbleWindow(HINSTANCE hInst, HWND hWnd) : m_hInst(hInst), m_hWnd(hWnd) {}

private:
  void Render();
  int HitTest(POINT pt) const;
  void SendOpenTaskToMain(const std::wstring& idStr);
  void StartShowAnim();
  void StartHideAnim();
  void TickAnim();

private:
  HINSTANCE m_hInst{};
  HWND m_hWnd{};
  bool m_visible{false};
  std::vector<std::wstring> m_items; // one per line; format: "<id> <title>"
  std::vector<RECT> m_itemRects;

  // D2D/DWrite + backbuffer
  ID2D1Factory* m_pD2D{nullptr};
  ID2D1HwndRenderTarget* m_hwndRT{nullptr};
  IDWriteFactory* m_pDW{nullptr};
  IDWriteTextFormat* m_pFormat{nullptr};
  HRGN m_hrgn{nullptr};

  // Animation
  bool m_animShowing{false};
  bool m_animHiding{false};
  float m_animT{0.f}; // 0..1
  UINT_PTR m_animTimer{0};
};
