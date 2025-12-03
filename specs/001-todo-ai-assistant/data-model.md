# 数据模型：待办事项与AI智能助手

**功能**: 001-todo-ai-assistant
**日期**: 2025-11-27
**基于**: spec.md关键实体 + research.md技术决策（Isar数据库）

## 概述

本应用使用Isar作为本地数据库，所有实体使用Dart类配合Isar注解定义。数据存储在本地，通过WebSocket与后端实时同步。

## 实体清单

1. **Task** - 待办任务
2. **AIAgent** - AI智能体
3. **Message** - 对话消息
4. **Conversation** - 对话会话
5. **TaskAction** - 任务操作记录
6. **Badge** - 通知角标状态（内存中计算，不持久化）

---

## 1. Task（待办任务）

### 描述
代表用户需要完成的工作项，支持本地创建和云端推送两种来源。

### 字段定义

```dart
@collection
class Task {
  // 主键
  Id id = Isar.autoIncrement;

  // 基本信息
  late String title;                    // 任务标题，必填
  String? description;                  // 任务描述，可选

  // 分类与状态
  @enumerated
  late Priority priority;               // 优先级：low/medium/high
  late bool isCompleted;                // 完成状态

  // 时间戳
  @Index()
  late DateTime createdAt;              // 创建时间
  DateTime? dueDate;                    // 截止日期，可选
  DateTime? completedAt;                // 完成时间

  // 同步相关
  String? serverId;                     // 服务器端ID（云端同步的任务）
  @Index()
  late DateTime lastSyncedAt;           // 最后同步时间
  late bool isSynced;                   // 是否已同步到服务器
  late bool isDeleted;                  // 软删除标记

  // 来源标识
  @enumerated
  late TaskSource source;               // 来源：local/server/ai
  String? createdByAgentId;             // 如果由AI创建，记录智能体ID
}

enum Priority {
  low,      // 低优先级
  medium,   // 中优先级
  high,     // 高优先级
}

enum TaskSource {
  local,    // 本地创建
  server,   // 服务器推送
  ai,       // AI助手创建
}
```

### 验证规则

- `title`: 不能为空，不能只包含空格，长度1-200字符
- `description`: 可选，长度不超过2000字符
- `priority`: 必须是枚举值之一
- `dueDate`: 如果存在，不能早于`createdAt`
- `completedAt`: 只有当`isCompleted=true`时才能有值

### 索引策略

- `createdAt`: 支持按时间排序
- `lastSyncedAt`: 用于增量同步查询
- 复合索引 `(isCompleted, priority, dueDate)`: 支持任务列表筛选

### 关系

- **一对多**: Task -> TaskAction（一个任务可以有多个操作记录）

### 状态转换

```
[新建] --完成--> [已完成]
       --删除--> [已删除]

[已完成] --取消完成--> [新建]
         --删除--> [已删除]
```

### 查询示例

```dart
// 获取未完成的高优先级任务
final highPriorityTasks = await isar.tasks
  .filter()
  .isCompletedEqualTo(false)
  .priorityEqualTo(Priority.high)
  .sortByDueDateDesc()
  .findAll();

// 获取需要同步的任务
final unsyncedTasks = await isar.tasks
  .filter()
  .isSyncedEqualTo(false)
  .isDeletedEqualTo(false)
  .findAll();

// 获取今日到期任务
final today = DateTime.now();
final todayTasks = await isar.tasks
  .filter()
  .dueDateBetween(
    DateTime(today.year, today.month, today.day),
    DateTime(today.year, today.month, today.day, 23, 59, 59),
  )
  .findAll();
```

---

## 2. AIAgent（AI智能体）

### 描述
代表一个可用的AI助手配置，包括名称、描述、服务端点等信息。

### 字段定义

```dart
@collection
class AIAgent {
  // 主键
  Id id = Isar.autoIncrement;

  // 基本信息
  @Index(unique: true)
  late String agentId;                  // 唯一标识符（如"gpt-4", "claude-3"）
  late String name;                     // 显示名称
  late String description;              // 简短描述
  String? iconUrl;                      // 图标URL

  // 服务配置
  late String endpoint;                 // API端点
  String? apiKey;                       // API密钥（加密存储）
  late Map<String, dynamic> modelParams; // 模型参数（temperature等）

  // 状态
  late bool isEnabled;                  // 是否启用
  late bool isDefault;                  // 是否为默认智能体
  late int sortOrder;                   // 排序顺序

  // 统计
  late int messageCount;                // 总消息数
  late DateTime lastUsedAt;             // 最后使用时间
}
```

