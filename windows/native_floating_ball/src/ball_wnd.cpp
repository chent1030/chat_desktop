#include "ball_wnd.h"
#include <dwmapi.h>
#include <shellscalingapi.h>
#include <cassert>

#pragma comment(lib, "Dwmapi.lib")
#pragma comment(lib, "Shcore.lib")

static const wchar_t* kBallClass = L"NativeFloatingBallWindow";

ATOM BallWindow::Register(HINSTANCE hInst) {
  WNDCLASSEX wc{ sizeof(WNDCLASSEX) };
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = &BallWindow::WndProc;
  wc.hInstance = hInst;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.lpszClassName = kBallClass;
  return RegisterClassEx(&wc);
}

HWND BallWindow::Create(HINSTANCE hInst, int x, int y, int diameter) {
  HWND hWnd = CreateWindowEx(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED,
      kBallClass, L"", WS_POPUP,
      x, y, diameter, diameter,
      nullptr, nullptr, hInst, nullptr);
  return hWnd;
}

BallWindow::BallWindow(HINSTANCE hInst) : m_hInst(hInst) {}
BallWindow::~BallWindow() {
  if (m_pRT) m_pRT->Release();
  if (m_pD2DFactory) m_pD2DFactory->Release();
  if (m_pWIC) m_pWIC->Release();
  if (m_hMemDC) DeleteDC(m_hMemDC);
  if (m_hDIB) DeleteObject(m_hDIB);
}

LRESULT CALLBACK BallWindow::WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  BallWindow* self = reinterpret_cast<BallWindow*>(GetWindowLongPtr(hWnd, GWLP_USERDATA));
  if (msg == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lParam);
    self = new BallWindow(cs->hInstance);
    self->m_hWnd = hWnd;
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

LRESULT BallWindow::HandleMessage(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  switch (msg) {
  case WM_CREATE: {
    // Layered per-pixel alpha, click-through disabled (we need interactivity)
    SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW);
    InitializeD2D();
    // Try load GIF from exe directory: ball.gif
    wchar_t exePath[MAX_PATH]; GetModuleFileName(nullptr, exePath, MAX_PATH);
    wchar_t* slash = wcsrchr(exePath, L'\\'); if (slash) *(slash) = 0;
    std::wstring gifPath = std::wstring(exePath) + L"\\ball.gif";
    m_gif.Load(m_pWIC, gifPath);
    m_frameIndex = 0;
    if (m_gif.FrameCount() > 0) {
      SetTimer(hWnd, m_timerId, m_gif.GetDelayMs(0), nullptr);
    }
    Render();
    return 0;
  }
  case WM_MOUSEMOVE: {
    TRACKMOUSEEVENT tme{ sizeof(TRACKMOUSEEVENT), TME_LEAVE, m_hWnd, 0 };
    TrackMouseEvent(&tme);
    ShowBubble();
    return 0;
  }
  case WM_MOUSELEAVE:
    HideBubble(); return 0;
  case WM_COPYDATA: {
    // Accept UPDATE_TASKS from external sender: dwData=1, payload = L"<id> <title>\n..."
    auto cds = reinterpret_cast<COPYDATASTRUCT*>(lParam);
    if (cds && cds->dwData == 1 && cds->lpData && cds->cbData >= sizeof(wchar_t)) {
      std::wstring payload(reinterpret_cast<const wchar_t*>(cds->lpData), cds->cbData / sizeof(wchar_t));
      // Normalize CRLF
      for (auto& ch : payload) if (ch == L'\r') ch = L'\n';
      std::vector<std::wstring> items;
      size_t start = 0;
      while (start < payload.size()) {
        size_t pos = payload.find(L'\n', start);
        std::wstring line = payload.substr(start, (pos == std::wstring::npos ? payload.size() : pos) - start);
        if (!line.empty()) items.push_back(line);
        if (pos == std::wstring::npos) break; else start = pos + 1;
      }
      EnsureBubble();
      if (m_bubble) {
        m_bubble->SetItems(items);
        // If visible, re-show to refresh content/size
        if (m_bubble->IsVisible()) {
          RECT wr{}; GetWindowRect(m_hWnd, &wr);
          m_bubble->ShowNoActivate(wr.right + 8, wr.top, 280, 28 * (int)items.size() + 20);
        }
      }
      return 0;
    }
    return 0;
  }
  case WM_DPICHANGED:
    OnDpiChanged(hWnd, wParam, lParam); return 0;
  case WM_NCHITTEST: {
    // Draggable by default
    return HTCAPTION;
  }
  case WM_TIMER:
    if (wParam == m_timerId && m_gif.FrameCount() > 0) {
      m_frameIndex = (m_frameIndex + 1) % m_gif.FrameCount();
      KillTimer(hWnd, m_timerId);
      SetTimer(hWnd, m_timerId, m_gif.GetDelayMs(m_frameIndex), nullptr);
      Render();
    }
    return 0;
  case WM_PAINT:
    Render(); return 0;
  }
  return DefWindowProc(hWnd, msg, wParam, lParam);
}

