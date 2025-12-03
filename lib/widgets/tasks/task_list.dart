import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_indicator.dart';
import 'task_item.dart';

/// TaskList widget - 显示任务列表
class TaskList extends ConsumerStatefulWidget {
  final VoidCallback? onTaskTap;
  final Function(Task)? onTaskEdit;
  final Function(Task)? onTaskDelete;

  const TaskList({
    super.key,
    this.onTaskTap,
    this.onTaskEdit,
    this.onTaskDelete,
  });

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  @override
  void initState() {
    super.initState();
    // 组件初始化时加载任务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskListState = ref.watch(taskListProvider);

    return Column(
      children: [
        // 顶部工具栏 (筛选和排序)
        _buildToolbar(context, taskListState),

        // 任务列表
        Expanded(
          child: _buildTaskListContent(context, taskListState),
        ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(BuildContext context, TaskListState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 筛选按钮
          _buildFilterButton(context, state),
          const SizedBox(width: 8),

          // 排序按钮
          _buildSortButton(context, state),

          const Spacer(),

          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(taskListProvider.notifier).refresh();
            },
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterButton(BuildContext context, TaskListState state) {
    return PopupMenuButton<TaskFilter>(
      initialValue: state.filter,
      onSelected: (filter) {
        ref.read(taskListProvider.notifier).setFilter(filter);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: TaskFilter.all,
          child: Text('全部任务'),
        ),
        const PopupMenuItem(
          value: TaskFilter.incomplete,
          child: Text('未完成'),
        ),
        const PopupMenuItem(
          value: TaskFilter.completed,
          child: Text('已完成'),
        ),
        const PopupMenuItem(
          value: TaskFilter.overdue,
          child: Text('已逾期'),
        ),
        const PopupMenuItem(
          value: TaskFilter.dueSoon,
          child: Text('即将到期'),
        ),
        const PopupMenuItem(
          value: TaskFilter.today,
          child: Text('今天'),
        ),
      ],
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(_getFilterLabel(state.filter)),
      ),
    );
  }

  /// 构建排序按钮
  Widget _buildSortButton(BuildContext context, TaskListState state) {
    return PopupMenuButton<TaskSortOrder>(
      initialValue: state.sortOrder,
      onSelected: (sortOrder) {
        ref.read(taskListProvider.notifier).setSortOrder(sortOrder);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: TaskSortOrder.createdAtDesc,
          child: Text('创建时间 ↓'),
        ),
        const PopupMenuItem(
          value: TaskSortOrder.createdAtAsc,
          child: Text('创建时间 ↑'),
        ),
        const PopupMenuItem(
          value: TaskSortOrder.dueDateAsc,
          child: Text('截止日期 ↑'),
        ),
        const PopupMenuItem(
          value: TaskSortOrder.dueDateDesc,
          child: Text('截止日期 ↓'),
        ),
        const PopupMenuItem(
          value: TaskSortOrder.priorityDesc,
          child: Text('优先级 ↓'),
        ),
        const PopupMenuItem(
          value: TaskSortOrder.priorityAsc,
          child: Text('优先级 ↑'),
        ),
        const PopupMenuItem(
          value: TaskSortOrder.titleAsc,
          child: Text('标题 A-Z'),
        ),
      ],
      child: Chip(
        avatar: const Icon(Icons.sort, size: 18),
        label: Text(_getSortOrderLabel(state.sortOrder)),
      ),
    );
  }

  /// 构建任务列表内容
  Widget _buildTaskListContent(BuildContext context, TaskListState state) {
    // 加载中
    if (state.isLoading) {
      return const LoadingIndicator(message: '加载任务中...');
    }

    // 错误状态
    if (state.error != null) {
      return ErrorView(
        message: '加载失败',
        details: state.error,
        onRetry: () {
          ref.read(taskListProvider.notifier).refresh();
        },
      );
    }

    // 空状态
    if (state.tasks.isEmpty) {
      return _buildEmptyState(context, state);
    }

    // 任务列表
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(taskListProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: state.tasks.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return TaskItem(
            key: ValueKey(task.id),
            task: task,
            onTap: widget.onTaskTap,
            onEdit: widget.onTaskEdit != null
                ? () => widget.onTaskEdit!(task)
                : null,
            onDelete: widget.onTaskDelete != null
                ? () => widget.onTaskDelete!(task)
                : null,
          );
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context, TaskListState state) {
    String message;
    String? subtitle;
    IconData icon;

    switch (state.filter) {
      case TaskFilter.all:
        message = '还没有任务';
        subtitle = '点击下方按钮创建你的第一个任务';
        icon = Icons.task_alt;
        break;
      case TaskFilter.incomplete:
        message = '没有未完成的任务';
        subtitle = '太棒了!所有任务都已完成';
        icon = Icons.check_circle_outline;
        break;
      case TaskFilter.completed:
        message = '没有已完成的任务';
        subtitle = '完成任务后会显示在这里';
        icon = Icons.inbox_outlined;
        break;
      case TaskFilter.overdue:
        message = '没有逾期的任务';
        subtitle = '做得很好!';
        icon = Icons.event_available;
        break;
      case TaskFilter.dueSoon:
        message = '没有即将到期的任务';
        subtitle = '接下来24小时内没有任务到期';
        icon = Icons.event_note;
        break;
      case TaskFilter.today:
        message = '今天没有任务';
        subtitle = '享受你的空闲时间';
        icon = Icons.wb_sunny;
        break;
    }

    if (state.searchKeyword.isNotEmpty) {
      message = '没有找到匹配的任务';
      subtitle = '尝试使用其他关键词搜索';
      icon = Icons.search_off;
    }

    return EmptyView(
      message: message,
      subtitle: subtitle,
      icon: icon,
    );
  }

  /// 获取筛选标签
  String _getFilterLabel(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return '全部';
      case TaskFilter.incomplete:
        return '未完成';
      case TaskFilter.completed:
        return '已完成';
      case TaskFilter.overdue:
        return '已逾期';
      case TaskFilter.dueSoon:
        return '即将到期';
      case TaskFilter.today:
        return '今天';
    }
  }

  /// 获取排序标签
  String _getSortOrderLabel(TaskSortOrder sortOrder) {
    switch (sortOrder) {
      case TaskSortOrder.createdAtDesc:
        return '创建时间↓';
      case TaskSortOrder.createdAtAsc:
        return '创建时间↑';
      case TaskSortOrder.dueDateAsc:
        return '截止日期↑';
      case TaskSortOrder.dueDateDesc:
        return '截止日期↓';
      case TaskSortOrder.priorityDesc:
        return '优先级↓';
      case TaskSortOrder.priorityAsc:
        return '优先级↑';
      case TaskSortOrder.titleAsc:
        return '标题A-Z';
    }
  }
}