### 验证规则

- `agentId`: 唯一，不能为空，格式：小写字母+数字+连字符
- `name`: 不能为空，长度1-50字符
- `endpoint`: 必须是有效的URL
- `isDefault`: 最多只能有一个智能体标记为default

### 索引策略

- `agentId`: 唯一索引，用于快速查找特定智能体
- `sortOrder`: 用于界面排序

### 关系

- **一对多**: AIAgent -> Conversation（一个智能体可以有多个会话）
- **一对多**: AIAgent -> Message（一个智能体的所有消息）

### 预置数据

```dart
// 应用初始化时预置的AI智能体
final presetAgents = [
  AIAgent()
    ..agentId = 'gpt-4'
    ..name = 'GPT-4'
    ..description = '通用AI助手，适合各类对话'
    ..endpoint = 'https://api.openai.com/v1/chat/completions'
    ..isEnabled = true
    ..isDefault = true
    ..sortOrder = 1,

  AIAgent()
    ..agentId = 'claude-3'
    ..name = 'Claude 3'
    ..description = '擅长分析和创作的AI助手'
    ..endpoint = 'https://api.anthropic.com/v1/messages'
    ..isEnabled = true
    ..isDefault = false
    ..sortOrder = 2,
];
```

---

## 3. Message（对话消息）

### 描述
代表AI对话中的单条消息，包含用户发送的消息和AI的回复。

### 字段定义

```dart
@collection
class Message {
  // 主键
  Id id = Isar.autoIncrement;

  // 关联信息
  @Index()
  late String conversationId;           // 所属会话ID

  @Index()
  late String agentId;                  // 关联的智能体ID

  // 消息内容
  late String content;                  // 消息文本

  @enumerated
  late MessageRole role;                // 角色：user/assistant/system

  // 时间戳
  @Index()
  late DateTime timestamp;              // 发送时间

  // 状态
  late bool isRead;                     // 是否已读

  @enumerated
  late MessageStatus status;            // 状态：pending/sent/delivered/error

  String? errorMessage;                 // 错误信息（如果status=error）

  // 元数据
  Map<String, dynamic>? metadata;       // 额外元数据（如token使用量）
}

enum MessageRole {
  user,       // 用户消息
  assistant,  // AI回复
  system,     // 系统消息
}

enum MessageStatus {
  pending,    // 等待发送
  sent,       // 已发送
  delivered,  // 已送达
  error,      // 发送失败
}
```

### 验证规则

- `content`: 不能为空
- `conversationId`: 必须对应有效的Conversation
- `agentId`: 必须对应有效的AIAgent
- `timestamp`: 不能是未来时间

### 索引策略

- `conversationId`: 用于查询特定会话的所有消息
- `agentId`: 用于查询特定智能体的所有消息
- `timestamp`: 用于按时间排序
- 复合索引 `(conversationId, timestamp)`: 优化会话消息查询

### 关系

- **多对一**: Message -> Conversation
- **多对一**: Message -> AIAgent

### 查询示例

```dart
// 获取某个会话的所有消息
final messages = await isar.messages
  .filter()
  .conversationIdEqualTo(conversationId)
  .sortByTimestamp()
  .findAll();

// 获取未读消息数量
final unreadCount = await isar.messages
  .filter()
  .isReadEqualTo(false)
  .roleEqualTo(MessageRole.assistant)
  .count();

// 获取最近7天的消息
final weekAgo = DateTime.now().subtract(Duration(days: 7));
final recentMessages = await isar.messages
  .filter()
  .timestampGreaterThan(weekAgo)
  .findAll();
```

---

## 4. Conversation（对话会话）

### 描述
代表与特定智能体的一次完整对话交互，可以理解为一个对话线程。

### 字段定义

