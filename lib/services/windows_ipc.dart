// Windows-only: WM_COPYDATA sender to native floating window
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;
import '../models/task.dart';

class WindowsFloatingIpc {
  static const String _floatingClassName = 'NativeFloatingBallWindow';

  /// Send unread tasks to native floating window (hover bubble).
  /// The floating app expects WM_COPYDATA with dwData=1 and a UTF-16 payload
  /// where each line is: "<id> <title>".
  static bool sendUnreadTasks(List<Task> unread) {
    if (!Platform.isWindows) return false;

    final className = _floatingClassName.toNativeUtf16(allocator: calloc);
    try {
      final hwnd = win32.FindWindow(className, ffi.nullptr);
      if (hwnd == 0) {
        return false; // floating window not found
      }

      final lines = unread.map((t) => '${t.id} ${t.title}').join('\n');
      // UTF-16 payload including terminating NUL
      final payload = lines.toNativeUtf16(allocator: calloc);
      // Define local COPYDATASTRUCT to avoid platform typedef issues
      final cds = calloc<_COPYDATASTRUCT>();
      cds.ref.dwData = ffi.sizeOf<ffi.IntPtr>() == 8 ? 1 : 1; // 1 = UPDATE_TASKS
      cds.ref.cbData = (lines.length + 1) * 2; // bytes
      cds.ref.lpData = payload.cast();

      // WM_COPYDATA = 0x004A
      win32.SendMessage(hwnd, 0x004A, 0, cds.address);

      calloc.free(cds);
      calloc.free(payload);
      return true;
    } finally {
      calloc.free(className);
    }
  }
}

// Minimal struct mirror of Windows COPYDATASTRUCT
base class _COPYDATASTRUCT extends ffi.Struct {
  @ffi.UintPtr()
  external int dwData;

  @ffi.UintPtr()
  external int cbData;

  external ffi.Pointer<ffi.Void> lpData;
}
