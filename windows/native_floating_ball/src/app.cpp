#include <windows.h>
#include <shellscalingapi.h>
#include "ball_wnd.h"

#pragma comment(lib, "Shcore.lib")

int APIENTRY wWinMain(HINSTANCE hInst, HINSTANCE, LPWSTR, int) {
  // DPI awareness (Win10): per‑monitor v2
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  BallWindow::Register(hInst);
  const int diameter = 120;
  // 初始位置由悬浮窗内部计算（固定右下角），这里的 x/y 仅作占位
  HWND hWnd = BallWindow::Create(hInst, 0, 0, diameter);
  if (!hWnd) return -1;
  ShowWindow(hWnd, SW_SHOWNOACTIVATE);
  UpdateWindow(hWnd);

  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  CoUninitialize();
  return 0;
}
