import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import 'task_detail.dart';
import '../../services/task_service.dart';

enum _TaskItemMenuAction {
  detail,
  dispatch,
}

/// TaskItem widget - 显示单个任务的卡片组件
class TaskItem extends ConsumerWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskItem({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: task.isCompleted ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.isCompleted ? Colors.grey.shade300 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _markAsRead(context, ref),
        onLongPress: () => _showContextMenu(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 完成状态复选框
              _buildCheckbox(context, ref),
              const SizedBox(width: 12),

              // 任务内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行 (标题 + 优先级指示器)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? Colors.grey.shade600
                                  : null,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 右上角小圆点（未读显示，已读淡出）
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.85, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          ),
                          child: task.isRead
                              ? const SizedBox(
                                  key: ValueKey('read'),
                                  width: 8,
                                  height: 8,
                                )
                              : Container(
                                  key: const ValueKey('unread'),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Color(task.priority.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 6),
                        _buildTopRightMenu(context, ref),
                      ],
                    ),

                    // 描述 (如果有)
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // 底部信息栏 (截止日期、标签、来源)
                    const SizedBox(height: 8),
                    _buildBottomInfo(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context, WidgetRef ref) async {
    try {
      await TaskService.instance.markTaskAsRead(task.id);
      // 立即刷新列表以获得即时动画反馈
      // Isar watch 也会触发，但这里主动刷新可更快反馈
      await ref.read(taskListProvider.notifier).loadTasks();
    } catch (_) {}
  }

  Widget _buildTopRightMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_TaskItemMenuAction>(
      tooltip: '更多',
      icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade700),
      onSelected: (action) async {
        switch (action) {
          case _TaskItemMenuAction.detail:
            await _markAsRead(context, ref);
            if (!context.mounted) return;
            await TaskDetailDialog.show(context, task);
            return;
          case _TaskItemMenuAction.dispatch:
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('开发中,请等待...')),
            );
            return;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _TaskItemMenuAction.detail,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 8),
              Text('详情'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _TaskItemMenuAction.dispatch,
          child: Row(
            children: [
              Icon(Icons.send_outlined, size: 18),
              SizedBox(width: 8),
              Text('任务派发'),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建完成状态复选框
  Widget _buildCheckbox(BuildContext context, WidgetRef ref) {
    return Checkbox(
      value: task.isCompleted,
      onChanged: (value) async {
        await ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// 构建优先级指示器
  Widget _buildPriorityIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Color(task.priority.colorValue),
        shape: BoxShape.circle,
      ),
    );
  }

  /// 构建底部信息栏
  Widget _buildBottomInfo(ThemeData theme) {
    final infoWidgets = <Widget>[];

    // 截止日期
    if (task.dueDate != null) {
      final dueDateWidget = _buildDueDateChip(theme);
      if (dueDateWidget != null) {
        infoWidgets.add(dueDateWidget);
      }
    }

    // 标签
    if (task.tags != null && task.tags!.isNotEmpty) {
      infoWidgets.add(_buildTagsChip(theme));
    }

    // AI创建标识
    if (task.source == TaskSource.ai) {
      infoWidgets.add(_buildAISourceChip(theme));
    }

    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: infoWidgets,
    );
  }

  /// 构建截止日期芯片
  Widget? _buildDueDateChip(ThemeData theme) {
    if (task.dueDate == null) return null;

    final dateFormat = DateFormat('MM/dd HH:mm');
    final dateStr = dateFormat.format(task.dueDate!);

    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (task.isCompleted) {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
      icon = Icons.event_available;
    } else if (task.isOverdue) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.event_busy;
    } else if (task.isDueSoon) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.event_note;
    } else {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.event;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            dateStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签芯片
  Widget _buildTagsChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label, size: 14, color: Colors.purple.shade700),
          const SizedBox(width: 4),
          Text(
            task.tags!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.purple.shade700,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建AI来源芯片
  Widget _buildAISourceChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: Colors.teal.shade700),
          const SizedBox(width: 4),
          Text(
            'AI创建',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.teal.shade700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示上下文菜单
  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 菜单项
            ListTile(
              leading: Icon(
                task.isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle,
              ),
              title: Text(task.isCompleted ? '标记为未完成' : '标记为已完成'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(taskListProvider.notifier)
                    .toggleTaskCompletion(task.id);
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _confirmDelete(context);
                if (confirmed && onDelete != null) {
                  onDelete?.call();
                } else if (confirmed) {
                  await ref.read(taskListProvider.notifier).deleteTask(task.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 确认删除对话框
  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除任务"${task.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}
