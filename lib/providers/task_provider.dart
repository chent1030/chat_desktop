import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/mqtt_service.dart';

// ============================================
// TaskService Provider
// ============================================

/// TaskService实例provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService.instance;
});

// ============================================
// T024: TaskListProvider - 管理任务列表状态
// ============================================

/// 任务列表筛选选项
enum TaskFilter {
  all, // 所有任务
  incomplete, // 未完成
  completed, // 已完成
  overdue, // 逾期
  dueSoon, // 即将到期
  today, // 今天
}

/// 任务排序选项
enum TaskSortOrder {
  createdAtDesc, // 创建时间降序
  createdAtAsc, // 创建时间升序
  dueDateAsc, // 截止日期升序
  dueDateDesc, // 截止日期降序
  priorityDesc, // 优先级降序 (高->低)
  priorityAsc, // 优先级升序 (低->高)
  titleAsc, // 标题升序
}

/// 任务列表状态
class TaskListState {
  final List<Task> tasks;
  final TaskFilter filter;
  final TaskSortOrder sortOrder;
  final String searchKeyword;
  final bool isLoading;
  final String? error;

  const TaskListState({
    this.tasks = const [],
    this.filter = TaskFilter.all,
    this.sortOrder = TaskSortOrder.createdAtDesc,
    this.searchKeyword = '',
    this.isLoading = false,
    this.error,
  });

  TaskListState copyWith({
    List<Task>? tasks,
    TaskFilter? filter,
    TaskSortOrder? sortOrder,
    String? searchKeyword,
    bool? isLoading,
    String? error,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      sortOrder: sortOrder ?? this.sortOrder,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// TaskListProvider - 管理任务列表的状态和操作
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskService _taskService;
  StreamSubscription<void>? _taskWatchSubscription;
  StreamSubscription<void>? _mqttTaskChangeSubscription;

  TaskListNotifier(this._taskService) : super(const TaskListState()) {
    print('🎯 [Provider] TaskListNotifier 初始化');

    // 初始化时加载任务
    loadTasks();

    // 监听数据库变化，自动刷新任务列表
    _taskWatchSubscription = _taskService.watchTasks().listen((_) {
      print('📊 [Provider] 检测到数据库变化（Isar Watch），重新加载任务列表');
      loadTasks();
    });

    // 监听MQTT任务变更通知
    try {
      _mqttTaskChangeSubscription = MqttService.instance.taskChangeStream.listen(
        (_) {
          print('📊 [Provider] 收到MQTT任务变更通知，重新加载任务列表');
          loadTasks();
        },
        onError: (error) {
          print('❌ [Provider] MQTT任务变更监听错误: $error');
        },
      );
      print('✓ [Provider] 已订阅MQTT任务变更通知');
    } catch (e) {
      print('❌ [Provider] 订阅MQTT任务变更失败: $e');
    }
  }

  @override
  void dispose() {
    _taskWatchSubscription?.cancel();
    _mqttTaskChangeSubscription?.cancel();
    super.dispose();
  }

  /// 加载任务
  Future<void> loadTasks() async {
    print('📊 [Provider] loadTasks() 被调用');
    state = state.copyWith(isLoading: true, error: null);

    try {
      List<Task> tasks;

      // 根据筛选条件获取任务
      switch (state.filter) {
        case TaskFilter.all:
          tasks = await _taskService.getAllTasks();
          break;
        case TaskFilter.incomplete:
          tasks = await _taskService.getIncompleteTasks();
          break;
        case TaskFilter.completed:
          tasks = await _taskService.getCompletedTasks();
          break;
        case TaskFilter.overdue:
          tasks = await _taskService.getOverdueTasks();
          break;
        case TaskFilter.dueSoon:
          tasks = await _taskService.getDueSoonTasks();
          break;
        case TaskFilter.today:
          tasks = await _taskService.getTodayTasks();
          break;
      }

      // 应用搜索关键词
      if (state.searchKeyword.isNotEmpty) {
        final keyword = state.searchKeyword.toLowerCase();
        tasks = tasks
            .where((task) =>
                task.title.toLowerCase().contains(keyword) ||
                (task.description?.toLowerCase().contains(keyword) ?? false))
            .toList();
      }

      // 应用排序
      tasks = _sortTasks(tasks, state.sortOrder);

      print('✓ [Provider] 加载了 ${tasks.length} 个任务');
      state = state.copyWith(tasks: tasks, isLoading: false);
      print('✓ [Provider] UI状态已更新');
    } catch (e) {
      print('❌ [Provider] 加载任务失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '加载任务失败: $e',
      );
    }
  }

  /// 设置筛选条件
  void setFilter(TaskFilter filter) {
    state = state.copyWith(filter: filter);
    loadTasks();
  }

  /// 设置排序顺序
  void setSortOrder(TaskSortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
    loadTasks();
  }

  /// 设置搜索关键词
  void setSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword);
    loadTasks();
  }

  /// 清除搜索
  void clearSearch() {
    state = state.copyWith(searchKeyword: '');
    loadTasks();
  }

  /// 刷新任务列表
  Future<void> refresh() async {
    await loadTasks();
  }

