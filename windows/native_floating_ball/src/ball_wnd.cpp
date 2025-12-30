#include "ball_wnd.h"
#include <dwmapi.h>
#include <shellscalingapi.h>
#include <shlobj.h>
#include <cassert>
#include <algorithm>
#include <fstream>
#include <sstream>

#pragma comment(lib, "Dwmapi.lib")
#pragma comment(lib, "Shcore.lib")

static const wchar_t* kBallClass = L"NativeFloatingBallWindow";
static const wchar_t* kFlutterMainClass = L"FLUTTER_RUNNER_WIN32_WINDOW";

static std::wstring HrToString(HRESULT hr) {
  std::wstringstream ss;
  ss << L"0x" << std::hex << (unsigned long)hr;
  return ss.str();
}

struct BallCreateParams {
  int diameter{120};
};

static HWND FindFlutterMainWindow() {
  struct Ctx {
    HWND found{nullptr};
  } ctx;
  EnumWindows(
      [](HWND hWnd, LPARAM lp) -> BOOL {
        auto* c = reinterpret_cast<Ctx*>(lp);
        wchar_t cls[256]{0};
        if (GetClassNameW(hWnd, cls, (int)(sizeof(cls) / sizeof(cls[0])))) {
          if (wcscmp(cls, kFlutterMainClass) == 0) {
            c->found = hWnd;
            return FALSE; // stop
          }
        }
        return TRUE; // continue
      },
      reinterpret_cast<LPARAM>(&ctx));
  return ctx.found;
}

static void ActivateToForeground(HWND hWnd) {
  if (!hWnd || !IsWindow(hWnd)) return;

  // 确保窗口可见（很多情况下主程序是 hide 而不是 minimize）
  ShowWindow(hWnd, SW_SHOW);
  ShowWindow(hWnd, SW_RESTORE);

  // 提升到顶层并请求前台
  SetWindowPos(hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

  // 解决跨进程 SetForegroundWindow 可能失败的问题：临时绑定输入队列
  const DWORD selfThread = GetCurrentThreadId();
  DWORD targetThread = 0;
  GetWindowThreadProcessId(hWnd, &targetThread);
  const HWND hFore = GetForegroundWindow();
  DWORD foreThread = 0;
  if (hFore) GetWindowThreadProcessId(hFore, &foreThread);

  if (targetThread) AttachThreadInput(selfThread, targetThread, TRUE);
  if (foreThread) AttachThreadInput(selfThread, foreThread, TRUE);

  SetForegroundWindow(hWnd);
  SetActiveWindow(hWnd);
  SetFocus(hWnd);
  BringWindowToTop(hWnd);

  if (targetThread) AttachThreadInput(selfThread, targetThread, FALSE);
  if (foreThread) AttachThreadInput(selfThread, foreThread, FALSE);
}

static void SendRestoreRequest(HWND hWnd) {
  if (!hWnd || !IsWindow(hWnd)) return;
  // 约定：dwData=3 表示“恢复主窗口”（由 Runner 进程自行 Show/Restore/Foreground）
  const wchar_t* payload = L"restore_main_window";
  COPYDATASTRUCT cds{};
  cds.dwData = 3;
  cds.cbData = (DWORD)((wcslen(payload) + 1) * sizeof(wchar_t));
  cds.lpData = (PVOID)payload;
  SendMessageW(hWnd, WM_COPYDATA, 0, (LPARAM)&cds);
}

ATOM BallWindow::Register(HINSTANCE hInst) {
  WNDCLASSEX wc{ sizeof(WNDCLASSEX) };
  wc.style = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS; // enable double click
  wc.lpfnWndProc = &BallWindow::WndProc;
  wc.hInstance = hInst;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.lpszClassName = kBallClass;
  return RegisterClassEx(&wc);
}

HWND BallWindow::Create(HINSTANCE hInst, int x, int y, int diameter) {
  BallCreateParams params{};
  params.diameter = diameter;
  HWND hWnd = CreateWindowEx(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED,
      kBallClass, L"", WS_POPUP,
      x, y, diameter, diameter,
      nullptr, nullptr, hInst, &params);
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
    if (cs->lpCreateParams) {
      auto* p = reinterpret_cast<BallCreateParams*>(cs->lpCreateParams);
      self->m_diameter = p->diameter;
    }
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
    PositionInitial();
    EnsureBorderlessStyle();
    InitializeD2D();
    // Load GIFs (with fallbacks)
    LoadGifs();
    SelectGifByUnread();
    m_frameIndex = 0;
    if (m_activeGif && m_activeGif->FrameCount() > 0) {
      SetTimer(hWnd, m_timerId, m_activeGif->GetDelayMs(0), nullptr);
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
  case WM_LBUTTONDBLCLK:
    OpenMainApp(); return 0;
  case WM_NCLBUTTONDBLCLK:
    // 当前窗口在 WM_NCHITTEST 中返回 HTCAPTION，双击会走非客户区消息
    OpenMainApp(); return 0;
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
      // Unread count = items count
      m_unreadCount = (int)items.size();
      SelectGifByUnread();
      m_frameIndex = 0;
      if (m_activeGif && m_activeGif->FrameCount() > 0) {
        KillTimer(m_hWnd, m_timerId);
        SetTimer(m_hWnd, m_timerId, m_activeGif->GetDelayMs(0), nullptr);
      }
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
  case WM_DISPLAYCHANGE:
  case WM_SETTINGCHANGE:
    // 分辨率/缩放/任务栏位置变化后，重新贴右下角
    PositionBottomRight();
    EnsureBorderlessStyle();
    return 0;
  case WM_EXITSIZEMOVE:
    // 用户拖拽结束后保存位置，下次启动自动回放
    SaveCurrentPosition();
    return 0;
  case WM_NCHITTEST: {
    // 必须返回 HTCLIENT，否则鼠标事件会走非客户区消息（WM_NC*），导致 WM_MOUSEMOVE 等不触发，
    // 表现为“悬停/点击没反应”。拖拽在 WM_LBUTTONDOWN 中手动触发。
    return HTCLIENT;
  }
  case WM_LBUTTONDOWN: {
    // 手动进入系统拖拽（保持 HTCLIENT 的同时支持拖动窗口）
    ReleaseCapture();
    SendMessageW(hWnd, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
    return 0;
  }
  case WM_TIMER:
    if (wParam == m_timerId && m_activeGif && m_activeGif->FrameCount() > 0) {
      m_frameIndex = (m_frameIndex + 1) % m_activeGif->FrameCount();
      KillTimer(hWnd, m_timerId);
      SetTimer(hWnd, m_timerId, m_activeGif->GetDelayMs(m_frameIndex), nullptr);
      Render();
    }
    return 0;
  case WM_PAINT:
    Render(); return 0;
  }
  return DefWindowProc(hWnd, msg, wParam, lParam);
}

std::wstring BallWindow::GetSettingsPath() const {
  PWSTR appData = nullptr;
  std::wstring path;
  if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &appData)) && appData) {
    path = appData;
    CoTaskMemFree(appData);
    path += L"\\chat_desktop";
    CreateDirectoryW(path.c_str(), nullptr);
    path += L"\\native_floating_ball_pos.txt";
  }
  return path;
}

