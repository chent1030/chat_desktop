import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'screens/home_screen.dart';
import 'widgets/window/mini_window.dart';
import 'providers/window_provider.dart';
import 'services/log_service.dart';
import 'utils/theme.dart';

/// 窗口监听器 - 处理窗口关闭事件
class AppWindowListener extends WindowListener {
  final WidgetRef ref;

  AppWindowListener(this.ref);

  @override
  Future<void> onWindowClose() async {
    // 在Windows平台上,关闭按钮进入小窗模式而不是退出
    if (Platform.isWindows) {
      await LogService.instance.info('Windows平台：关闭按钮被点击，切换到小窗模式', tag: 'WINDOW');
      print('🪟 [WINDOW] Windows平台：关闭按钮被点击，切换到小窗模式');

      // 切换到小窗模式
      await ref.read(windowStateProvider.notifier).switchToMiniMode();

      // 阻止窗口关闭
      return;
    } else {
      // 其他平台正常退出
      await windowManager.destroy();
    }
  }
}

/// 托盘监听器 - 处理托盘图标点击事件
class AppTrayListener extends TrayListener {
  final WidgetRef ref;

  AppTrayListener(this.ref);

  @override
  void onTrayIconMouseDown() {
    // 点击托盘图标时恢复窗口
    ref.read(windowStateProvider.notifier).switchToNormalMode();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键点击托盘图标，显示菜单
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    // 处理托盘菜单点击
    if (menuItem.key == 'show_window') {
      ref.read(windowStateProvider.notifier).switchToNormalMode();
    } else if (menuItem.key == 'exit_app') {
      // 退出应用
      windowManager.destroy();
    }
  }
}

/// 应用根Widget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late AppWindowListener _windowListener;
  late AppTrayListener _trayListener;

  @override
  void initState() {
    super.initState();
    // 创建并注册窗口监听器
    _windowListener = AppWindowListener(ref);
    windowManager.addListener(_windowListener);
    print('✓ 窗口监听器已注册');

    // 创建并注册托盘监听器（仅Windows平台）
    if (Platform.isWindows) {
      _trayListener = AppTrayListener(ref);
      trayManager.addListener(_trayListener);
      print('✓ 托盘监听器已注册');
    }
  }

  @override
  void dispose() {
    // 移除窗口监听器
    windowManager.removeListener(_windowListener);

    // 移除托盘监听器
    if (Platform.isWindows) {
      trayManager.removeListener(_trayListener);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final windowState = ref.watch(windowStateProvider);
    final unreadCount = ref.watch(unreadBadgeCountProvider);
    final unreadTasks = ref.watch(unreadTasksProvider);

    return MaterialApp(
      title: '芯服务',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: windowState.mode == WindowMode.mini
          ? MiniWindow(
              unreadCount: unreadCount,
              unreadTasks: unreadTasks,
              onDoubleTap: () {
                ref.read(windowStateProvider.notifier).switchToNormalMode();
              },
            )
          : const HomeScreen(),
    );
  }
}
