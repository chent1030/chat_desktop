import 'package:isar/isar.dart';
import 'task.dart';

part 'task_action.g.dart';

/// 任务操作类型枚举
enum ActionType {
  created,      // 创建任务 - 0
  updated,      // 更新任务 - 1
  completed,    // 标记为已完成 - 2
  uncompleted,  // 标记为未完成 - 3
  deleted,      // 删除任务 - 4
  restored,     // 恢复已删除的任务 - 5
}

/// 任务操作记录实体模型 (用于审计和撤销功能)
@Collection()
class TaskAction {
  /// 操作记录ID (自动生成)
  Id id = Isar.autoIncrement;

  /// 关联的任务ID (使用int而非Id类型)
  @Index()
  late int taskId;

  /// 操作类型
  @Enumerated(EnumType.ordinal)
  @Index()
  late ActionType actionType;

  /// 操作时间
  @Index()
  late DateTime timestamp;

  /// 执行操作的主体 (user/ai/<agentId>)
  late String performedBy;

  /// 变更内容 (JSON格式字符串, 存储变更前后的值)
  /// 格式: {"field": {"before": "old_value", "after": "new_value"}}
  String? changes;

  /// 操作描述 (人类可读的描述)
  String? description;

  /// 是否可撤销
  late bool canUndo;

  /// 构造函数
  TaskAction({
    this.id = Isar.autoIncrement,
    required this.taskId,
    required this.actionType,
    required this.timestamp,
    this.performedBy = 'user',
    this.changes,
    this.description,
    this.canUndo = true,
  });

  /// 转换为JSON (用于WebSocket同步)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'actionType': actionType.index,
      'timestamp': timestamp.toIso8601String(),
      'performedBy': performedBy,
      'changes': changes,
      'description': description,
      'canUndo': canUndo,
    };
  }

  /// 从JSON创建 (用于WebSocket同步)
  factory TaskAction.fromJson(Map<String, dynamic> json) {
    return TaskAction(
      id: json['id'] as Id? ?? Isar.autoIncrement,
      taskId: json['taskId'] as int,
      actionType: ActionType.values[json['actionType'] as int],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      performedBy: json['performedBy'] as String? ?? 'user',
      changes: json['changes'] as String?,
      description: json['description'] as String?,
      canUndo: json['canUndo'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'TaskAction(id: $id, taskId: $taskId, actionType: $actionType, timestamp: $timestamp, performedBy: $performedBy)';
  }
}

/// 操作类型扩展方法
extension ActionTypeExtension on ActionType {
  /// 获取操作类型的显示名称
  String get displayName {
    switch (this) {
      case ActionType.created:
        return '创建';
      case ActionType.updated:
        return '更新';
      case ActionType.completed:
        return '标记完成';
      case ActionType.uncompleted:
        return '标记未完成';
      case ActionType.deleted:
        return '删除';
      case ActionType.restored:
        return '恢复';
    }
  }

  /// 获取操作类型的图标名称 (Material Icons)
  String get iconName {
    switch (this) {
      case ActionType.created:
        return 'add_circle';
      case ActionType.updated:
        return 'edit';
      case ActionType.completed:
        return 'check_circle';
      case ActionType.uncompleted:
        return 'radio_button_unchecked';
      case ActionType.deleted:
        return 'delete';
      case ActionType.restored:
        return 'restore';
    }
  }

  /// 是否为可撤销的操作
  bool get isUndoable {
    switch (this) {
      case ActionType.created:
      case ActionType.updated:
      case ActionType.completed:
      case ActionType.uncompleted:
      case ActionType.deleted:
        return true;
      case ActionType.restored:
        return false; // 恢复操作本身不可撤销
    }
  }
}

/// 任务操作记录辅助类 (用于创建常见的操作记录)
class TaskActionHelper {
  /// 创建"创建任务"操作记录
  static TaskAction createTaskCreated({
    required int taskId,
    required String title,
    String performedBy = 'user',
  }) {
    return TaskAction(
      taskId: taskId,
      actionType: ActionType.created,
      timestamp: DateTime.now(),
      performedBy: performedBy,
      description: '创建任务: $title',
      canUndo: true,
    );
  }

  /// 创建"更新任务"操作记录
  static TaskAction createTaskUpdated({
    required int taskId,
    required Map<String, dynamic> changes,
    String performedBy = 'user',
  }) {
    return TaskAction(
      taskId: taskId,
      actionType: ActionType.updated,
      timestamp: DateTime.now(),
      performedBy: performedBy,
      changes: _serializeChanges(changes),
      description: '更新任务',
      canUndo: true,
    );
  }

  /// 创建"标记完成"操作记录
  static TaskAction createTaskCompleted({
    required int taskId,
    String performedBy = 'user',
  }) {
    return TaskAction(
      taskId: taskId,
      actionType: ActionType.completed,
      timestamp: DateTime.now(),
      performedBy: performedBy,
      description: '标记任务为已完成',
      canUndo: true,
    );
  }

  /// 创建"标记未完成"操作记录
  static TaskAction createTaskUncompleted({
    required int taskId,
    String performedBy = 'user',
  }) {
    return TaskAction(
      taskId: taskId,
      actionType: ActionType.uncompleted,
      timestamp: DateTime.now(),
      performedBy: performedBy,
      description: '标记任务为未完成',
      canUndo: true,
    );
  }

  /// 创建"删除任务"操作记录
  static TaskAction createTaskDeleted({
    required int taskId,
    required String title,
    String performedBy = 'user',
  }) {
    return TaskAction(
      taskId: taskId,
      actionType: ActionType.deleted,
      timestamp: DateTime.now(),
      performedBy: performedBy,
      description: '删除任务: $title',
      canUndo: true,
    );
  }

  /// 创建"恢复任务"操作记录
  static TaskAction createTaskRestored({
    required int taskId,
    required String title,
    String performedBy = 'user',
  }) {
    return TaskAction(
      taskId: taskId,
      actionType: ActionType.restored,
      timestamp: DateTime.now(),
      performedBy: performedBy,
      description: '恢复任务: $title',
      canUndo: false,
    );
  }

  /// 序列化变更内容为JSON字符串
  static String _serializeChanges(Map<String, dynamic> changes) {
    // 简单实现, 实际可以使用json.encode()
    final buffer = StringBuffer('{');
    final entries = changes.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}": ');

      if (entry.value is Map) {
        buffer.write('{');
        final valueMap = entry.value as Map;
        buffer.write('"before": "${valueMap['before']}", ');
        buffer.write('"after": "${valueMap['after']}"');
        buffer.write('}');
      } else {
        buffer.write('"${entry.value}"');
      }

      if (i < entries.length - 1) {
        buffer.write(', ');
      }
    }

    buffer.write('}');
    return buffer.toString();
  }
}
