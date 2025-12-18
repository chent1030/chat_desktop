import 'dart:io';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'task_provider.dart';
import '../services/log_service.dart';
import '../models/task.dart';

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
      await LogService.instance.info('开始切换到小窗口模式', tag: 'WINDOW');
      print('🪟 [WINDOW] 开始切换到小窗口模式');

      // 所有平台：设置透明背景
      try {
        await LogService.instance.info('设置透明背景', tag: 'WINDOW');
        print('🪟 [WINDOW] 设置透明背景');
        // 使用 flutter_acrylic 设置完全透明效果
        await Window.setEffect(
          effect: WindowEffect.transparent,
        );
        await LogService.instance.info('透明效果设置完成', tag: 'WINDOW');
        print('✓ [WINDOW] 透明效果设置完成');
      } catch (e) {
        await LogService.instance.error('设置透明效果失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 设置透明效果失败: $e');
        rethrow;
      }

      // 所有平台：设置为无边框窗口
      try {
        await LogService.instance.info('设置为无边框窗口', tag: 'WINDOW');
        print('🪟 [WINDOW] 设置为无边框窗口');
        // 设置为无边框窗口（移除系统边框和阴影）
        await windowManager.setAsFrameless();
        await LogService.instance.info('无边框窗口设置完成', tag: 'WINDOW');
        print('✓ [WINDOW] 无边框窗口设置完成');
      } catch (e) {
        await LogService.instance.error('设置无边框窗口失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 设置无边框窗口失败: $e');
        rethrow;
      }

      // 所有平台：设置窗口大小为80x80
      try {
        await LogService.instance.info('设置窗口大小为80x80', tag: 'WINDOW');
        print('🪟 [WINDOW] 设置窗口大小为80x80');
        // 设置为图标大小80x80
        await windowManager.setSize(const Size(80, 80));
        await LogService.instance.info('窗口大小设置完成', tag: 'WINDOW');
        print('✓ [WINDOW] 窗口大小设置完成');
      } catch (e) {
        await LogService.instance.error('设置窗口大小失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 设置窗口大小失败: $e');
        rethrow;
      }

      try {
        await LogService.instance.info('隐藏标题栏', tag: 'WINDOW');
        print('🪟 [WINDOW] 隐藏标题栏');
        // 隐藏标题栏
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await LogService.instance.info('标题栏隐藏完成', tag: 'WINDOW');
        print('✓ [WINDOW] 标题栏隐藏完成');
      } catch (e) {
        await LogService.instance.error('隐藏标题栏失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 隐藏标题栏失败: $e');
        rethrow;
      }

      try {
        await LogService.instance.info('设置窗口置顶', tag: 'WINDOW');
        print('🪟 [WINDOW] 设置窗口置顶');
        // 设置窗口置顶
        await windowManager.setAlwaysOnTop(true);
        await LogService.instance.info('窗口置顶设置完成', tag: 'WINDOW');
        print('✓ [WINDOW] 窗口置顶设置完成');
      } catch (e) {
        await LogService.instance.error('设置窗口置顶失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 设置窗口置顶失败: $e');
        rethrow;
      }

      try {
        // 隐藏工具栏图标（所有平台）
        await LogService.instance.info('隐藏工具栏图标', tag: 'WINDOW');
        print('🪟 [WINDOW] 隐藏工具栏图标');
        await windowManager.setSkipTaskbar(true);
        await LogService.instance.info('工具栏图标已隐藏', tag: 'WINDOW');
        print('✓ [WINDOW] 工具栏图标已隐藏');
      } catch (e) {
        await LogService.instance.error('隐藏工具栏图标失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 隐藏工具栏图标失败: $e');
        rethrow;
      }

      try {
        await LogService.instance.info('居中显示窗口', tag: 'WINDOW');
        print('🪟 [WINDOW] 居中显示窗口');
        // 居中显示
        await windowManager.center();
        await LogService.instance.info('窗口居中完成', tag: 'WINDOW');
        print('✓ [WINDOW] 窗口居中完成');
      } catch (e) {
        await LogService.instance.error('窗口居中失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 窗口居中失败: $e');
        rethrow;
      }

      state = state.copyWith(
        mode: WindowMode.mini,
        isAlwaysOnTop: true,
      );

      await LogService.instance.info('成功切换到小窗口模式', tag: 'WINDOW');
      print('✓ [WINDOW] 成功切换到小窗口模式');
    } catch (e, stackTrace) {
      await LogService.instance.error('切换小窗口失败 - $e', tag: 'WINDOW');
      print('✗ [WINDOW] 切换小窗口失败: $e');
      print('Stack trace: $stackTrace');
      // 记录到崩溃日志
      await LogService.instance.logCrash('切换小窗口模式失败', e, stackTrace);
    }
  }

  /// 切换到正常窗口模式
  Future<void> switchToNormalMode() async {
    try {
      await LogService.instance.info('开始切换到正常窗口模式', tag: 'WINDOW');
      print('🪟 [WINDOW] 开始切换到正常窗口模式');

      // 所有平台：恢复白色背景
      try {
        await LogService.instance.info('恢复不透明白色背景', tag: 'WINDOW');
        print('🪟 [WINDOW] 恢复不透明白色背景');
        // 使用 flutter_acrylic 设置不透明白色效果
        await Window.setEffect(
          effect: WindowEffect.solid,
          color: const Color(0xFFFFFFFF),
        );
        await LogService.instance.info('不透明白色背景恢复完成', tag: 'WINDOW');
        print('✓ [WINDOW] 不透明白色背景恢复完成');
      } catch (e) {
        await LogService.instance.error('恢复不透明背景失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 恢复不透明背景失败: $e');
        rethrow;
      }

      try {
        await LogService.instance.info('恢复标题栏', tag: 'WINDOW');
        print('🪟 [WINDOW] 恢复标题栏');
        // 恢复标题栏
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        await LogService.instance.info('标题栏恢复完成', tag: 'WINDOW');
        print('✓ [WINDOW] 标题栏恢复完成');
      } catch (e) {
        await LogService.instance.error('恢复标题栏失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 恢复标题栏失败: $e');
        rethrow;
      }

      try {
        await LogService.instance.info('恢复窗口大小为1200x800', tag: 'WINDOW');
        print('🪟 [WINDOW] 恢复窗口大小为1200x800');
        // 恢复窗口大小
        await windowManager.setSize(const Size(1200, 800));
        await LogService.instance.info('窗口大小恢复完成', tag: 'WINDOW');
        print('✓ [WINDOW] 窗口大小恢复完成');
      } catch (e) {
        await LogService.instance.error('恢复窗口大小失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 恢复窗口大小失败: $e');
        rethrow;
      }

      try {
        await LogService.instance.info('取消窗口置顶', tag: 'WINDOW');
        print('🪟 [WINDOW] 取消窗口置顶');
        // 取消置顶
        await windowManager.setAlwaysOnTop(false);
        await LogService.instance.info('窗口置顶已取消', tag: 'WINDOW');
        print('✓ [WINDOW] 窗口置顶已取消');
      } catch (e) {
        await LogService.instance.error('取消窗口置顶失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 取消窗口置顶失败: $e');
        rethrow;
      }

      try {
        // 显示工具栏图标（所有平台）
        await LogService.instance.info('显示工具栏图标', tag: 'WINDOW');
        print('🪟 [WINDOW] 显示工具栏图标');
        await windowManager.setSkipTaskbar(false);
        await LogService.instance.info('工具栏图标已显示', tag: 'WINDOW');
        print('✓ [WINDOW] 工具栏图标已显示');
      } catch (e) {
        await LogService.instance.error('显示工具栏图标失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 显示工具栏图标失败: $e');
        rethrow;
      }

      try {
        await LogService.instance.info('居中显示窗口', tag: 'WINDOW');
        print('🪟 [WINDOW] 居中显示窗口');
        // 居中显示
        await windowManager.center();
        await LogService.instance.info('窗口居中完成', tag: 'WINDOW');
        print('✓ [WINDOW] 窗口居中完成');
      } catch (e) {
        await LogService.instance.error('窗口居中失败 - $e', tag: 'WINDOW');
        print('✗ [WINDOW] 窗口居中失败: $e');
        rethrow;
      }

      state = state.copyWith(
        mode: WindowMode.normal,
        isAlwaysOnTop: false,
      );

      await LogService.instance.info('成功切换到正常窗口模式', tag: 'WINDOW');
      print('✓ [WINDOW] 成功切换到正常窗口模式');
    } catch (e, stackTrace) {
      await LogService.instance.error('切换正常窗口失败 - $e', tag: 'WINDOW');
      print('✗ [WINDOW] 切换正常窗口失败: $e');
      print('Stack trace: $stackTrace');
      // 记录到崩溃日志
      await LogService.instance.logCrash('切换正常窗口模式失败', e, stackTrace);
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

/// 未读角标计数Provider - 显示未读且未完成任务数
final unreadBadgeCountProvider = Provider<int>((ref) {
  final taskListState = ref.watch(taskListProvider);
  // 返回未读且未完成任务的数量
  return taskListState.tasks.where((task) => !task.isRead && !task.isCompleted).length;
});

/// 未读任务列表Provider - 返回未读且未完成的任务
final unreadTasksProvider = Provider<List<Task>>((ref) {
  final taskListState = ref.watch(taskListProvider);
  // 返回未读且未完成的任务列表
  return taskListState.tasks.where((task) => !task.isRead && !task.isCompleted).toList();
});
