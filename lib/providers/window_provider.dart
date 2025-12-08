import 'dart:io';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'task_provider.dart';

/// 窗口模式枚举
enum WindowMode {
  normal, // 正常窗口
  mini, // 小窗口模式
}

/// 窗口状态
class WindowState {
  final WindowMode mode;
  final bool isAlwaysOnTop;

  const WindowState({
    this.mode = WindowMode.normal,
    this.isAlwaysOnTop = false,
  });

  WindowState copyWith({
    WindowMode? mode,
    bool? isAlwaysOnTop,
  }) {
    return WindowState(
      mode: mode ?? this.mode,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
    );
  }
}

/// 窗口状态Provider
class WindowStateNotifier extends StateNotifier<WindowState> {
  WindowStateNotifier() : super(const WindowState());

  /// 切换到小窗口模式
  Future<void> switchToMiniMode() async {
    try {
      // 保存当前窗口位置和大小
      // final position = await windowManager.getPosition();
      // final size = await windowManager.getSize();
      // 可以保存到SharedPreferences

      // 隐藏标题栏
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

      // Windows平台需要额外处理：设置无边框窗口和透明背景
      if (Platform.isWindows) {
        // 设置背景色为透明（移除白色背景）
        await windowManager.setBackgroundColor(const Color(0x00000000));

        // 设置为无边框窗口（移除系统边框和阴影）
        await windowManager.setAsFrameless();

        // 设置稍大一点的尺寸以容纳圆形图标和边距
        await windowManager.setSize(const Size(100, 100));
      } else {
        // 其他平台保持原有尺寸
        await windowManager.setSize(const Size(80, 80));
      }

      // 设置窗口置顶
      await windowManager.setAlwaysOnTop(true);

      // 居中显示
      await windowManager.center();

      state = state.copyWith(
        mode: WindowMode.mini,
        isAlwaysOnTop: true,
      );

      print('✓ 已切换到小窗口模式');
    } catch (e) {
      print('✗ 切换小窗口失败: $e');
    }
  }

  /// 切换到正常窗口模式
  Future<void> switchToNormalMode() async {
    try {
      // Windows平台需要额外处理：恢复背景色
      if (Platform.isWindows) {
        // 恢复白色背景
        await windowManager.setBackgroundColor(const Color(0xFFFFFFFF));
      }

      // 恢复标题栏
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);

      // 恢复窗口大小
      await windowManager.setSize(const Size(1200, 800));

      // 取消置顶
      await windowManager.setAlwaysOnTop(false);

      // 居中显示
      await windowManager.center();

      state = state.copyWith(
        mode: WindowMode.normal,
        isAlwaysOnTop: false,
      );

      print('✓ 已切换到正常窗口模式');
    } catch (e) {
      print('✗ 切换正常窗口失败: $e');
    }
  }

  /// 切换窗口模式
  Future<void> toggleMode() async {
    if (state.mode == WindowMode.normal) {
      await switchToMiniMode();
    } else {
      await switchToNormalMode();
    }
  }

  /// 设置窗口置顶
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    try {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
      state = state.copyWith(isAlwaysOnTop: alwaysOnTop);
    } catch (e) {
      print('✗ 设置窗口置顶失败: $e');
    }
  }
}

/// 窗口状态Provider实例
final windowStateProvider =
    StateNotifierProvider<WindowStateNotifier, WindowState>((ref) {
  return WindowStateNotifier();
});

/// 未读角标计数Provider - 显示未完成任务数
final unreadBadgeCountProvider = Provider<int>((ref) {
  final taskListState = ref.watch(taskListProvider);
  // 返回未完成任务的数量
  return taskListState.tasks.where((task) => !task.isCompleted).length;
});
