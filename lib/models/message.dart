import 'package:isar/isar.dart';

part 'message.g.dart';

/// 消息角色枚举
enum MessageRole {
  user,       // 用户消息 - 0
  assistant,  // AI助手消息 - 1
  system,     // 系统消息 - 2
}

/// 消息状态枚举
enum MessageStatus {
  sending,    // 发送中 - 0
  sent,       // 已发送 - 1
  delivered,  // 已送达 - 2
  failed,     // 发送失败 - 3
  streaming,  // 流式传输中 - 4
}

/// 消息实体模型
@Collection()
class Message {
  /// 消息ID (自动生成)
  Id id = Isar.autoIncrement;

  /// 关联的会话ID
  @Index()
  late int conversationId;

  /// 关联的智能体ID (agentId字符串, 如 "gpt-4")
  @Index()
  late String agentId;

  /// 消息角色
  @Enumerated(EnumType.ordinal)
  @Index()
  late MessageRole role;

  /// 消息内容
  late String content;

  /// 消息状态
  @Enumerated(EnumType.ordinal)
  late MessageStatus status;

  /// 创建时间
  @Index()
  late DateTime createdAt;

  /// 更新时间
  late DateTime updatedAt;

  /// 错误信息 (如果发送失败)
  String? error;

  /// Token使用量 (可选)
  int? tokenCount;

  /// 消息元数据 (JSON格式字符串)
  /// 例如: {"model": "gpt-4", "finish_reason": "stop"}
  String? metadata;

  /// 构造函数
  Message({
    this.id = Isar.autoIncrement,
    required this.conversationId,
    required this.agentId,
    required this.role,
    required this.content,
    this.status = MessageStatus.sending,
    required this.createdAt,
    required this.updatedAt,
    this.error,
    this.tokenCount,
    this.metadata,
  });

  /// 复制方法
  Message copyWith({
    Id? id,
    int? conversationId,
    String? agentId,
    MessageRole? role,
    String? content,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? error,
    int? tokenCount,
    String? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      agentId: agentId ?? this.agentId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      error: error ?? this.error,
      tokenCount: tokenCount ?? this.tokenCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 更新时间戳
  void touch() {
    updatedAt = DateTime.now();
  }

  /// 标记为发送成功
  void markAsSent() {
    status = MessageStatus.sent;
    touch();
  }

  /// 标记为发送失败
  void markAsFailed(String errorMessage) {
    status = MessageStatus.failed;
    error = errorMessage;
    touch();
  }

  /// 标记为流式传输中
  void markAsStreaming() {
    status = MessageStatus.streaming;
    touch();
  }

  /// 追加内容 (用于流式响应)
  void appendContent(String chunk) {
    content += chunk;
    touch();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'agentId': agentId,
      'role': role.index,
      'content': content,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'error': error,
      'tokenCount': tokenCount,
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as Id? ?? Isar.autoIncrement,
      conversationId: json['conversationId'] as int,
      agentId: json['agentId'] as String,
      role: MessageRole.values[json['role'] as int],
      content: json['content'] as String,
      status: MessageStatus.values[json['status'] as int? ?? 0],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      error: json['error'] as String?,
      tokenCount: json['tokenCount'] as int?,
      metadata: json['metadata'] as String?,
    );
  }

  /// 转换为AI API格式 (通用格式)
  Map<String, dynamic> toAPIFormat() {
    return {
      'role': role.name,
      'content': content,
    };
  }

  @override
  String toString() {
    return 'Message(id: $id, role: $role, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}..., status: $status)';
  }
}

/// 消息角色扩展方法
extension MessageRoleExtension on MessageRole {
  /// 获取角色的显示名称
  String get displayName {
    switch (this) {
      case MessageRole.user:
        return '用户';
      case MessageRole.assistant:
        return 'AI助手';
      case MessageRole.system:
        return '系统';
    }
  }

  /// 获取角色的图标
  String get iconName {
    switch (this) {
      case MessageRole.user:
        return 'person';
      case MessageRole.assistant:
        return 'smart_toy';
      case MessageRole.system:
        return 'settings';
    }
  }
}

/// 消息状态扩展方法
extension MessageStatusExtension on MessageStatus {
  /// 获取状态的显示名称
  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return '发送中';
      case MessageStatus.sent:
        return '已发送';
      case MessageStatus.delivered:
        return '已送达';
      case MessageStatus.failed:
        return '发送失败';
      case MessageStatus.streaming:
        return '接收中';
    }
  }

  /// 是否为最终状态
  bool get isFinal {
    return this == MessageStatus.sent ||
        this == MessageStatus.delivered ||
        this == MessageStatus.failed;
  }

  /// 是否为错误状态
  bool get isError {
    return this == MessageStatus.failed;
  }
}

/// 消息构建器辅助类
class MessageBuilder {
  /// 创建用户消息
  static Message createUserMessage({
    required int conversationId,
    required String agentId,
    required String content,
  }) {
    final now = DateTime.now();
    return Message(
      conversationId: conversationId,
      agentId: agentId,
      role: MessageRole.user,
      content: content,
      status: MessageStatus.sent,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 创建助手消息
  static Message createAssistantMessage({
    required int conversationId,
    required String agentId,
    String content = '',
  }) {
    final now = DateTime.now();
    return Message(
      conversationId: conversationId,
      agentId: agentId,
      role: MessageRole.assistant,
      content: content,
      status: MessageStatus.streaming,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 创建系统消息
  static Message createSystemMessage({
    required int conversationId,
    required String agentId,
    required String content,
  }) {
    final now = DateTime.now();
    return Message(
      conversationId: conversationId,
      agentId: agentId,
      role: MessageRole.system,
      content: content,
      status: MessageStatus.sent,
      createdAt: now,
      updatedAt: now,
    );
  }
}
