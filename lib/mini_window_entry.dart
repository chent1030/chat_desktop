import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:lottie/lottie.dart';
import 'models/task.dart';
import 'services/task_service.dart';
import 'services/storage_service.dart';
import 'services/log_service.dart';
import 'providers/task_provider.dart';

/// 悬浮窗入口点 - 独立的窗口实例
/// 注意：这是一个子窗口，不能使用 window_manager，应使用 WindowController
Future<void> miniWindowMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化必要的服务（使用单例模式，与主窗口共享）
    await LogService.instance.initialize();
    print('✓ [MINI] LogService 初始化成功');

    await StorageService.instance.initialize();
    print('✓ [MINI] StorageService 初始化成功');

    // 初始化 TaskService（依赖 StorageService）
    // TaskService 使用单例模式，会自动使用已初始化的 StorageService
    print('✓ [MINI] TaskService 已就绪');

    // 注意：子窗口不需要初始化 window_manager
    // 窗口属性已在创建时由主窗口通过 DesktopMultiWindow.createWindow() 配置
    print('✓ [MINI] 子窗口初始化完成');

    runApp(
      const ProviderScope(
        child: MiniWindowApp(),
      ),
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
class MiniWindowHome extends ConsumerStatefulWidget {
  const MiniWindowHome({super.key});

  @override
  ConsumerState<MiniWindowHome> createState() => _MiniWindowHomeState();
}

class _MiniWindowHomeState extends ConsumerState<MiniWindowHome> {
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  /// 移除悬浮层
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 显示悬浮待办项列表
  void _showOverlay(List<Task> unreadTasks) {
    if (_overlayEntry != null || unreadTasks.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 90, // Logo右侧10px
        top: 0,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 250,
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '待办事项 (${unreadTasks.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: unreadTasks.length,
                    separatorBuilder: (context, index) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final task = unreadTasks[index];
                      return InkWell(
                        onTap: () async {
                          // 点击待办项时标记为已读
                          await TaskService.instance.markTaskAsRead(task.id);
                          _removeOverlay();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(task.priority),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 获取优先级颜色
  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
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
    final taskListState = ref.watch(taskListProvider);
    final unreadTasks = taskListState.tasks
        .where((task) => !task.isRead && !task.isCompleted)
        .toList();
    final unreadCount = unreadTasks.length;

    // 根据是否有未读消息选择不同的 Lottie 动画
    final lottieAsset = unreadCount > 0 ? 'dynamic_logo.json' : 'unread_logo.json';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _isHovering = true);
              if (unreadTasks.isNotEmpty) {
                _showOverlay(unreadTasks);
              }
            },
            onExit: (_) {
              setState(() => _isHovering = false);
              _removeOverlay();
            },
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
      ),
    );
  }
}
