import 'package:isar/isar.dart';

part 'ai_agent.g.dart';

/// AI智能体实体模型
@Collection()
class AIAgent {
  /// 智能体ID (自动生成)
  Id id = Isar.autoIncrement;

  /// 智能体唯一标识符 (例如: gpt-4, claude-3)
  @Index(unique: true)
  late String agentId;

  /// 智能体名称
  late String name;

  /// 智能体描述
  String? description;

  /// API端点URL
  late String endpoint;

  /// 是否启用
  late bool isEnabled;

  /// 是否为默认智能体
  late bool isDefault;

  /// 排序顺序
  late int sortOrder;

  /// 消息总数
  late int messageCount;

  /// 最后使用时间
  late DateTime lastUsedAt;

  /// 模型参数 (JSON格式字符串)
  /// 例如: {"model": "gpt-4", "temperature": 0.7, "max_tokens": 2000}
  String? modelParams;

  /// 模型名称 (例如: gpt-4, claude-3-opus-20240229)
  String? modelName;

  /// API密钥 (可选,如果为空则从环境变量读取)
  String? apiKey;

  /// 头像URL (可选)
  String? avatar;

  /// 是否为预设智能体
  late bool isPreset;

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  late DateTime updatedAt;

  /// 构造函数
  AIAgent({
    this.id = Isar.autoIncrement,
    required this.agentId,
    required this.name,
    this.description,
    required this.endpoint,
    this.isEnabled = true,
    this.isDefault = false,
    this.sortOrder = 0,
    this.messageCount = 0,
    required this.lastUsedAt,
    this.modelParams,
    this.modelName,
    this.apiKey,
    this.avatar,
    this.isPreset = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 复制方法
  AIAgent copyWith({
    Id? id,
    String? agentId,
    String? name,
    String? description,
    String? endpoint,
    bool? isEnabled,
    bool? isDefault,
    int? sortOrder,
    int? messageCount,
    DateTime? lastUsedAt,
    String? modelParams,
    String? modelName,
    String? apiKey,
    String? avatar,
    bool? isPreset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIAgent(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      name: name ?? this.name,
      description: description ?? this.description,
      endpoint: endpoint ?? this.endpoint,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      messageCount: messageCount ?? this.messageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      modelParams: modelParams ?? this.modelParams,
      modelName: modelName ?? this.modelName,
      apiKey: apiKey ?? this.apiKey,
      avatar: avatar ?? this.avatar,
      isPreset: isPreset ?? this.isPreset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 更新时间戳
  void touch() {
    updatedAt = DateTime.now();
  }

  /// 增加消息计数
  void incrementMessageCount() {
    messageCount++;
    lastUsedAt = DateTime.now();
    touch();
  }

  /// 更新最后使用时间
  void updateLastUsedAt() {
    lastUsedAt = DateTime.now();
    touch();
  }

  /// 获取API端点（endpoint别名，用于兼容）
  String get apiEndpoint => endpoint;

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'name': name,
      'description': description,
      'endpoint': endpoint,
      'isEnabled': isEnabled,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'messageCount': messageCount,
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'modelParams': modelParams,
      'modelName': modelName,
      'apiKey': apiKey,
      'avatar': avatar,
      'isPreset': isPreset,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory AIAgent.fromJson(Map<String, dynamic> json) {
    return AIAgent(
      id: json['id'] as Id? ?? Isar.autoIncrement,
      agentId: json['agentId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      endpoint: json['endpoint'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : DateTime.now(),
      modelParams: json['modelParams'] as String?,
      modelName: json['modelName'] as String?,
      apiKey: json['apiKey'] as String?,
      avatar: json['avatar'] as String?,
      isPreset: json['isPreset'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AIAgent(id: $id, agentId: $agentId, name: $name, isEnabled: $isEnabled, messageCount: $messageCount)';
  }
}

/// 预定义的AI智能体配置
class AIAgentPresets {
  /// GPT-4 智能体
  static AIAgent gpt4() {
    final now = DateTime.now();
    return AIAgent(
      agentId: 'gpt-4',
      name: 'GPT-4',
      description: '通用AI助手，适合各类对话和任务处理',
      endpoint: 'https://api.openai.com/v1/chat/completions',
      isEnabled: true,
      isDefault: true,
      sortOrder: 1,
      lastUsedAt: now,
      modelParams: '{"model":"gpt-4","temperature":0.7,"max_tokens":2000}',
      modelName: 'gpt-4',
      isPreset: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// GPT-3.5 Turbo 智能体
  static AIAgent gpt35Turbo() {
    final now = DateTime.now();
    return AIAgent(
      agentId: 'gpt-3.5-turbo',
      name: 'GPT-3.5 Turbo',
      description: '快速响应的AI助手，适合日常对话',
      endpoint: 'https://api.openai.com/v1/chat/completions',
      isEnabled: true,
      isDefault: false,
      sortOrder: 2,
      lastUsedAt: now,
      modelParams: '{"model":"gpt-3.5-turbo","temperature":0.7,"max_tokens":2000}',
      modelName: 'gpt-3.5-turbo',
      isPreset: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Claude 3 Opus 智能体
  static AIAgent claude3Opus() {
    final now = DateTime.now();
    return AIAgent(
      agentId: 'claude-3-opus',
      name: 'Claude 3 Opus',
      description: '擅长分析和创作的AI助手',
      endpoint: 'https://api.anthropic.com/v1/messages',
      isEnabled: true,
      isDefault: false,
      sortOrder: 3,
      lastUsedAt: now,
      modelParams: '{"model":"claude-3-opus-20240229","temperature":0.7,"max_tokens":2000}',
      modelName: 'claude-3-opus-20240229',
      isPreset: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Claude 3 Sonnet 智能体
  static AIAgent claude3Sonnet() {
    final now = DateTime.now();
    return AIAgent(
      agentId: 'claude-3-sonnet',
      name: 'Claude 3 Sonnet',
      description: '平衡性能和成本的AI助手',
      endpoint: 'https://api.anthropic.com/v1/messages',
      isEnabled: true,
      isDefault: false,
      sortOrder: 4,
      lastUsedAt: now,
      modelParams: '{"model":"claude-3-sonnet-20240229","temperature":0.7,"max_tokens":2000}',
      modelName: 'claude-3-sonnet-20240229',
      isPreset: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 获取所有预设智能体
  static List<AIAgent> getAllPresets() {
    return [
      gpt4(),
      gpt35Turbo(),
      claude3Opus(),
      claude3Sonnet(),
    ];
  }
}
