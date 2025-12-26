import 'dart:async';
import 'dart:io';
import '../models/task.dart';
import 'windows_ipc.dart';

class WindowsFloatingHelper {
  /// Launch native floating window exe. Returns true if process started.
  static Future<bool> launchNativeFloating({String? exePath}) async {
    if (!Platform.isWindows) return false;
    // Search deterministic and fallback build paths
    final candidates = <String>[];
    try {
      final exe = Platform.resolvedExecutable; // ...\Runner.exe
      final dir = File(exe).parent.path;
      if (exePath != null && exePath.isNotEmpty) {
        candidates.add(exePath);
      }
      candidates.addAll([
        '$dir\\native_floating_ball.exe',
        // CMake subdir build outputs
        '$dir\\..\\native_floating_folders\\Debug\\native_floating_ball.exe',
        '$dir\\..\\native_floating_folders\\Release\\native_floating_ball.exe',
        // Source tree build folder (if invoked separately)
        '$dir\\..\\..\\native_floating_ball\\build\\Release\\native_floating_ball.exe',
        '$dir\\..\\..\\native_floating_ball\\build\\Debug\\native_floating_ball.exe',
      ]);
    } catch (_) {}

    for (final p in candidates) {
      try {
        final file = File(p).absolute;
        if (await file.exists()) {
          // Ensure GIF assets present beside target exe; copy from Runner dir if missing
          try {
            final runnerDir = File(Platform.resolvedExecutable).parent.path;
            final gif1 = File('$runnerDir\\dynamic_logo.gif');
            final gif2 = File('$runnerDir\\unread_logo.gif');
            final targetDir = file.parent.path;
            if (await gif1.exists() && !await File('$targetDir\\dynamic_logo.gif').exists()) {
              await gif1.copy('$targetDir\\dynamic_logo.gif');
            }
            if (await gif2.exists() && !await File('$targetDir\\unread_logo.gif').exists()) {
              await gif2.copy('$targetDir\\unread_logo.gif');
            }
          } catch (_) {}

          await Process.start(file.path, const [], runInShell: true);
          return true;
        }
      } catch (_) {}
    }
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
