import 'package:isar/isar.dart';
import '../models/task.dart';
import '../models/task_action.dart';
import 'storage_service.dart';

/// 任务管理服务 - 负责任务的CRUD操作
class TaskService {
  static TaskService? _instance;
  final StorageService _storageService;

  TaskService._() : _storageService = StorageService.instance;

  static TaskService get instance {
    _instance ??= TaskService._();
    return _instance!;
  }

  /// 获取Isar实例的快捷方式
  Isar get _isar => _storageService.isar;

  // ============================================
  // CRUD 操作
  // ============================================

  /// 创建新任务
  /// 返回创建的任务ID
  Future<int> createTask({
    required String title,
    String? description,
    Priority priority = Priority.medium,
    DateTime? dueDate,
    String? tags,
    TaskSource source = TaskSource.manual,
    String? createdByAgentId,
  }) async {
    final now = DateTime.now();

    final task = Task(
      title: title.trim(),
      description: description?.trim(),
      priority: priority,
      isCompleted: false,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      source: source,
      createdByAgentId: createdByAgentId,
      tags: tags,
      isSynced: false,
    );

    // 保存任务到数据库
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    // 记录操作
    await _recordAction(
      TaskActionHelper.createTaskCreated(
        taskId: task.id,
        title: task.title,
        performedBy: source == TaskSource.ai && createdByAgentId != null
            ? createdByAgentId
            : 'user',
      ),
    );

    print('✓ 任务已创建: ${task.title} (ID: ${task.id})');
    return task.id;
  }

  /// 直接保存Task对象（用于MQTT等外部来源，保留完整信息包括UUID）
  Future<int> createTaskDirect(Task task) async {
    // 保存任务到数据库
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    // 记录操作
    await _recordAction(
      TaskActionHelper.createTaskCreated(
        taskId: task.id,
        title: task.title,
        performedBy: task.source == TaskSource.ai && task.createdByAgentId != null
            ? task.createdByAgentId!
            : 'mqtt',
      ),
    );

    print('✓ 任务已创建: ${task.title} (ID: ${task.id}, UUID: ${task.uuid})');
    return task.id;
  }

  /// 根据ID获取任务
  Future<Task?> getTaskById(int id) async {
    return await _isar.tasks.get(id);
  }

  /// 获取所有任务
  Future<List<Task>> getAllTasks() async {
    return await _isar.tasks.where().findAll();
  }

  /// 更新任务
  Future<void> updateTask(Task task) async {
    // 更新时间戳
    task.touch();
    task.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    // 记录操作
    await _recordAction(
      TaskActionHelper.createTaskUpdated(
        taskId: task.id,
        changes: {'title': task.title}, // 简化版本
        performedBy: 'user',
      ),
    );

    print('✓ 任务已更新: ${task.title}');
  }

