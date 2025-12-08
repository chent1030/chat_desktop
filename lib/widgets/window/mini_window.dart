import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// 小窗口Widget - 显示圆形图标和未读角标
class MiniWindow extends ConsumerStatefulWidget {
  final VoidCallback onDoubleTap;
  final int unreadCount;

  const MiniWindow({
    super.key,
    required this.onDoubleTap,
    this.unreadCount = 0,
  });

  @override
  ConsumerState<MiniWindow> createState() => _MiniWindowState();
}

class _MiniWindowState extends ConsumerState<MiniWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: DragToMoveArea(
          child: GestureDetector(
            onDoubleTap: widget.onDoubleTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 主圆形图标
                _buildMainIcon(),

                // 未读角标
                if (widget.unreadCount > 0) _buildBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建主圆形图标
  Widget _buildMainIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.task_alt,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  /// 构建未读角标
  Widget _buildBadge() {
    final displayCount = widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}';

    return Positioned(
      right: -5,
      top: -5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Text(
          displayCount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
