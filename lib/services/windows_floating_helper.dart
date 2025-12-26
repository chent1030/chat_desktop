import 'dart:async';
import 'dart:io';
import '../models/task.dart';
import 'windows_ipc.dart';

class WindowsFloatingHelper {
  /// Launch native floating window exe. Returns true if process started.
  static Future<bool> launchNativeFloating({String? exePath}) async {
    if (!Platform.isWindows) return false;
    // Deterministic path: same directory as Runner.exe
    try {
      final exe = Platform.resolvedExecutable; // ...\Runner.exe
      final dir = File(exe).parent.path;
      final p = exePath != null && exePath.isNotEmpty ? exePath : '$dir\\native_floating_ball.exe';
      final file = File(p).absolute;
      if (await file.exists()) {
        await Process.start(file.path, const [], runInShell: true);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Launch native floating window and sync unread tasks once (after a short delay).
  static Future<bool> launchFloatingAndSync(List<Task> unread, {String? exePath}) async {
    final ok = await launchNativeFloating(exePath: exePath);
    if (ok) {
      // Give the floating window time to create
      await Future.delayed(const Duration(milliseconds: 300));
      WindowsFloatingIpc.sendUnreadTasks(unread);
    }
    return ok;
  }
}
