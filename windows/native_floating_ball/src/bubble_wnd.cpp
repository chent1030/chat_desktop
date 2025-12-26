#include "bubble_wnd.h"
#include <dwmapi.h>
#include <uxtheme.h>
#include <d2d1helper.h>
#include <windowsx.h>
#include <string>

#pragma comment(lib, "Dwmapi.lib")

static const wchar_t* kBubbleClass = L"NativeFloatingBubbleWindow";

ATOM BubbleWindow::Register(HINSTANCE hInst) {
  WNDCLASSEX wc{ sizeof(WNDCLASSEX) };
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = &BubbleWindow::WndProc;
  wc.hInstance = hInst;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.hbrBackground = (HBRUSH)GetStockObject(HOLLOW_BRUSH);
  wc.lpszClassName = kBubbleClass;
  return RegisterClassEx(&wc);
}

HWND BubbleWindow::Create(HINSTANCE hInst, int x, int y, int w, int h) {
  return CreateWindowEx(WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
                        kBubbleClass, L"", WS_POPUP,
                        x, y, w, h, nullptr, nullptr, hInst, nullptr);
}

// Acrylic enable helper
typedef enum _ACCENT_STATE {
  ACCENT_DISABLED = 0,
  ACCENT_ENABLE_GRADIENT = 1,
  ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
  ACCENT_ENABLE_BLURBEHIND = 3,
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4,
  ACCENT_ENABLE_HOSTBACKDROP = 5
} ACCENT_STATE;

typedef struct _ACCENT_POLICY {
  ACCENT_STATE AccentState;
  DWORD AccentFlags;
  DWORD GradientColor;
  DWORD AnimationId;
} ACCENT_POLICY;

typedef enum _WINDOWCOMPOSITIONATTRIB {
  WCA_UNDEFINED = 0,
  WCA_ACCENT_POLICY = 19
} WINDOWCOMPOSITIONATTRIB;

typedef struct _WINDOWCOMPOSITIONATTRIBDATA {
  WINDOWCOMPOSITIONATTRIB Attrib;
  PVOID pvData;
  SIZE_T cbData;
} WINDOWCOMPOSITIONATTRIBDATA;

static BOOL (WINAPI *pSetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA*) = nullptr;

static void EnableAcrylic(HWND hWnd, BYTE opacity /*0-255*/, COLORREF tint = RGB(255,255,255)) {
  if (!pSetWindowCompositionAttribute) {
    HMODULE hUser = GetModuleHandleW(L"user32.dll");
    pSetWindowCompositionAttribute = reinterpret_cast<BOOL(WINAPI*)(HWND, WINDOWCOMPOSITIONATTRIBDATA*)>(
      GetProcAddress(hUser, "SetWindowCompositionAttribute"));
  }
  if (!pSetWindowCompositionAttribute) return;
  // ARGB: A in high byte
  DWORD color = ((DWORD)opacity << 24) | (GetRValue(tint) << 16) | (GetGValue(tint) << 8) | GetBValue(tint);
  ACCENT_POLICY policy{ ACCENT_ENABLE_ACRYLICBLURBEHIND, 0, color, 0 };
  WINDOWCOMPOSITIONATTRIBDATA data{ WCA_ACCENT_POLICY, &policy, sizeof(policy) };
  pSetWindowCompositionAttribute(hWnd, &data);
}

void BubbleWindow::SetItems(const std::vector<std::wstring>& items) {
  m_items = items;
}

void BubbleWindow::ShowNoActivate(int x, int y, int w, int h) {
  SetWindowPos(m_hWnd, HWND_TOPMOST, x, y, w, h, SWP_NOACTIVATE | SWP_SHOWWINDOW);
  // Rounded region (to enable acrylic with round corners)
  if (m_hrgn) { DeleteObject(m_hrgn); m_hrgn = nullptr; }
  m_hrgn = CreateRoundRectRgn(0, 0, w, h, 20, 20);
  SetWindowRgn(m_hWnd, m_hrgn, FALSE);
  // Enable acrylic blur
  EnableAcrylic(m_hWnd, 0xD0, RGB(30,30,30));
  StartShowAnim();
  Render();
  m_visible = true;
}