  /// 删除任务
  Future<void> deleteTask(int taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      print('✗ 任务不存在: $taskId');
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.tasks.delete(taskId);
    });

    // 记录操作
    await _recordAction(
      TaskActionHelper.createTaskDeleted(
        taskId: taskId,
        title: task.title,
        performedBy: 'user',
      ),
    );

    print('✓ 任务已删除: ${task.title}');
  }

  /// 删除多个任务
  Future<void> deleteTasks(List<int> taskIds) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.deleteAll(taskIds);
    });

    print('✓ 已删除 ${taskIds.length} 个任务');
  }

  // ============================================
  // 任务状态操作
  // ============================================

  /// 标记任务为已完成
  Future<void> markTaskAsCompleted(int taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      print('✗ 任务不存在: $taskId');
      return;
    }

    task.markAsCompleted();
    task.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    // 记录操作
    await _recordAction(
      TaskActionHelper.createTaskCompleted(
        taskId: taskId,
        performedBy: 'user',
      ),
    );

    print('✓ 任务已完成: ${task.title}');
  }

  /// 标记任务为未完成
  Future<void> markTaskAsIncomplete(int taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      print('✗ 任务不存在: $taskId');
      return;
    }

    task.markAsIncomplete();
    task.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    // 记录操作
    await _recordAction(
      TaskActionHelper.createTaskUncompleted(
        taskId: taskId,
        performedBy: 'user',
      ),
    );

    print('✓ 任务标记为未完成: ${task.title}');
  }

  /// 切换任务完成状态
  Future<void> toggleTaskCompletion(int taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) return;

    if (task.isCompleted) {
      await markTaskAsIncomplete(taskId);
    } else {
      await markTaskAsCompleted(taskId);
    }
  }

  /// 标记任务为已读
  Future<void> markTaskAsRead(int taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      print('✗ 任务不存在: $taskId');
      return;
    }

    // 如果已经是已读状态，不需要重复操作
    if (task.isRead) {
      return;
    }

    task.markAsRead();
    task.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    print('✓ 任务已标记为已读: ${task.title}');
  }

  /// 标记任务为未读
  Future<void> markTaskAsUnread(int taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      print('✗ 任务不存在: $taskId');
      return;
    }

    task.markAsUnread();
    task.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    print('✓ 任务标记为未读: ${task.title}');
  }

  /// 分发任务给用户或团队
  Future<void> assignTask({
    required int taskId,
    required String assignedTo,
    required String assignedToType, // 'user' 或 'team'
    required String assignedBy,
  }) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      print('✗ 任务不存在: $taskId');
      return;
    }

    final updatedTask = task.copyWith(
      assignedTo: assignedTo,
      assignedToType: assignedToType,
      assignedBy: assignedBy,
      assignedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });

    print('✓ 任务已分发: ${task.title} -> $assignedTo ($assignedToType)');
  }

  /// 取消任务分发
  Future<void> unassignTask(int taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) {
      print('✗ 任务不存在: $taskId');
      return;
    }

    final updatedTask = task.copyWith(
      assignedTo: null,
      assignedToType: null,
      assignedBy: null,
      assignedAt: null,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });

    print('✓ 任务分发已取消: ${task.title}');
  }

  // ============================================
  // 查询操作
  // ============================================

  /// 获取未完成的任务
  Future<List<Task>> getIncompleteTasks() async {
    return await _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 获取已完成的任务
  Future<List<Task>> getCompletedTasks() async {
    return await _isar.tasks
        .filter()
        .isCompletedEqualTo(true)
        .sortByCompletedAtDesc()
        .findAll();
  }

  /// 根据优先级获取任务
  Future<List<Task>> getTasksByPriority(Priority priority) async {
    return await _isar.tasks
        .filter()
        .priorityEqualTo(priority)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 获取逾期的任务
  Future<List<Task>> getOverdueTasks() async {
    final now = DateTime.now();
    return await _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .dueDateLessThan(now)
        .sortByDueDate()
        .findAll();
  }

  /// 获取即将到期的任务 (24小时内)
  Future<List<Task>> getDueSoonTasks() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));

    return await _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .dueDateBetween(now, tomorrow)
        .sortByDueDate()
        .findAll();
  }

  /// 获取今天的任务
  Future<List<Task>> getTodayTasks() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _isar.tasks
        .filter()
        .dueDateBetween(startOfDay, endOfDay)
        .sortByDueDate()
        .findAll();
  }

  /// 搜索任务 (根据标题或描述)
  Future<List<Task>> searchTasks(String keyword) async {
    final lowerKeyword = keyword.toLowerCase().trim();
    if (lowerKeyword.isEmpty) {
      return await getAllTasks();
    }

    return await _isar.tasks
        .filter()
        .titleContains(lowerKeyword, caseSensitive: false)
        .or()
        .descriptionContains(lowerKeyword, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 获取任务总数
  Future<int> getTaskCount() async {
    return await _isar.tasks.count();
  }

  /// 获取未完成任务数量
  Future<int> getIncompleteTaskCount() async {
    return await _isar.tasks.filter().isCompletedEqualTo(false).count();
  }

  /// 获取已完成任务数量
  Future<int> getCompletedTaskCount() async {
    return await _isar.tasks.filter().isCompletedEqualTo(true).count();
  }

  // ============================================
  // TaskAction 操作记录
  // ============================================

  /// 记录任务操作
  Future<void> _recordAction(TaskAction action) async {
    await _isar.writeTxn(() async {
      await _isar.taskActions.put(action);
    });
  }

  /// 获取任务的操作历史
  Future<List<TaskAction>> getTaskActions(int taskId) async {
    return await _isar.taskActions
        .filter()
        .taskIdEqualTo(taskId)
        .sortByTimestampDesc()
        .findAll();
  }

  /// 获取最近的操作记录
  Future<List<TaskAction>> getRecentActions({int limit = 20}) async {
    return await _isar.taskActions
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }

  // ============================================
  // 批量操作
  // ============================================

  /// 批量创建任务
  Future<List<int>> createTasks(List<Task> tasks) async {
    final ids = <int>[];

    await _isar.writeTxn(() async {
      for (final task in tasks) {
        final id = await _isar.tasks.put(task);
        ids.add(id);
      }
    });

    print('✓ 已批量创建 ${tasks.length} 个任务');
    return ids;
  }

  /// 批量更新任务
  Future<void> updateTasks(List<Task> tasks) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.putAll(tasks);
    });

    print('✓ 已批量更新 ${tasks.length} 个任务');
  }

  /// 标记所有任务为已完成
  Future<void> markAllTasksAsCompleted() async {
    final tasks = await getIncompleteTasks();

    for (final task in tasks) {
      task.markAsCompleted();
    }

    await updateTasks(tasks);
    print('✓ 已标记所有任务为已完成');
  }

  /// 清除所有已完成的任务
  Future<void> clearCompletedTasks() async {
    final completedTasks = await getCompletedTasks();
    final taskIds = completedTasks.map((t) => t.id).toList();

    await deleteTasks(taskIds);
    print('✓ 已清除 ${taskIds.length} 个已完成任务');
  }

  // ============================================
  // 统计信息
  // ============================================

  /// 获取任务统计信息
  Future<Map<String, dynamic>> getTaskStatistics() async {
    final total = await getTaskCount();
    final incomplete = await getIncompleteTaskCount();
    final completed = await getCompletedTaskCount();
    final overdue = (await getOverdueTasks()).length;
    final dueSoon = (await getDueSoonTasks()).length;

    return {
      'total': total,
      'incomplete': incomplete,
      'completed': completed,
      'overdue': overdue,
      'dueSoon': dueSoon,
      'completionRate':
          total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0',
    };
  }

  /// 获取按优先级分组的任务数量
  Future<Map<Priority, int>> getTaskCountByPriority() async {
    final result = <Priority, int>{};

    for (final priority in Priority.values) {
      final count = await _isar.tasks
          .filter()
          .priorityEqualTo(priority)
          .isCompletedEqualTo(false)
          .count();
      result[priority] = count;
    }

    return result;
  }

  // ============================================
  // 工具方法
  // ============================================

  /// 监听任务变化 (实时更新)
  Stream<void> watchTasks() {
    return _isar.tasks.watchLazy();
  }

  /// 监听特定任务的变化
  Stream<Task?> watchTask(int taskId) {
    return _isar.tasks.watchObject(taskId);
  }

  /// 清除所有任务 (用于测试)
  Future<void> clearAllTasks() async {
    await _isar.writeTxn(() async {
      await _isar.tasks.clear();
      await _isar.taskActions.clear();
    });

    print('✓ 已清除所有任务和操作记录');
  }
}
