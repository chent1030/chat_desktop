import 'dart:async';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:lottie/lottie.dart';
import 'package:window_manager/window_manager.dart';

/// 悬浮窗入口点 - 独立的窗口实例
/// 注意：这是一个子窗口，不能使用需要平台通道的插件
/// 应该通过窗口间通信或共享内存从主窗口获取数据
Future<void> miniWindowMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('✓ [MINI] 悬浮窗 Flutter 绑定初始化成功');

    // 尝试初始化 window_manager 来设置窗口属性
    try {
      await windowManager.ensureInitialized();

      // 设置窗口为无标题栏样式
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setAsFrameless();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);

      print('✓ [MINI] 窗口样式设置成功');
    } catch (e) {
      print('⚠ [MINI] 窗口样式设置失败（可能不支持）: $e');
      // 忽略错误，继续执行
    }

    // 设置消息处理器，接收来自主窗口的消息
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      print('🔔 [MINI] 收到消息: ${call.method}, 来自窗口: $fromWindowId');

      if (call.method == 'update_unread_count') {
        // 接收未读任务数更新
        final count = call.arguments as int;
        print('✓ [MINI] 更新未读任务数: $count');
        unreadCountController.add(count);
      } else if (call.method == 'update_unread_tasks') {
        // 接收未读任务列表更新
        final tasks = List<Map<String, dynamic>>.from(call.arguments as List);
        print('✓ [MINI] 更新未读任务列表，数量: ${tasks.length}');
        unreadTasksController.add(tasks);
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
final unreadTasksController = StreamController<List<Map<String, dynamic>>>.broadcast();

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
  bool _isHovering = false;
  List<Map<String, dynamic>> _unreadTasks = [];
  StreamSubscription? _unreadCountSubscription;
  StreamSubscription? _unreadTasksSubscription;

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

    // 监听未读任务列表变化
    _unreadTasksSubscription = unreadTasksController.stream.listen((tasks) {
      setState(() {
        _unreadTasks = tasks;
      });
      print('✓ [MINI UI] 未读任务列表更新，数量: ${tasks.length}');
    });
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    _unreadTasksSubscription?.cancel();
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
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 主动画容器
            Container(
              width: 120,
              height: 120,
              color: Colors.transparent,
              child: GestureDetector(
                onDoubleTap: _onDoubleTap,
                child: Center(
                  child: ClipRect(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Lottie.asset(
                            lottieAsset,
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
            ),
            // 悬停时显示未读任务列表
            if (_isHovering && _unreadTasks.isNotEmpty)
              Positioned(
                left: 130,
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    maxHeight: 400,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '未读待办 ($_unreadCount)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 任务列表
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: _unreadTasks.length > 5 ? 5 : _unreadTasks.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final task = _unreadTasks[index];
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                task['title'] ?? '无标题',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: task['description'] != null
                                  ? Text(
                                      task['description'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      // 底部提示
                      if (_unreadTasks.length > 5)
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              '还有 ${_unreadTasks.length - 5} 条...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