void BubbleWindow::Hide() {
  StartHideAnim();
}

LRESULT CALLBACK BubbleWindow::WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  BubbleWindow* self = reinterpret_cast<BubbleWindow*>(GetWindowLongPtr(hWnd, GWLP_USERDATA));
  if (msg == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lParam);
    self = new BubbleWindow(cs->hInstance, hWnd);
    SetWindowLongPtr(hWnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    return DefWindowProc(hWnd, msg, wParam, lParam);
  }
  if (!self) return DefWindowProc(hWnd, msg, wParam, lParam);
  if (msg == WM_NCDESTROY) {
    auto res = self->HandleMessage(hWnd, msg, wParam, lParam);
    delete self;
    SetWindowLongPtr(hWnd, GWLP_USERDATA, 0);
    return res;
  }
  return self->HandleMessage(hWnd, msg, wParam, lParam);
}

LRESULT BubbleWindow::HandleMessage(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  switch (msg) {
  case WM_PAINT: {
    PAINTSTRUCT ps; BeginPaint(hWnd, &ps); EndPaint(hWnd, &ps);
    Render();
    return 0;
  }
  case WM_TIMER:
    if (wParam == m_animTimer) { TickAnim(); return 0; }
    break;
  case WM_LBUTTONUP: {
    POINT pt{ GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
    int idx = HitTest(pt);
    if (idx >= 0 && idx < (int)m_items.size()) {
      // Assume item string begins with id: e.g., "42 任务标题"
      std::wstring s = m_items[idx];
      size_t sp = s.find(L' ');
      std::wstring id = (sp == std::wstring::npos) ? s : s.substr(0, sp);
      SendOpenTaskToMain(id);
      Hide();
    }
    return 0;
  }
  }
  return DefWindowProc(hWnd, msg, wParam, lParam);
}

void BubbleWindow::Render() {
  if (!m_visible && !m_animHiding) return;
  RECT rc; GetClientRect(m_hWnd, &rc);
  int w = rc.right - rc.left, h = rc.bottom - rc.top;
  // Init D2D/DWrite once
  if (!m_pD2D) {
    D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_pD2D);
    DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), (IUnknown**)&m_pDW);
  }
  if (!m_hwndRT) {
    D2D1_SIZE_U sz = D2D1::SizeU(w, h);
    D2D1_RENDER_TARGET_PROPERTIES rtp = D2D1::RenderTargetProperties(
        D2D1_RENDER_TARGET_TYPE_DEFAULT,
        D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED),
        96.f, 96.f);
    D2D1_HWND_RENDER_TARGET_PROPERTIES hwndp = D2D1::HwndRenderTargetProperties(m_hWnd, sz, D2D1_PRESENT_OPTIONS_NONE);
    m_pD2D->CreateHwndRenderTarget(&rtp, &hwndp, &m_hwndRT);
  } else {
    m_hwndRT->Resize(D2D1::SizeU(w, h));
  }

  m_hwndRT->BeginDraw();
  m_hwndRT->Clear(D2D1::ColorF(0,0,0,0));

  // Animation params
  float t = m_animT; if (m_animHiding) t = 1.f - t; // hide invert
  float opacity = 0.1f + 0.9f * t;
  float scale = 0.96f + 0.04f * t;
  D2D1_MATRIX_3X2_F mat = D2D1::Matrix3x2F::Scale(scale, scale, D2D1::Point2F(0.f, 0.f));
  m_hwndRT->SetTransform(mat);

  // Frosted card (simulated): rounded rect with subtle gradient and inner border
  ID2D1SolidColorBrush* brush = nullptr; m_hwndRT->CreateSolidColorBrush(D2D1::ColorF(1.f,1.f,1.f, 0.12f * opacity), &brush);
  ID2D1SolidColorBrush* border = nullptr; m_hwndRT->CreateSolidColorBrush(D2D1::ColorF(1.f,1.f,1.f, 0.25f * opacity), &border);
  D2D1_ROUNDED_RECT rr = D2D1::RoundedRect(D2D1::RectF(0.f, 0.f, (float)w, (float)h), 10.f, 10.f);
  m_hwndRT->FillRoundedRectangle(rr, brush);
  m_hwndRT->DrawRoundedRectangle(rr, border, 1.f);
  brush->Release(); border->Release();

  // Text format once
  if (!m_pFormat) m_pDW->CreateTextFormat(L"Segoe UI", nullptr, DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL, 13.f, L"zh-CN", &m_pFormat);
  m_itemRects.clear();
  float y = 10.f; const float lineH = 24.f;
  for (auto& s : m_items) {
    D2D1_RECT_F tr = D2D1::RectF(10.f, y, (float)w - 10.f, y + lineH);
    ID2D1SolidColorBrush* txt = nullptr; m_hwndRT->CreateSolidColorBrush(D2D1::ColorF(1.f,1.f,1.f, 0.95f * opacity), &txt);
    m_hwndRT->DrawTextW(s.c_str(), (UINT)s.size(), m_pFormat, tr, txt, D2D1_DRAW_TEXT_OPTIONS_ENABLE_COLOR_FONT);
    txt->Release();
    RECT hr{ (LONG)(6*scale), (LONG)((y-2)*scale), (LONG)((w-6)*scale), (LONG)((y+lineH+2)*scale) };
    m_itemRects.push_back(hr);
    y += lineH + 4.f;
  }
  m_hwndRT->EndDraw();
}