std::wstring BallWindow::GetLogPath() const {
  std::wstring path = GetSettingsPath();
  if (path.empty()) return path;
  const std::wstring suffix = L"native_floating_ball_pos.txt";
  if (path.size() >= suffix.size() &&
      path.compare(path.size() - suffix.size(), suffix.size(), suffix) == 0) {
    path.resize(path.size() - suffix.size());
    path += L"native_floating_ball.log";
    return path;
  }
  path += L".log";
  return path;
}

void BallWindow::LogLine(const std::wstring& line) const {
  const std::wstring path = GetLogPath();
  if (path.empty()) return;

  std::wofstream out(path, std::ios::app);
  if (!out.is_open()) return;
  out << line << L"\n";
}

void BallWindow::LogHr(const wchar_t* where, HRESULT hr) const {
  if (!where) return;
  std::wstring line = L"[native_floating_ball] ";
  line += where;
  line += L" hr=";
  line += HrToString(hr);
  LogLine(line);
}

void BallWindow::LogLastError(const wchar_t* where) const {
  if (!where) return;
  const DWORD err = GetLastError();
  std::wstringstream ss;
  ss << L"[native_floating_ball] " << where << L" GetLastError=" << err;
  LogLine(ss.str());
}

void BallWindow::EnsureBorderlessStyle() {
  if (!m_hWnd) return;

  LONG_PTR style = GetWindowLongPtrW(m_hWnd, GWL_STYLE);
  LONG_PTR exStyle = GetWindowLongPtrW(m_hWnd, GWL_EXSTYLE);

  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
  style |= WS_POPUP;

  exStyle |= (WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_TOPMOST);

  SetWindowLongPtrW(m_hWnd, GWL_STYLE, style);
  SetWindowLongPtrW(m_hWnd, GWL_EXSTYLE, exStyle);

  SetWindowPos(
      m_hWnd, nullptr, 0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
}

bool BallWindow::LoadSavedPosition(POINT* ptOut) {
  if (!ptOut) return false;
  const std::wstring path = GetSettingsPath();
  if (path.empty()) return false;

  std::wifstream in(path);
  if (!in.is_open()) return false;
  long x = 0, y = 0;
  in >> x >> y;
  if (!in.good()) return false;
  ptOut->x = (LONG)x;
  ptOut->y = (LONG)y;
  return true;
}

void BallWindow::SaveCurrentPosition() {
  if (!m_hWnd) return;
  const std::wstring path = GetSettingsPath();
  if (path.empty()) return;

  RECT wr{};
  if (!GetWindowRect(m_hWnd, &wr)) return;
  std::wofstream out(path, std::ios::trunc);
  if (!out.is_open()) return;
  out << wr.left << L" " << wr.top;
}

void BallWindow::ClampToWorkArea(POINT* ptInOut) {
  if (!ptInOut) return;
  // 以目标点所在显示器为准；若不在任何显示器上，则用最近的显示器
  const HMONITOR mon = MonitorFromPoint(*ptInOut, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi{ sizeof(mi) };
  if (!GetMonitorInfoW(mon, &mi)) return;

  const int minX = mi.rcWork.left;
  const int minY = mi.rcWork.top;
  const int maxX = mi.rcWork.right - m_diameter;
  const int maxY = mi.rcWork.bottom - m_diameter;

  if (ptInOut->x < minX) ptInOut->x = minX;
  if (ptInOut->y < minY) ptInOut->y = minY;
  if (ptInOut->x > maxX) ptInOut->x = maxX;
  if (ptInOut->y > maxY) ptInOut->y = maxY;
}

void BallWindow::PositionInitial() {
  POINT pt{};
  if (LoadSavedPosition(&pt)) {
    ClampToWorkArea(&pt);
    SetWindowPos(m_hWnd, HWND_TOPMOST, pt.x, pt.y, m_diameter, m_diameter, SWP_NOACTIVATE | SWP_SHOWWINDOW);
    return;
  }
  PositionBottomRight();
}

void BallWindow::PositionBottomRight() {
  if (!m_hWnd) return;
  const HMONITOR mon = MonitorFromWindow(m_hWnd, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi{ sizeof(mi) };
  if (!GetMonitorInfoW(mon, &mi)) return;

  const UINT dpi = GetDpiForWindow(m_hWnd);
  const int margin = MulDiv(18, (int)dpi, 96); // 距离右下角的边距（可按体验调整）
  const int x = mi.rcWork.right - m_diameter - margin;
  const int y = mi.rcWork.bottom - m_diameter - margin;

  SetWindowPos(m_hWnd, HWND_TOPMOST, x, y, m_diameter, m_diameter, SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

bool BallWindow::InitializeD2D() {
  HRESULT hr = S_OK;
  if (!m_pD2DFactory) {
    hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_pD2DFactory);
    if (FAILED(hr)) {
      LogHr(L"D2D1CreateFactory", hr);
      return false;
    }
  }
  if (!m_pWIC) {
    hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&m_pWIC));
    if (FAILED(hr)) {
      LogHr(L"CoCreateInstance(WICImagingFactory)", hr);
      return false;
    }
  }

  // Create memory DC + DIB
  if (!m_hMemDC) {
    HDC hdcScreen = GetDC(nullptr);
    m_hMemDC = CreateCompatibleDC(hdcScreen);
    ReleaseDC(nullptr, hdcScreen);
  }

  if (!m_hDIB) {
    BITMAPINFO bi{};
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = m_diameter;
    bi.bmiHeader.biHeight = -m_diameter; // top-down
    bi.bmiHeader.biPlanes = 1;
    bi.bmiHeader.biBitCount = 32;
    bi.bmiHeader.biCompression = BI_RGB;
    m_hDIB = CreateDIBSection(m_hMemDC, &bi, DIB_RGB_COLORS, &m_pBits, nullptr, 0);
    if (!m_hDIB) {
      LogLastError(L"CreateDIBSection");
      return false;
    }
    SelectObject(m_hMemDC, m_hDIB);
  }

  // 为了在部分核显/企业版系统上更稳定，默认使用 SOFTWARE 渲染（悬浮球很小，性能足够）。
  m_rtType = D2D1_RENDER_TARGET_TYPE_SOFTWARE;
  return CreateRenderTarget(m_rtType);
}

bool BallWindow::CreateRenderTarget(D2D1_RENDER_TARGET_TYPE type) {
  if (!m_pD2DFactory || !m_hMemDC) return false;

  if (m_pRT) {
    m_pRT->Release();
    m_pRT = nullptr;
  }

  D2D1_RENDER_TARGET_PROPERTIES props = D2D1::RenderTargetProperties(
      type,
      D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED),
      96.f, 96.f);
  const RECT rc{ 0,0,m_diameter,m_diameter };
  const HRESULT hr = m_pD2DFactory->CreateDCRenderTarget(&props, &m_pRT);
  if (FAILED(hr) || !m_pRT) {
    LogHr(L"CreateDCRenderTarget", hr);
    return false;
  }
  m_pRT->BindDC(m_hMemDC, &rc);
  return true;
}

void BallWindow::Render() {
  if (!m_pRT) {
    if (!CreateRenderTarget(m_rtType)) return;
  }
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

  if (m_activeGif && m_activeGif->FrameCount() > 0) {
    IWICFormatConverter* conv = nullptr;
    if (m_activeGif->CreateConvertedFrame(m_pWIC, m_frameIndex, &conv)) {
      ID2D1Bitmap* bmp = nullptr;
      if (SUCCEEDED(m_pRT->CreateBitmapFromWicBitmap(conv, nullptr, &bmp))) {
        const float tw = (float)m_diameter;
        const float th = (float)m_diameter;
        const float gw = (float)m_activeGif->Width();
        const float gh = (float)m_activeGif->Height();
        // Cover fit: scale to cover circle
        float scale = (std::max)(tw / gw, th / gh);
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

  const HRESULT hr = m_pRT->EndDraw();
  if (FAILED(hr)) {
    LogHr(L"EndDraw", hr);
    if (hr == D2DERR_RECREATE_TARGET) {
      CreateRenderTarget(m_rtType);
    }
    return;
  }
  PresentLayered();
}

void BallWindow::PresentLayered() {
  HDC hdcScreen = GetDC(nullptr);
  POINT ptSrc{ 0,0 };
  POINT ptDst{ 0,0 };
  RECT wr{}; GetWindowRect(m_hWnd, &wr); ptDst.x = wr.left; ptDst.y = wr.top;
  SIZE sz{ m_diameter, m_diameter };
  BLENDFUNCTION bf{ AC_SRC_OVER, 0, 255, AC_SRC_ALPHA };
  const BOOL ok = UpdateLayeredWindow(m_hWnd, hdcScreen, &ptDst, &sz, m_hMemDC, &ptSrc, 0, &bf, ULW_ALPHA);
  if (!ok) {
    LogLastError(L"UpdateLayeredWindow");
    EnsureBorderlessStyle();
  }
  ReleaseDC(nullptr, hdcScreen);
}

void BallWindow::OnDpiChanged(HWND hWnd, WPARAM wParam, LPARAM lParam) {
  UNREFERENCED_PARAMETER(wParam);
  const RECT* prcNew = reinterpret_cast<RECT*>(lParam);
  SetWindowPos(hWnd, nullptr, prcNew->left, prcNew->top,
               prcNew->right - prcNew->left, prcNew->bottom - prcNew->top,
               SWP_NOZORDER | SWP_NOACTIVATE);
  // Recreate DIB for new size if needed (omitted for brevity)
  PositionBottomRight();
}

void BallWindow::LoadGifs() {
  // Primary: exe directory
  wchar_t exePath[MAX_PATH]; GetModuleFileName(nullptr, exePath, MAX_PATH);
  wchar_t* slash = wcsrchr(exePath, L'\\'); if (slash) *(slash) = 0; // dirname
  std::wstring dir = exePath;
  auto tryLoad = [&](const std::wstring& baseDir) -> bool {
    std::wstring unread = baseDir + L"\\unread_logo.gif";
    std::wstring dyn    = baseDir + L"\\dynamic_logo.gif";
    bool okU = m_gifUnread.Load(m_pWIC, unread);
    bool okD = m_gifDynamic.Load(m_pWIC, dyn);
    return okU && okD;
  };

  if (tryLoad(dir)) return;

  // Fallback 1: sibling Runner output directory (..\..\Debug or Release)
  std::wstring parent = dir; // ...\runner\native_floating_folders\(Config)
  wchar_t* slash2 = wcsrchr(parent.data(), L'\\');
  if (slash2) { *slash2 = 0; /* ...\runner\native_floating_folders */
    wchar_t* slash3 = wcsrchr(parent.data(), L'\\');
    if (slash3) { *slash3 = 0; /* ...\runner */
      if (tryLoad(std::wstring(parent) + L"\\Debug")) return;
      if (tryLoad(std::wstring(parent) + L"\\Release")) return;
    }
  }

  // If still not found, leave players empty; Render() draws a fallback circle.
}

void BallWindow::SelectGifByUnread() {
  m_activeGif = (m_unreadCount > 0) ? &m_gifDynamic : &m_gifUnread;
}

void BallWindow::OpenMainApp() {
  // 有些情况下 FindWindow 会找不到（多窗口/不同线程创建），这里改为枚举顶层窗口更稳。
  HWND hwndMain = FindFlutterMainWindow();
  if (!hwndMain) return;

  // 先让主程序自己从托盘隐藏状态恢复（跨进程前台激活限制更少）
  SendRestoreRequest(hwndMain);
  ActivateToForeground(hwndMain);
  // 打开主程序后隐藏悬浮球（如需保留可删除此行）
  ShowWindow(m_hWnd, SW_HIDE);
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
