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

    // 注意：子窗口不应该初始化任何需要平台通道的服务（如 path_provider）
    // 因为在 desktop_multi_window 的子窗口环境中，这些插件无法正常工作
    // 数据应该通过窗口间通信从主窗口获取，或者使用内存共享机制

    print('✓ [MINI] 子窗口初始化完成（跳过服务初始化）');

    runApp(
      const MiniWindowApp(),
    );
  } catch (e, stackTrace) {
    print('✗ [MINI] 悬浮窗初始化失败: $e');
    print('Stack trace: $stackTrace');
  }
}

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
  // 暂时使用固定的未读数量，未来可以通过窗口间通信从主窗口获取
  int _unreadCount = 0;

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
    // 暂时使用固定值，未来可以通过窗口间通信更新
    final lottieAsset = _unreadCount > 0 ? 'dynamic_logo.json' : 'unread_logo.json';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: SizedBox(
              width: 80,
              height: 80,
              child: ClipOval(
                child: Center(
                  child: Lottie.asset(
                    lottieAsset,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
