import 'dart:async';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:lottie/lottie.dart';

/// 悬浮窗入口点 - 独立的窗口实例
/// 注意：这是一个子窗口，不能使用需要平台通道的插件
/// 应该通过窗口间通信或共享内存从主窗口获取数据
Future<void> miniWindowMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('✓ [MINI] 悬浮窗 Flutter 绑定初始化成功');

    // 设置消息处理器，接收来自主窗口的消息
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      print('🔔 [MINI] 收到消息: ${call.method}, 来自窗口: $fromWindowId');

      if (call.method == 'update_unread_count') {
        // 接收未读任务数更新
        final count = call.arguments as int;
        print('✓ [MINI] 更新未读任务数: $count');
        // 通过全局状态或其他方式更新UI
        // 暂时通过 EventBus 或 StreamController 实现
        unreadCountController.add(count);
      }
    });

    print('✓ [MINI] 子窗口初始化完成（跳过服务初始化）');

    runApp(
      const MiniWindowApp(),
    );
  } catch (e, stackTrace) {
    print('✗ [MINI] 悬浮窗初始化失败: $e');
    print('Stack trace: $stackTrace');
  }
}

// 用于跨Widget通信的 Stream Controller
final unreadCountController = StreamController<int>.broadcast();

/// 悬浮窗应用
class MiniWindowApp extends StatelessWidget {
  const MiniWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        // 确保所有颜色都是透明的
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          surface: Colors.transparent,
          background: Colors.transparent,
        ),
      ),
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: MiniWindowHome(),
      ),
    );
  }
}

/// 悬浮窗主页
class MiniWindowHome extends StatefulWidget {
  const MiniWindowHome({super.key});

  @override
  State<MiniWindowHome> createState() => _MiniWindowHomeState();
}

class _MiniWindowHomeState extends State<MiniWindowHome> {
  int _unreadCount = 0;
  StreamSubscription? _unreadCountSubscription;

  @override
  void initState() {
    super.initState();
    // 监听未读任务数变化
    _unreadCountSubscription = unreadCountController.stream.listen((count) {
      setState(() {
        _unreadCount = count;
      });
      print('✓ [MINI UI] 未读任务数更新为: $count');
    });
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    super.dispose();
  }

  /// 双击恢复主窗口
  Future<void> _onDoubleTap() async {
    print('🪟 [MINI] 双击悬浮窗，准备恢复主窗口');
    try {
      // 通知主窗口恢复（发送消息到窗口ID 0，即主窗口）
      await DesktopMultiWindow.invokeMethod(0, 'restore_main_window');
      print('✓ [MINI] 已发送恢复主窗口请求');
    } catch (e) {
      print('✗ [MINI] 发送恢复主窗口请求失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据是否有未读消息选择不同的 Lottie 动画
    final lottieAsset = _unreadCount > 0 ? 'dynamic_logo.json' : 'unread_logo.json';

    print('🎨 [MINI UI] 当前未读数: $_unreadCount, 使用动画: $lottieAsset');

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 120,
        height: 120,
        color: Colors.transparent,
        child: GestureDetector(
          onDoubleTap: _onDoubleTap,
          child: Center(
            child: Lottie.asset(
              lottieAsset,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),
        ),
      ),
    );
  }
}
