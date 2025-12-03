import 'package:isar/isar.dart';

part 'conversation.g.dart';

/// 会话实体模型
@Collection()
class Conversation {
  /// 会话ID (自动生成)
  Id id = Isar.autoIncrement;

  /// 关联的智能体ID (agentId字符串, 如 "gpt-4")
  @Index()
  late String agentId;

  /// 会话标题
  late String title;

  /// 是否为活跃会话
  @Index()
  late bool isActive;

  /// 消息总数
  late int messageCount;

  /// 创建时间
  @Index()
  late DateTime createdAt;

  /// 更新时间 (最后一条消息的时间)
  @Index()
  late DateTime updatedAt;

  /// 最后一条消息内容 (用于预览)
  String? lastMessageContent;

  /// 是否已固定
  late bool isPinned;

  /// 总Token使用量 (可选)
  int? totalTokens;

  /// 会话元数据 (JSON格式字符串)
  /// 例如: {"auto_generated_title": true}
  String? metadata;

  /// 构造函数
  Conversation({
    this.id = Isar.autoIncrement,
    required this.agentId,
    this.title = '新对话',
    this.isActive = true,
    this.messageCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageContent,
    this.isPinned = false,
    this.totalTokens,
    this.metadata,
  });

  /// 复制方法
  Conversation copyWith({
    Id? id,
    String? agentId,
    String? title,
    bool? isActive,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessageContent,
    bool? isPinned,
    int? totalTokens,
    String? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      isPinned: isPinned ?? this.isPinned,
      totalTokens: totalTokens ?? this.totalTokens,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 更新时间戳
  void touch() {
    updatedAt = DateTime.now();
  }

  /// 增加消息计数
  void incrementMessageCount() {
    messageCount++;
    touch();
  }

  /// 更新最后一条消息
  void updateLastMessage(String content) {
    lastMessageContent = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
    touch();
  }

  /// 设置标题
  void setTitle(String newTitle) {
    title = newTitle;
    touch();
  }

  /// 切换固定状态
  void togglePin() {
    isPinned = !isPinned;
    touch();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'title': title,
      'isActive': isActive,
      'messageCount': messageCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'isPinned': isPinned,
      'totalTokens': totalTokens,
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as Id? ?? Isar.autoIncrement,
      agentId: json['agentId'] as String,
      title: json['title'] as String? ?? '新对话',
      isActive: json['isActive'] as bool? ?? true,
      messageCount: json['messageCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      lastMessageContent: json['lastMessageContent'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      totalTokens: json['totalTokens'] as int?,
      metadata: json['metadata'] as String?,
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, title: $title, agentId: $agentId, messageCount: $messageCount, isActive: $isActive)';
  }
}

/// 会话构建器辅助类
class ConversationBuilder {
  /// 创建新会话
  static Conversation create({
    required String agentId,
    String? title,
  }) {
    final now = DateTime.now();
    return Conversation(
      agentId: agentId,
      title: title ?? _generateDefaultTitle(now),
      isActive: true,
      messageCount: 0,
      createdAt: now,
      updatedAt: now,
      isPinned: false,
    );
  }

  /// 生成默认标题
  static String _generateDefaultTitle(DateTime time) {
    final hour = time.hour;
    String timeOfDay;

    if (hour >= 5 && hour < 12) {
      timeOfDay = '早上';
    } else if (hour >= 12 && hour < 14) {
      timeOfDay = '中午';
    } else if (hour >= 14 && hour < 18) {
      timeOfDay = '下午';
    } else if (hour >= 18 && hour < 22) {
      timeOfDay = '晚上';
    } else {
      timeOfDay = '深夜';
    }

    return '$timeOfDay的对话';
  }

  /// 从首条消息生成标题
  static String generateTitleFromMessage(String message) {
    // 截取前30个字符作为标题
    if (message.length <= 30) {
      return message;
    }

    return '${message.substring(0, 30)}...';
  }
}

/// 会话排序选项
enum ConversationSortOrder {
  updatedAtDesc, // 更新时间降序 (最新的在前)
  updatedAtAsc, // 更新时间升序
  createdAtDesc, // 创建时间降序
  createdAtAsc, // 创建时间升序
  titleAsc, // 标题升序
  messageCountDesc, // 消息数量降序
}

extension ConversationSortOrderExtension on ConversationSortOrder {
  String get displayName {
    switch (this) {
      case ConversationSortOrder.updatedAtDesc:
        return '最近更新';
      case ConversationSortOrder.updatedAtAsc:
        return '最早更新';
      case ConversationSortOrder.createdAtDesc:
        return '最新创建';
      case ConversationSortOrder.createdAtAsc:
        return '最早创建';
      case ConversationSortOrder.titleAsc:
        return '标题A-Z';
      case ConversationSortOrder.messageCountDesc:
        return '消息最多';
    }
  }
}