  /// 切换任务完成状态
  Future<void> toggleTaskCompletion(int taskId) async {
    try {
      await _taskService.toggleTaskCompletion(taskId);
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: '切换任务状态失败: $e');
    }
  }

  /// 删除任务
  Future<void> deleteTask(int taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: '删除任务失败: $e');
    }
  }

  /// 清除所有已完成任务
  Future<void> clearCompletedTasks() async {
    try {
      await _taskService.clearCompletedTasks();
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: '清除已完成任务失败: $e');
    }
  }

  /// 排序任务
  List<Task> _sortTasks(List<Task> tasks, TaskSortOrder sortOrder) {
    final sortedTasks = List<Task>.from(tasks);

    switch (sortOrder) {
      case TaskSortOrder.createdAtDesc:
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TaskSortOrder.createdAtAsc:
        sortedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TaskSortOrder.dueDateAsc:
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortOrder.dueDateDesc:
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case TaskSortOrder.priorityDesc:
        sortedTasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TaskSortOrder.priorityAsc:
        sortedTasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case TaskSortOrder.titleAsc:
        sortedTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return sortedTasks;
  }
}

/// TaskListProvider实例
/// 注意：不使用autoDispose，确保provider在应用生命周期内始终存在
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  print('🎯 [Provider] 创建 TaskListProvider');
  final taskService = ref.watch(taskServiceProvider);
  return TaskListNotifier(taskService);
});

// ============================================
// T025: TaskFormProvider - 管理任务表单状态
// ============================================

/// 任务表单状态
class TaskFormState {
  final String title;
  final String description;
  final Priority priority;
  final DateTime? dueDate;
  final String? tags;
  final bool isEditing; // true = 编辑模式, false = 创建模式
  final int? editingTaskId; // 正在编辑的任务ID
  final bool isSaving;
  final String? error;

  const TaskFormState({
    this.title = '',
    this.description = '',
    this.priority = Priority.medium,
    this.dueDate,
    this.tags,
    this.isEditing = false,
    this.editingTaskId,
    this.isSaving = false,
    this.error,
  });

  TaskFormState copyWith({
    String? title,
    String? description,
    Priority? priority,
    DateTime? dueDate,
    String? tags,
    bool? isEditing,
    int? editingTaskId,
    bool? isSaving,
    String? error,
  }) {
    return TaskFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      isEditing: isEditing ?? this.isEditing,
      editingTaskId: editingTaskId ?? this.editingTaskId,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }

  /// 表单是否有效
  bool get isValid => title.trim().isNotEmpty;

  /// 重置表单
  TaskFormState reset() {
    return const TaskFormState();
  }
}

/// TaskFormProvider - 管理任务表单的状态和操作
class TaskFormNotifier extends StateNotifier<TaskFormState> {
  final TaskService _taskService;

  TaskFormNotifier(this._taskService) : super(const TaskFormState());

  /// 设置标题
  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// 设置描述
  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  /// 设置优先级
  void setPriority(Priority priority) {
    state = state.copyWith(priority: priority);
  }

  /// 设置截止日期
  void setDueDate(DateTime? dueDate) {
    state = state.copyWith(dueDate: dueDate);
  }

  /// 设置标签
  void setTags(String? tags) {
    state = state.copyWith(tags: tags);
  }

  /// 加载任务到表单 (用于编辑)
  Future<void> loadTask(int taskId) async {
    final task = await _taskService.getTaskById(taskId);
    if (task == null) {
      state = state.copyWith(error: '任务不存在');
      return;
    }

    state = TaskFormState(
      title: task.title,
      description: task.description ?? '',
      priority: task.priority,
      dueDate: task.dueDate,
      tags: task.tags,
      isEditing: true,
      editingTaskId: taskId,
    );
  }

  /// 保存任务 (创建或更新)
  Future<bool> saveTask() async {
    if (!state.isValid) {
      state = state.copyWith(error: '任务标题不能为空');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      if (state.isEditing && state.editingTaskId != null) {
        // 更新现有任务
        final task = await _taskService.getTaskById(state.editingTaskId!);
        if (task == null) {
          state = state.copyWith(isSaving: false, error: '任务不存在');
          return false;
        }

        final updatedTask = task.copyWith(
          title: state.title.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          priority: state.priority,
          dueDate: state.dueDate,
          tags: state.tags,
        );

        await _taskService.updateTask(updatedTask);
      } else {
        // 创建新任务
        await _taskService.createTask(
          title: state.title.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          priority: state.priority,
          dueDate: state.dueDate,
          tags: state.tags,
        );
      }

      state = state.copyWith(isSaving: false);
      reset();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: '保存任务失败: $e',
      );
      return false;
    }
  }

  /// 重置表单
  void reset() {
    state = const TaskFormState();
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// TaskFormProvider实例
final taskFormProvider =
    StateNotifierProvider<TaskFormNotifier, TaskFormState>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TaskFormNotifier(taskService);
});

// ============================================
// 辅助 Providers
// ============================================

/// 任务变化流Provider（用于触发其他Provider刷新）
final taskChangesStreamProvider = StreamProvider<void>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.watchTasks();
});

/// 任务统计信息provider
final taskStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // 监听任务变化
  ref.watch(taskChangesStreamProvider);
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getTaskStatistics();
});

/// 任务总数provider
final taskCountProvider = FutureProvider<int>((ref) async {
  // 监听任务变化
  ref.watch(taskChangesStreamProvider);
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getTaskCount();
});

/// 未完成任务数量provider (用于角标)
final incompleteTaskCountProvider = FutureProvider<int>((ref) async {
  // 监听任务变化
  ref.watch(taskChangesStreamProvider);
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getIncompleteTaskCount();
});

/// 单个任务provider (根据ID)
final taskProvider = FutureProvider.family<Task?, int>((ref, taskId) async {
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getTaskById(taskId);
});
