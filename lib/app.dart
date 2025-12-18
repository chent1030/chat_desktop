import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
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
    // 所有平台：关闭按钮创建独立悬浮窗而不是退出
    await LogService.instance.info('关闭按钮被点击，准备创建独立悬浮窗', tag: 'WINDOW');
    print('🪟 [WINDOW] 关闭按钮被点击，准备创建独立悬浮窗');

    try {
      // 创建独立的悬浮窗（80x80，透明，置顶）
      // 传递 'mini_window' 作为第一个参数，子窗口的 main() 会接收到这个参数
      final window = await DesktopMultiWindow.createWindow('mini_window');

      // 设置悬浮窗属性
      await window.setFrame(const Offset(100, 100) & const Size(80, 80));
      await window.setTitle('');  // 空标题
      await window.center();

      // 关键设置：移除标题栏和边框
      // 注意：desktop_multi_window 的 API 有限，某些属性可能无法直接设置
      // 需要在子窗口内部通过 UI 层面实现无边框效果

      await window.show();

      await LogService.instance.info('独立悬浮窗创建成功', tag: 'WINDOW');
      print('✓ [WINDOW] 独立悬浮窗创建成功');

      // 获取当前未读任务数并发送给悬浮窗
      try {
        final unreadCount = ref.read(unreadBadgeCountProvider);
        print('📤 [WINDOW] 发送未读任务数给悬浮窗: $unreadCount, 窗口ID: ${window.windowId}');

        // 等待一小段时间确保悬浮窗已经初始化
        await Future.delayed(const Duration(milliseconds: 500));

        // 使用正确的 API 发送消息给子窗口
        await DesktopMultiWindow.invokeMethod(
          window.windowId,
          'update_unread_count',
          unreadCount,
        );
        print('✓ [WINDOW] 未读任务数已发送');
      } catch (e) {
        print('✗ [WINDOW] 发送未读任务数失败: $e');
      }

      // 隐藏主窗口
      await windowManager.hide();
      await LogService.instance.info('主窗口已隐藏', tag: 'WINDOW');
      print('✓ [WINDOW] 主窗口已隐藏');
    } catch (e, stackTrace) {
      await LogService.instance.error('创建悬浮窗失败 - $e', tag: 'WINDOW');
      print('✗ [WINDOW] 创建悬浮窗失败: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

/// 托盘监听器 - 处理托盘图标点击事件
class AppTrayListener extends TrayListener {
  final WidgetRef ref;

  AppTrayListener(this.ref);

  @override
  void onTrayIconMouseDown() {
    // 点击托盘图标时恢复主窗口
    windowManager.show();
    windowManager.focus();
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
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      // 真正退出应用（不是进入小窗模式）
      print('🔴 [APP] 用户从系统托盘选择退出，正在关闭程序...');
      windowManager.destroy();
      exit(0); // 强制退出进程
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

    // 创建并注册托盘监听器（所有平台）
    _trayListener = AppTrayListener(ref);
    trayManager.addListener(_trayListener);
    print('✓ 托盘监听器已注册');
  }

  @override
  void dispose() {
    // 移除窗口监听器
    windowManager.removeListener(_windowListener);

    // 移除托盘监听器
    trayManager.removeListener(_trayListener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '芯服务',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