```dart
@collection
class Conversation {
  // 主键
  Id id = Isar.autoIncrement;

  // 关联信息
  @Index()
  late String agentId;                  // 关联的智能体ID

  // 基本信息
  late String title;                    // 会话标题（自动生成或用户编辑）

  // 时间戳
  @Index()
  late DateTime createdAt;              // 创建时间

  @Index()
  late DateTime lastUpdatedAt;          // 最后更新时间

  // 统计
  late int messageCount;                // 消息数量

  // 状态
  late bool isActive;                   // 是否活跃（用于清理旧会话）
  late bool isPinned;                   // 是否置顶
}
```

### 验证规则

- `agentId`: 必须对应有效的AIAgent
- `title`: 不能为空，长度1-100字符
- `lastUpdatedAt`: 不能早于`createdAt`

### 索引策略

- `agentId`: 用于查询特定智能体的所有会话
- `createdAt` 和 `lastUpdatedAt`: 用于按时间排序

### 关系

- **一对多**: Conversation -> Message（一个会话包含多条消息）
- **多对一**: Conversation -> AIAgent

### 自动标题生成

```dart
// 根据第一条用户消息自动生成标题
Future<void> generateTitle(Conversation conversation) async {
  final firstMessage = await isar.messages
    .filter()
    .conversationIdEqualTo(conversation.id.toString())
    .roleEqualTo(MessageRole.user)
    .sortByTimestamp()
    .findFirst();

  if (firstMessage != null) {
    // 取前30个字符作为标题
    conversation.title = firstMessage.content.substring(
      0,
      min(30, firstMessage.content.length),
    ) + (firstMessage.content.length > 30 ? '...' : '');
  }
}
```

### 查询示例

```dart
// 获取某个智能体的所有会话
final conversations = await isar.conversations
  .filter()
  .agentIdEqualTo(agentId)
  .sortByLastUpdatedAtDesc()
  .findAll();

// 获取置顶会话
final pinnedConversations = await isar.conversations
  .filter()
  .isPinnedEqualTo(true)
  .sortByLastUpdatedAtDesc()
  .findAll();
```

---

## 5. TaskAction（任务操作记录）

### 描述
代表AI执行的任务相关操作，用于审计和撤销功能。

### 字段定义

```dart
@collection
class TaskAction {
  // 主键
  Id id = Isar.autoIncrement;

  // 关联信息
  @Index()
  late int taskId;                      // 关联的任务ID（Isar ID）
  String? agentId;                      // 执行操作的智能体ID（如果是AI操作）

  // 操作信息
  @enumerated
  late ActionType actionType;           // 操作类型

  late Map<String, dynamic> beforeState; // 操作前状态
  late Map<String, dynamic> afterState;  // 操作后状态

  // 时间戳
  @Index()
  late DateTime timestamp;              // 操作时间

  // 用户确认
  late bool isConfirmed;                // 用户是否确认（AI操作需要确认）
  DateTime? confirmedAt;                // 确认时间
}

enum ActionType {
  create,     // 创建任务
  update,     // 更新任务
  complete,   // 完成任务
  reopen,     // 重新打开任务
  delete,     // 删除任务
}
```

### 验证规则

- `taskId`: 必须对应有效的Task
- `actionType`: 必须是枚举值之一
- `confirmedAt`: 只有当`isConfirmed=true`时才能有值

### 索引策略

- `taskId`: 用于查询特定任务的所有操作记录
- `timestamp`: 用于按时间排序

### 关系

- **多对一**: TaskAction -> Task

### 撤销功能

```dart
// 撤销任务操作
Future<void> undoTaskAction(TaskAction action) async {
  final task = await isar.tasks.get(action.taskId);
  if (task == null) return;

  // 恢复到操作前的状态
  task.title = action.beforeState['title'];
  task.priority = Priority.values[action.beforeState['priority']];
  task.isCompleted = action.beforeState['isCompleted'];
  // ... 恢复其他字段

  await isar.writeTxn(() => isar.tasks.put(task));
}
```

---

## 6. Badge（通知角标状态）

### 描述
通知角标不作为独立实体持久化，而是通过查询实时计算。

### 计算逻辑

