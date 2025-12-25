import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

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

  /// 全局唯一标识符 (用于MQTT同步去重)
  /// 内部命名使用 taskUid 以避免与外部部分数据库保留/常用名冲突
  @Index(unique: true, replace: true)
  String? taskUid;
  // 兼容已生成的 Isar 代码与既有调用：暴露 uuid 访问器
  String? get uuid => taskUid;
  set uuid(String? value) => taskUid = value;

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

  /// 是否已读
  @Index()
  late bool isRead;

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

  /// 分配给谁 (用户ID或团队ID)
  String? assignedTo;

  /// 分配类型 (user 或 team)
  String? assignedToType;

  /// 分配者
  String? assignedBy;

  /// 分配时间
  DateTime? assignedAt;

  /// 构造函数
  Task({
    this.id = Isar.autoIncrement,
    String? uuid,
    required this.title,
    this.description,
    this.priority = Priority.medium,
    this.isCompleted = false,
    this.isRead = false,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.source = TaskSource.manual,
    this.createdByAgentId,
    this.completedAt,
    this.tags,
    this.isSynced = false,
    this.lastSyncedAt,
    this.assignedTo,
    this.assignedToType,
    this.assignedBy,
    this.assignedAt,
  }) {
    // 如果uuid为null，生成一个新的
    taskUid = uuid ?? const Uuid().v4();
  }

  /// 复制方法 (用于更新任务)
  Task copyWith({
    Id? id,
    String? uuid,
    String? title,
    String? description,
    Priority? priority,
    bool? isCompleted,
    bool? isRead,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskSource? source,
    String? createdByAgentId,
    DateTime? completedAt,
    String? tags,
    bool? isSynced,
    DateTime? lastSyncedAt,
    String? assignedTo,
    String? assignedToType,
    String? assignedBy,
    DateTime? assignedAt,
  }) {
    return Task(
      id: id ?? this.id,
      uuid: uuid ?? taskUid,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isRead: isRead ?? this.isRead,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      createdByAgentId: createdByAgentId ?? this.createdByAgentId,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToType: assignedToType ?? this.assignedToType,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
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

  /// 标记为已读
  void markAsRead() {
    isRead = true;
    updatedAt = DateTime.now();
  }

  /// 标记为未读
  void markAsUnread() {
    isRead = false;
    updatedAt = DateTime.now();
  }

  /// 更新时间戳
  void touch() {
    updatedAt = DateTime.now();
  }

  /// 转换为JSON (用于MQTT同步)
  Map<String, dynamic> toJson() {
    final dateFormat = 'yyyy-MM-dd HH:mm:ss';

    String? formatDateTime(DateTime? dateTime) {
      if (dateTime == null) return null;
      return '${dateTime.year.toString().padLeft(4, '0')}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}:'
          '${dateTime.second.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'uuid': taskUid,
      'title': title,
      'description': description,
      'priority': priority.index,
      'isCompleted': isCompleted,
      'isRead': isRead,
      'dueDate': formatDateTime(dueDate),
      'createdAt': formatDateTime(createdAt),
      'updatedAt': formatDateTime(updatedAt),
      'source': source.index,
      'createdByAgentId': createdByAgentId,
      'completedAt': formatDateTime(completedAt),
      'tags': tags,
      'isSynced': isSynced,
      'lastSyncedAt': formatDateTime(lastSyncedAt),
      'assignedTo': assignedTo,
      'assignedToType': assignedToType,
      'assignedBy': assignedBy,
      'assignedAt': formatDateTime(assignedAt),
    };
  }

  /// 从JSON创建 (用于MQTT同步)
  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(String? dateTimeStr) {
      if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
      try {
        // 支持 yyyy-MM-dd HH:mm:ss 格式
        final parts = dateTimeStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');

          return DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            int.parse(timeParts[2]),
          );
        }
        // 兼容ISO8601格式
        return DateTime.parse(dateTimeStr);
      } catch (e) {
        print('解析时间失败: $dateTimeStr, error: $e');
        return null;
      }
    }

    return Task(
      id: json['id'] as Id? ?? Isar.autoIncrement,
      uuid: json['uuid'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: Priority.values[json['priority'] as int? ?? 1],
      isCompleted: json['isCompleted'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      dueDate: parseDateTime(json['dueDate'] as String?),
      createdAt: parseDateTime(json['createdAt'] as String?) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt'] as String?) ?? DateTime.now(),
      source: TaskSource.values[json['source'] as int? ?? 0],
      createdByAgentId: json['createdByAgentId'] as String?,
      completedAt: parseDateTime(json['completedAt'] as String?),
      tags: json['tags'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      lastSyncedAt: parseDateTime(json['lastSyncedAt'] as String?),
      assignedTo: json['assignedTo'] as String?,
      assignedToType: json['assignedToType'] as String?,
      assignedBy: json['assignedBy'] as String?,
      assignedAt: parseDateTime(json['assignedAt'] as String?),
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, taskUid: $taskUid, title: $title, priority: $priority, isCompleted: $isCompleted, dueDate: $dueDate)';
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
