import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'services/config_service.dart';
import 'services/storage_service.dart';
import 'services/log_service.dart';
import 'utils/constants.dart';

/// 应用入口点
Future<void> main() async {
  // 使用 runZonedGuarded 捕获所有未处理的异步异常
  runZonedGuarded(() async {
    await _initializeApp();
  }, (error, stackTrace) {
    // 捕获未处理的异步异常
    _handleCrash('未捕获的异步异常', error, stackTrace);
  });
}

/// 处理崩溃
void _handleCrash(String context, Object error, StackTrace stackTrace) {
  print('💥 [CRASH] $context: $error');
  print('Stack trace: $stackTrace');

  // 记录到崩溃日志文件（单独的文件）
  LogService.instance.logCrash(context, error, stackTrace);
}

/// 初始化应用
Future<void> _initializeApp() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 设置 Flutter 框架错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    // 保留 Flutter 的默认错误处理（在控制台输出红屏等）
    FlutterError.presentError(details);

    // 记录到日志文件
    _handleCrash(
      'Flutter框架异常',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  try {
    // 初始���日志服务（最先初始化，以便记录其他服务的日志）
    await LogService.instance.initialize();
    print('✓ LogService初始化成功');

    // 加载环境变量
    await dotenv.load(fileName: '.env');
    print('✓ 环境变量加载成功');
    await LogService.instance.info('环境变量加载成功');

    // 初始化配置服务
    await ConfigService.instance.initialize();
    print('✓ ConfigService初始化成功');
    await LogService.instance.info('ConfigService初始化成功');

    // 初始化存储服务
    await StorageService.instance.initialize();
    print('✓ StorageService初始化成功');
    await LogService.instance.info('StorageService初始化成功');

    // 初始化窗口管理器
    await windowManager.ensureInitialized();

    // 配置窗口选项（Windows平台使用白色背景，避免透明层问题）
    WindowOptions windowOptions = WindowOptions(
      size: const Size(
        AppConstants.defaultWindowWidth,
        AppConstants.defaultWindowHeight,
      ),
      center: true,
      backgroundColor: Platform.isWindows ? Colors.white : Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppConstants.appName,
      minimumSize: const Size(
        AppConstants.minWindowWidth,
        AppConstants.minWindowHeight,
      ),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // 阻止默认的关闭行为，改为切换到小窗模式（所有平台）
    await windowManager.setPreventClose(true);
    print('✓ 已设置阻止默认关闭行为');

    print('✓ WindowManager初始化成功');

    // 初始化系统托盘（所有平台）
    try {
      // 设置托盘图标
      final iconPath = Platform.isWindows
          ? 'app_icon.ico'
          : Platform.isMacOS
              ? 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png'
              : 'assets/app_icon.ico';

      await trayManager.setIcon(iconPath);

      // 设置托盘提示文字
      await trayManager.setToolTip('芯服务 - 点击恢复窗口');

      // 设置托盘菜单
      Menu menu = Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: '显示窗口',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: '退出',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);

      print('✓ 系统托盘初始化成功');
    } catch (e) {
      print('✗ 系统托盘初始化失败: $e');
    }

    // 启动应用
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('✗ 应用初始化失败: $e');
    print('堆栈追踪: $stackTrace');

    // 记录崩溃到日志文件
    _handleCrash('应用初始化失败', e, stackTrace);

    // 显示错误界面
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用初始化失败',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    '错误详情: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
