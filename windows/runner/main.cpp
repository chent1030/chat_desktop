#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <propkey.h>
#include <shobjidl.h>

#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Set AppUserModelID for Windows notification support
  // This is important for the notification system to recognize the app
  SetCurrentProcessExplicitAppUserModelID(L"com.chatdesktop.ChatDesktop");

  flutter::DartProject project(L"data");

  // Configure Bitsdojo Window only for mini-window (see below)

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  // Only enable custom frame for the mini window process
  bool is_mini_window = false;
  for (const auto& arg : command_line_arguments) {
    if (arg.find("mini_window") != std::string::npos) {
      is_mini_window = true;
      break;
    }
  }
  if (is_mini_window) {
    bitsdojo_window_configure(BDW_CUSTOM_FRAME);
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"chat_desktop", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
