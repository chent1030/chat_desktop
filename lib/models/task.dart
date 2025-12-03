import 'package:isar/isar.dart';

part 'task.g.dart';

/// 任务优先级枚举
enum Priority {
  low,    // 0
  medium, // 1
  high,   // 2
}

/// 任务来源枚举
enum TaskSource {
  manual, // 用户手动创建 - 0
  ai,     // AI助手创建 - 1
}

/// 任务实体模型
@Collection()
class Task {
  /// 任务ID (自动生成)
  Id id = Isar.autoIncrement;

  /// 任务标题
  @Index(type: IndexType.value)
  late String title;

  /// 任务描述 (可选)
  String? description;

  /// 优先级 (默认: medium)
  @Enumerated(EnumType.ordinal)
  @Index()
  late Priority priority;

  /// 是否已完成
  @Index()
  late bool isCompleted;

  /// 截止日期 (可选)
  DateTime? dueDate;

  /// 创建时间
  @Index()
  late DateTime createdAt;

  /// 更新时间
  @Index()
  late DateTime updatedAt;

  /// 任务来源 (默认: manual)
  @Enumerated(EnumType.ordinal)
  late TaskSource source;

  /// 创建该任务的AI智能体ID (如果source=ai)
  String? createdByAgentId;

  /// 完成时间 (仅当isCompleted=true时有值)
  DateTime? completedAt;

  /// 任务标签/分类 (可选, 逗号分隔)
  String? tags;

  /// 是否已同步到云端
  late bool isSynced;

  /// 最后同步时间
  DateTime? lastSyncedAt;

  /// 构造函数
  Task({
    this.id = Isar.autoIncrement,
    required this.title,
    this.description,
    this.priority = Priority.medium,
    this.isCompleted = false,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.source = TaskSource.manual,
    this.createdByAgentId,
    this.completedAt,
    this.tags,
    this.isSynced = false,
    this.lastSyncedAt,
  });

  /// 复制方法 (用于更新任务)
  Task copyWith({
    Id? id,
    String? title,
    String? description,
    Priority? priority,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskSource? source,
    String? createdByAgentId,
    DateTime? completedAt,
    String? tags,
    bool? isSynced,
    DateTime? lastSyncedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      createdByAgentId: createdByAgentId ?? this.createdByAgentId,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// 是否逾期
  bool get isOverdue {
    if (dueDate == null || isCompleted) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  /// 是否即将到期 (24小时内)
  bool get isDueSoon {
    if (dueDate == null || isCompleted) {
      return false;
    }
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inHours > 0 && difference.inHours <= 24;
  }

  /// 标记为已完成
  void markAsCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// 标记为未完成
  void markAsIncomplete() {
    isCompleted = false;
    completedAt = null;
    updatedAt = DateTime.now();
  }

  /// 更新时间戳
  void touch() {
    updatedAt = DateTime.now();
  }

  /// 转换为JSON (用于WebSocket同步)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source.index,
      'createdByAgentId': createdByAgentId,
      'completedAt': completedAt?.toIso8601String(),
      'tags': tags,
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  /// 从JSON创建 (用于WebSocket同步)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as Id? ?? Isar.autoIncrement,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: Priority.values[json['priority'] as int? ?? 1],
      isCompleted: json['isCompleted'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      source: TaskSource.values[json['source'] as int? ?? 0],
      createdByAgentId: json['createdByAgentId'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      tags: json['tags'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, isCompleted: $isCompleted, dueDate: $dueDate)';
  }
}

/// 优先级扩展方法
extension PriorityExtension on Priority {
  /// 获取优先级的显示名称
  String get displayName {
    switch (this) {
      case Priority.low:
        return '低';
      case Priority.medium:
        return '中';
      case Priority.high:
        return '高';
    }
  }

  /// 获取优先级的颜色代码 (与AppTheme中的颜色对应)
  int get colorValue {
    switch (this) {
      case Priority.low:
        return 0xFF43A047; // 绿色
      case Priority.medium:
        return 0xFFFB8C00; // 橙色
      case Priority.high:
        return 0xFFE53935; // 红色
    }
  }
}

/// 任务来源扩展方法
extension TaskSourceExtension on TaskSource {
  /// 获取来源的显示名称
  String get displayName {
    switch (this) {
      case TaskSource.manual:
        return '手动创建';
      case TaskSource.ai:
        return 'AI创建';
    }
  }
}