```dart
// Badge计算服务
class BadgeService {
  final Isar isar;

  BadgeService(this.isar);

  // 计算未读消息数量
  Future<int> getUnreadMessageCount() async {
    return await isar.messages
      .filter()
      .isReadEqualTo(false)
      .roleEqualTo(MessageRole.assistant)
      .count();
  }

  // 计算未读任务更新数量
  Future<int> getUnreadTaskUpdateCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenTimestamp = prefs.getInt('lastSeenTaskTimestamp') ?? 0;
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp);

    return await isar.tasks
      .filter()
      .createdAtGreaterThan(lastSeen)
      .count();
  }

  // 计算总角标数字
  Future<int> getTotalBadgeCount() async {
    final messageCount = await getUnreadMessageCount();
    final taskCount = await getUnreadTaskUpdateCount();
    return messageCount + taskCount;
  }

  // 清除消息未读状态
  Future<void> markMessagesAsRead(List<int> messageIds) async {
    await isar.writeTxn(() async {
      for (final id in messageIds) {
        final message = await isar.messages.get(id);
        if (message != null) {
          message.isRead = true;
          await isar.messages.put(message);
        }
      }
    });
  }

  // 更新任务查看时间戳
  Future<void> updateLastSeenTaskTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'lastSeenTaskTimestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
```

---

## 数据迁移策略

### Schema版本控制

```dart
// 版本1：初始Schema
const int schemaVersion = 1;

Future<Isar> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();

  return await Isar.open(
    [
      TaskSchema,
      AIAgentSchema,
      MessageSchema,
      ConversationSchema,
      TaskActionSchema,
    ],
    directory: dir.path,
    inspector: kDebugMode,
  );
}
```

### 未来迁移示例

```dart
// 当Schema变更时，版本递增
const int schemaVersion = 2;

Future<void> migrateToV2(Isar isar) async {
  // 示例：为Task添加新字段tags
  final tasks = await isar.tasks.where().findAll();

  await isar.writeTxn(() async {
    for (final task in tasks) {
      // task.tags = []; // 新字段默认值
      await isar.tasks.put(task);
    }
  });
}
```

---

## 数据同步设计

### 同步时间戳策略

每个实体维护`lastSyncedAt`字段，用于增量同步：

```dart
// 获取需要上传到服务器的更改
Future<List<Task>> getTasksToSync() async {
  return await isar.tasks
    .filter()
    .isSyncedEqualTo(false)
    .isDeletedEqualTo(false)
    .findAll();
}

// 标记任务已同步
Future<void> markTaskAsSynced(int taskId, String serverId) async {
  await isar.writeTxn(() async {
    final task = await isar.tasks.get(taskId);
    if (task != null) {
      task.isSynced = true;
      task.serverId = serverId;
      task.lastSyncedAt = DateTime.now();
      await isar.tasks.put(task);
    }
  });
}
```

### 冲突解决

```dart
// 简单的最后写入胜出策略
Future<void> resolveConflict(Task localTask, Task serverTask) async {
  if (serverTask.lastSyncedAt.isAfter(localTask.lastSyncedAt)) {
    // 服务器版本更新，使用服务器数据
    await isar.writeTxn(() => isar.tasks.put(serverTask));
  } else {
    // 本地版本更新，保持本地数据，标记需要同步
    localTask.isSynced = false;
    await isar.writeTxn(() => isar.tasks.put(localTask));
  }
}
```

---

## 性能优化建议

1. **批量操作**：使用事务批量写入，避免逐条操作
2. **懒加载**：对话历史使用分页加载，初始只加载最近50条消息
3. **索引优化**：为常用查询字段添加索引，但避免过度索引
4. **清理策略**：定期清理30天以上的非活跃会话
5. **缓存策略**：在内存中缓存常用数据（如智能体列表）

---

## 总结

本数据模型设计：
- **6个核心实体**：Task, AIAgent, Message, Conversation, TaskAction, Badge
- **使用Isar数据库**：高性能、强查询能力、跨平台支持
- **支持离线优先**：本地完整功能，在线实时同步
- **关系清晰**：实体间关系明确，便于查询和维护
- **扩展性良好**：预留字段和元数据支持未来扩展
