# Windows Floating Window (WIC + D2D) – TODO

Goal: Build a native Win10+ floating ball window that is borderless, backgroundless (per‑pixel alpha), draggable, always‑on‑top, with a hover bubble for unread tasks. Integrate a file‑based task queue that executes actions sequentially (Outlook/DingTalk/open main task), and IPC with the main app.

## Phase 0 — Prep
- [ ] Target OS: Windows 10+ (DPI Per‑Monitor‑V2)
- [ ] Toolchain: VS 2022, C++17
- [ ] Create solution `windows/native_floating_ball/` with two windows: `BallWnd` (floating) and `BubbleWnd` (hover list)

## Phase 1 — Layered Ball Window (per‑pixel alpha)
- [ ] Create `WS_POPUP` + `WS_EX_TOPMOST|WS_EX_TOOLWINDOW|WS_EX_LAYERED` window (120×120)
- [ ] Enable DPI awareness (PMv2) and scaling handlers (WM_DPICHANGED)
- [ ] D2D1.1 + WIC init (ID2D1Factory1, IWICImagingFactory2)
- [ ] Render pipeline: ID2D1DCRenderTarget → DIBSection (32bpp PBGRA) → UpdateLayeredWindow(ULW_ALPHA)
- [ ] Round shape: D2D ellipse clip/layer to draw a circle
- [ ] Drag: WM_NCHITTEST → HTCAPTION

## Phase 2 — GIF Playback (WIC)
- [ ] Load GIF via IWICBitmapDecoder/IWICFormatConverter (32bppPBGRA)
- [ ] Read frame delays (metadata `/grctlext/Delay`), min 10 ms tick
- [ ] TimerQueue to advance frame → render → UpdateLayeredWindow
- [ ] Cover/contain math (no stretching) inside circular clip

## Phase 3 — Hover Bubble Window
- [ ] Separate `BubbleWnd` (WS_POPUP + layered) with rounded rect + subtle shadow
- [ ] Show on hover (TrackMouseEvent/WM_MOUSELEAVE), `SW_SHOWNOACTIVATE`
- [ ] DWrite text for items, keep hit‑rects for click
- [ ] Click item → hide bubble + send OPEN_TASK (WM_COPYDATA) to main app
- [ ] In `BallWnd` HT: if cursor in bubble area, return HTCLIENT (don’t drag)

## Phase 4 — Task File + Sequential Executor (skipped)
- [x] Not in current scope; execution is driven by UI interactions and IPC.

## Phase 5 — IPC with Main App
- [ ] Protocol (WM_COPYDATA): `dwData=1 UPDATE_TASKS`, `dwData=2 OPEN_TASK`
- [ ] Main app handler: `OPEN_TASK` → Show + foreground + open detail
- [ ] Floating app: accept `UPDATE_TASKS` to refresh unread list

## Phase 6 — Integration & Polish
- [ ] Bubble animations (fade/scale), edge‑aware positioning
- [ ] Multi‑monitor coordinates, Z‑order stability
- [ ] Logging (OutputDebugString + rolling file)
- [ ] Build config: x64 Release, post‑build copy if needed

## Acceptance Criteria
- [ ] Floating ball: no border, no background, draggable, always on top
- [ ] GIF renders smoothly, no stretching, circular crop, good quality
- [ ] Hover shows bubble with unread tasks; click opens main app task detail
- [ ] Task engine reads tasks.json, executes sequentially, persists status
- [ ] IPC OPEN_TASK works reliably; main window is focused/restored

## Nice‑to‑Have (later)
- [ ] DirectComposition effects (blur, shadow) on Win10+
- [ ] Named pipe IPC (replace WM_COPYDATA)
- [ ] Tray menu to pause/resume executor; reload tasks.json

## File Map (planned)
- `windows/native_floating_ball/`
  - `app.cpp` (WinMain, init)
  - `ball_wnd.h/.cpp` (floating window)
  - `bubble_wnd.h/.cpp` (hover list window)
  - `gif_player.h/.cpp` (WIC decode + frame timing)
  - `d2d_helpers.h/.cpp` (factory/RT utilities)
  - `task_engine.h/.cpp` (load/save JSON, queue worker)
  - `ipc.h/.cpp` (WM_COPYDATA helpers)
  - `json.hpp` (nlohmann/json, single‑header)

## Next Up
- [ ] Scaffold solution + Phase 1 (layered window + D2D/WIC init)
- [ ] Commit a minimal running ball window (solid color circle), then add GIF