int BubbleWindow::HitTest(POINT pt) const {
  for (int i = 0; i < (int)m_itemRects.size(); ++i) if (PtInRect(&m_itemRects[i], pt)) return i;
  return -1;
}

void BubbleWindow::SendOpenTaskToMain(const std::wstring& idStr) {
  // Find Flutter main window by class (title may vary)
  HWND hwndMain = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
  if (!hwndMain) hwndMain = FindWindowW(nullptr, nullptr);
  if (!hwndMain) return;
  std::wstring payload = L"{\"action\":\"open_task\",\"taskId\":" + idStr + L"}";
  COPYDATASTRUCT cds{}; cds.dwData = 2; // OPEN_TASK
  cds.cbData = (DWORD)((payload.size() + 1) * sizeof(wchar_t));
  cds.lpData = (PVOID)payload.c_str();
  SendMessageW(hwndMain, WM_COPYDATA, (WPARAM)nullptr, (LPARAM)&cds);
}

void BubbleWindow::StartShowAnim() {
  m_animShowing = true; m_animHiding = false; m_animT = 0.f;
  if (!m_animTimer) m_animTimer = SetTimer(m_hWnd, 101, 16, nullptr);
}
void BubbleWindow::StartHideAnim() {
  if (!m_visible && !m_animShowing) { ShowWindow(m_hWnd, SW_HIDE); return; }
  m_animHiding = true; m_animShowing = false; m_animT = 0.f;
  if (!m_animTimer) m_animTimer = SetTimer(m_hWnd, 101, 16, nullptr);
}
void BubbleWindow::TickAnim() {
  // simple ease-out
  m_animT += 0.08f;
  if (m_animT > 1.f) m_animT = 1.f;
  Render();
  if (m_animT >= 1.f) {
    KillTimer(m_hWnd, m_animTimer); m_animTimer = 0;
    if (m_animHiding) { ShowWindow(m_hWnd, SW_HIDE); m_visible = false; m_animHiding = false; }
    if (m_animShowing) { m_animShowing = false; }
  }
}