bool BallWindow::InitializeD2D() {
  HRESULT hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_pD2DFactory);
  if (FAILED(hr)) return false;
  hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&m_pWIC));
  if (FAILED(hr)) return false;

  // Create memory DC + DIB
  HDC hdcScreen = GetDC(nullptr);
  m_hMemDC = CreateCompatibleDC(hdcScreen);
  ReleaseDC(nullptr, hdcScreen);

  BITMAPINFO bi{};
  bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth = m_diameter;
  bi.bmiHeader.biHeight = -m_diameter; // top-down
  bi.bmiHeader.biPlanes = 1;
  bi.bmiHeader.biBitCount = 32;
  bi.bmiHeader.biCompression = BI_RGB;
  m_hDIB = CreateDIBSection(m_hMemDC, &bi, DIB_RGB_COLORS, &m_pBits, nullptr, 0);
  SelectObject(m_hMemDC, m_hDIB);

  D2D1_RENDER_TARGET_PROPERTIES props = D2D1::RenderTargetProperties(
      D2D1_RENDER_TARGET_TYPE_DEFAULT,
      D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED),
      96.f, 96.f);
  RECT rc{ 0,0,m_diameter,m_diameter };
  hr = m_pD2DFactory->CreateDCRenderTarget(&props, &m_pRT);
  if (FAILED(hr)) return false;

  m_pRT->BindDC(m_hMemDC, &rc);
  return true;
}

void BallWindow::Render() {
  if (!m_pRT) return;
  RECT rc{ 0,0,m_diameter,m_diameter };
  m_pRT->BindDC(m_hMemDC, &rc);
  m_pRT->BeginDraw();
  m_pRT->Clear(D2D1::ColorF(0, 0.f)); // fully transparent

  // Circular clip layer
  const float r = (m_diameter - 2.f) / 2.f;
  const D2D1_ELLIPSE e = D2D1::Ellipse(D2D1::Point2F((float)m_diameter / 2, (float)m_diameter / 2), r, r);
  ID2D1EllipseGeometry* geo = nullptr;
  m_pD2DFactory->CreateEllipseGeometry(e, &geo);
  ID2D1Layer* layer = nullptr;
  m_pRT->CreateLayer(nullptr, &layer);
  m_pRT->PushLayer(D2D1::LayerParameters(D2D1::InfiniteRect(), geo), layer);

  if (m_gif.FrameCount() > 0) {
    IWICFormatConverter* conv = nullptr;
    if (m_gif.CreateConvertedFrame(m_pWIC, m_frameIndex, &conv)) {
      ID2D1Bitmap* bmp = nullptr;
      if (SUCCEEDED(m_pRT->CreateBitmapFromWicBitmap(conv, nullptr, &bmp))) {
        const float tw = (float)m_diameter;
        const float th = (float)m_diameter;
        const float gw = (float)m_gif.Width();
        const float gh = (float)m_gif.Height();
        // Cover fit: scale to cover circle
        float scale = max(tw / gw, th / gh);
        float dw = gw * scale;
        float dh = gh * scale;
        D2D1_RECT_F dst = D2D1::RectF((tw - dw) / 2.f, (th - dh) / 2.f, (tw - dw) / 2.f + dw, (th - dh) / 2.f + dh);
        m_pRT->DrawBitmap(bmp, dst, 1.f, D2D1_BITMAP_INTERPOLATION_MODE_LINEAR);
        bmp->Release();
      }
      conv->Release();
    }
  } else {
    // Fallback solid circle
    ID2D1SolidColorBrush* brush = nullptr;
    m_pRT->CreateSolidColorBrush(D2D1::ColorF(D2D1::ColorF::RoyalBlue, 1.f), &brush);
    m_pRT->FillEllipse(e, brush);
    brush->Release();
  }

  m_pRT->PopLayer();
  layer->Release();
  geo->Release();

  m_pRT->EndDraw();
  PresentLayered();
}

void BallWindow::PresentLayered() {
  HDC hdcScreen = GetDC(nullptr);
  POINT ptSrc{ 0,0 };
  POINT ptDst{ 0,0 };
  RECT wr{}; GetWindowRect(m_hWnd, &wr); ptDst.x = wr.left; ptDst.y = wr.top;
  SIZE sz{ m_diameter, m_diameter };
  BLENDFUNCTION bf{ AC_SRC_OVER, 0, 255, AC_SRC_ALPHA };
  UpdateLayeredWindow(m_hWnd, hdcScreen, &ptDst, &sz, m_hMemDC, &ptSrc, 0, &bf, ULW_ALPHA);
  ReleaseDC(nullptr, hdcScreen);
}

void BallWindow::OnDpiChanged(HWND hWnd, WPARAM wParam, LPARAM lParam) {
  const RECT* prcNew = reinterpret_cast<RECT*>(lParam);
  SetWindowPos(hWnd, nullptr, prcNew->left, prcNew->top,
               prcNew->right - prcNew->left, prcNew->bottom - prcNew->top,
               SWP_NOZORDER | SWP_NOACTIVATE);
  // Recreate DIB for new size if needed (omitted for brevity)
}

void BallWindow::EnsureBubble() {
  if (!m_hwndBubble) {
    BubbleWindow::Register(m_hInst);
    // Create off-screen; we'll position on show
    m_hwndBubble = BubbleWindow::Create(m_hInst, 0, 0, 280, 180);
    // Attach instance pointer to window user data is handled in its WndProc
    m_bubble = std::unique_ptr<BubbleWindow>(reinterpret_cast<BubbleWindow*>(GetWindowLongPtr(m_hwndBubble, GWLP_USERDATA)));
    if (!m_bubble) {
      // If the instance isn't bound yet (due to GWLP_USERDATA timing), bind manually
      m_bubble.reset(new BubbleWindow(m_hInst, m_hwndBubble));
      SetWindowLongPtr(m_hwndBubble, GWLP_USERDATA, (LONG_PTR)m_bubble.get());
    }
  }
}

void BallWindow::ShowBubble() {
  EnsureBubble();
  RECT wr{}; GetWindowRect(m_hWnd, &wr);
  int x = wr.right + 8; int y = wr.top;
  m_bubble->ShowNoActivate(x, y, 280, 180);
}

void BallWindow::HideBubble() {
  if (m_bubble && m_bubble->IsVisible()) m_bubble->Hide();
}
