import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';

import '../models/task.dart';

/// Flutter 悬浮窗（desktop_multi_window）管理
///
/// 目标：同进程多窗口，避免原生 layered window 在部分核显/系统版本上的兼容问题。
class FloatingWindowService {
  FloatingWindowService._();

  static final FloatingWindowService instance = FloatingWindowService._();

  int? _windowId;

  int? get windowId => _windowId;

  bool get isOpen => _windowId != null;

  void bindWindowId(int windowId) {
    _windowId = windowId;
  }

  void unbindWindowId([int? windowId]) {
    if (windowId == null || _windowId == windowId) {
      _windowId = null;
    }
  }

  Future<void> syncUnreadTasks(List<Task> unreadTasks) async {
    if (!Platform.isWindows) return;
    final id = _windowId;
    if (id == null) return;

    final unreadCount =
        unreadTasks.where((t) => !t.isRead && !t.isCompleted).length;

    try {
      await DesktopMultiWindow.invokeMethod(
        id,
        'update_unread_count',
        unreadCount,
      );
    } catch (_) {}

    try {
      final taskMaps = unreadTasks
          .map(
            (task) => {
              'id': task.id,
              'title': task.title,
              'description': task.description,
              'isCompleted': task.isCompleted,
              'isRead': task.isRead,
            },
          )
          .toList(growable: false);

      await DesktopMultiWindow.invokeMethod(
        id,
        'update_unread_tasks',
        taskMaps,
      );
    } catch (_) {}
  }
}
