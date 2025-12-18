import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:lottie/lottie.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

/// 小窗口Widget - 显示圆形图标，鼠标悬停时显示待办项列表
class MiniWindow extends ConsumerStatefulWidget {
  final VoidCallback onDoubleTap;
  final int unreadCount;
  final List<Task> unreadTasks;

  const MiniWindow({
    super.key,
    required this.onDoubleTap,
    this.unreadCount = 0,
    this.unreadTasks = const [],
  });

  @override
  ConsumerState<MiniWindow> createState() => _MiniWindowState();
}

class _MiniWindowState extends ConsumerState<MiniWindow> {
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(MiniWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当未读数量变化时，setState 触发重建
    if (oldWidget.unreadCount != widget.unreadCount) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  /// 显示悬浮待办项列表
  void _showOverlay() {
    if (_overlayEntry != null || widget.unreadTasks.isEmpty) return;

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
                      '待办事项 (${widget.unreadTasks.length})',
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
                    itemCount: widget.unreadTasks.length,
                    separatorBuilder: (context, index) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final task = widget.unreadTasks[index];
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

  /// 移除悬浮层
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency, // 完全透明的Material
      child: Container(
        color: Colors.transparent, // 确保容器透明
        child: Center(
          child: DragToMoveArea(
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovering = true);
                if (widget.unreadTasks.isNotEmpty) {
                  _showOverlay();
                }
              },
              onExit: (_) {
                setState(() => _isHovering = false);
                _removeOverlay();
              },
              child: GestureDetector(
                onDoubleTap: widget.onDoubleTap,
                child: _buildLogoWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建Logo Widget（Lottie 动画）
  Widget _buildLogoWidget() {
    // 根据是否有未读消息选择不同的 Lottie 动画
    final lottieAsset = widget.unreadCount > 0
        ? 'dynamic_logo.json'
        : 'unread_logo.json';

    return SizedBox(
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
    );
  }
}
