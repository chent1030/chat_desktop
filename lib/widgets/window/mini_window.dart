import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:video_player/video_player.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

/// 小窗口Widget - 显示圆形图标和未读角标
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
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(MiniWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当未读数量变化时,重新初始化视频
    if (oldWidget.unreadCount != widget.unreadCount) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    // 如果有未读消息,播放视频;否则显示静态图片
    if (widget.unreadCount > 0) {
      // 先释放旧的控制器
      await _videoController?.dispose();

      // 创建新的视频控制器
      _videoController = VideoPlayerController.asset('dynamic_logo.mp4');
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();

      if (mounted) {
        setState(() {});
      }
    } else {
      // 没有未读消息时停止并释放视频
      await _videoController?.pause();
      await _videoController?.dispose();
      _videoController = null;

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DragToMoveArea(
        child: GestureDetector(
          onDoubleTap: widget.onDoubleTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo (图片或视频)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildLogoWidget(),
                ],
              ),

              // 待办项标题列表
              if (widget.unreadTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: widget.unreadTasks.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final task = widget.unreadTasks[index];
                        return InkWell(
                          onTap: () async {
                            // 点击待办项时标记为已读
                            await TaskService.instance.markTaskAsRead(task.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建Logo Widget（静态图片或动态视频）
  Widget _buildLogoWidget() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: widget.unreadCount > 0 && _videoController != null && _videoController!.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : Image.asset(
                'static_logo.jpg',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
