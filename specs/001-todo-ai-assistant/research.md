# 技术研究：待办事项与AI智能助手

**功能**: 001-todo-ai-assistant
**日期**: 2025-11-27
**目的**: 解决技术上下文中的未明确技术选型，为实施提供决策依据

## 研究概述

本研究针对Flutter桌面应用的两个关键技术决策：
1. 本地数据持久化方案（Hive vs Isar）
2. 状态管理方案（Riverpod vs Bloc）

## 1. 本地数据持久化：Isar

### 决策

**选择 Isar 作为本地数据持久化方案**

### 理由

1. **卓越的性能表现**
   - 写入速度约300ms（Hive 800ms），读取约200ms（Hive 500ms）
   - 大型索引数据集和跨多字段过滤查询性能优异
   - 被评为同类最佳，特别适合大规模、离线优先的应用

2. **强大的查询能力**
   - 专为大型索引数据集和复杂查询设计
   - 支持多字段过滤、索引查询、全文搜索
   - 非常适合AI对话历史检索和待办任务筛选场景

3. **完整的桌面平台支持**
   - 原生支持macOS和Windows
   - 为isolates和并发设计，适合桌面应用的多线程需求
   - 支持移动端、桌面端和Web端（未来扩展性）

4. **项目维护和未来发展**
   - Isar是Hive创建者开发的新一代数据库，旨在替代Hive
   - 创建者明确推荐使用Isar而非Hive
   - Hive现在实际上是Isar的轻量级包装器

5. **适合的使用场景**
   - **待办任务**: 支持复杂筛选（按优先级、截止日期、状态）、排序、标签查询
   - **AI对话历史**: 存储大量会话数据，支持按智能体、时间范围快速检索
   - **未读角标**: 实时统计未读消息和任务数量

### 考虑的替代方案：Hive

**优点**:
- 简单键值读写极快，设置更简单
- 学习曲线低，API直观
- 小型数据集和直接键值访问性能卓越

**缺点**:
- 查询能力有限，不适合复杂数据关系
- 大型数据集性能不如Isar
- 项目维护前景不明朗（已被Isar取代）
- 不支持复杂索引和关系查询

**结论**: 仅当数据访问模式非常简单（纯键值存储）且数据量小时才考虑Hive

### 最佳实践

1. **合理使用索引**
   ```dart
   @collection
   class Task {
     Id id = Isar.autoIncrement;

     @Index()
     late DateTime createdAt;

     @Index()
     late DateTime? dueDate;

     @Index()
     late int priority; // 0=低, 1=中, 2=高

     @Index()
     late bool isCompleted;

     late String title;
     late String? description;
   }

   @collection
   class Message {
     Id id = Isar.autoIncrement;

     @Index()
     late DateTime timestamp;

     @Index()
     late String conversationId;

     @Index()
     late String agentId;

     late String content;
     late bool isRead;
   }
   ```
   - 为常用查询字段添加索引（时间戳、会话ID、智能体ID）
   - 避免过度索引影响写入性能

2. **Schema迁移和调试**
   ```dart
   final isar = await Isar.open(
     [TaskSchema, MessageSchema, ConversationSchema, AIAgentSchema],
     directory: appDataDir,
     inspector: kDebugMode, // 开发时启用Inspector
   );
   ```
   - 使用Isar的Schema版本控制管理数据迁移
   - 开发阶段启用Inspector工具（浏览器调试界面）

3. **批量操作优化性能**
   ```dart
   // 批量插入任务
   await isar.writeTxn(() async {
     await isar.tasks.putAll(newTasks);
   });

   // 批量保存AI对话消息
   await isar.writeTxn(() async {
     final conversation = await isar.conversations.get(conversationId);
     await isar.messages.putAll(messages);
     conversation.lastUpdated = DateTime.now();
     await isar.conversations.put(conversation);
   });
   ```
   - 使用事务批量写入，而非逐条插入
   - WebSocket推送的多条消息批量保存

## 2. 状态管理：Riverpod 3

### 决策

**选择 Riverpod 3 作为状态管理方案**

### 理由

1. **现代化架构和低样板代码**
   - Riverpod 3的`@riverpod`宏大幅减少样板代码
   - 比Bloc少60-70%的代码量，提高开发效率
   - 清晰、可组合、无样板的状态管理方式

2. **优异的性能和编译时安全**
   - 被评为性能最佳的状态管理方案
   - 细粒度重建机制，只更新必要的组件
   - 编译时类型安全，减少运行时错误

3. **完美适配WebSocket和实时数据**
   - 原生支持`StreamProvider`，轻松管理WebSocket连接
   - 自动处理连接的创建和销毁
   - 支持自动重连和错误恢复机制
   ```dart
   @riverpod
   Stream<dynamic> taskWebSocket(TaskWebSocketRef ref) async* {
     final channel = WebSocketChannel.connect(
       Uri.parse('ws://api.example.com/tasks'),
     );
     ref.onDispose(() => channel.sink.close());
     yield* channel.stream;
   }
   ```

4. **无需BuildContext，全局状态管理**
   - 消除BuildContext依赖，避免常见的Context误用问题
   - 支持全局状态管理，非常适合桌面应用的多窗口场景
   - 小窗口模式和完整窗口模式可以共享同一状态

5. **测试友好性**
   - Provider可以轻松覆盖（override），便于单元测试和集成测试
   - 不需要mock复杂的依赖注入
   - 支持自动化测试工具（flutter_test）

### 考虑的替代方案：Bloc

**优点**:
- 严格的业务逻辑与UI分离，架构清晰
- 事件驱动模式，便于追踪状态变化
- 强大的社区生态（hydrated_bloc、bloc_concurrency等）
- 适合大型团队和企业级应用，强制统一的代码风格

**缺点**:
- 需要创建大量的Event和State类，样板代码多
- 学习曲线较陡，新手上手慢
- 对于小型UI或快速原型开发，Bloc显得过于繁重
- 处理简单状态时，Bloc的架构显得过度设计

**结论**: Bloc更适合大型企业应用和严格的架构规范需求。对于本项目（4个用户故事、个人/小团队使用），Riverpod更合适。

### 最佳实践

1. **使用代码生成简化开发**
   ```dart
   // 任务列表Provider
   @riverpod
   class TaskList extends _$TaskList {
     @override
     Future<List<Task>> build() async {
       final isar = ref.watch(isarInstanceProvider);
       return await isar.tasks.where().sortByCreatedAtDesc().findAll();
     }

     Future<void> addTask(Task task) async {
       final isar = ref.read(isarInstanceProvider);
       await isar.writeTxn(() => isar.tasks.put(task));
       ref.invalidateSelf();
     }

     Future<void> updateTask(Task task) async {
       final isar = ref.read(isarInstanceProvider);
       await isar.writeTxn(() => isar.tasks.put(task));
       ref.invalidateSelf();
     }
   }
   ```
   - 利用`riverpod_generator`自动生成Provider代码
   - 使用`ref.invalidateSelf()`刷新状态

2. **按功能模块组织Provider**
   ```dart
   lib/
     ├── features/
     │   ├── tasks/
     │   │   ├── providers/
     │   │   │   ├── task_list_provider.dart
     │   │   │   └── task_websocket_provider.dart
     │   │   ├── models/
     │   │   └── widgets/
     │   ├── chat/
     │   │   ├── providers/
     │   │   │   ├── conversation_provider.dart
     │   │   │   ├── agent_selector_provider.dart
     │   │   │   └── chat_websocket_provider.dart
     │   │   ├── models/
     │   │   └── widgets/
     │   └── window/
     │       ├── providers/
     │       │   ├── window_state_provider.dart
     │       │   └── badge_provider.dart
     │       └── widgets/
   ```
   - 按功能模块划分Provider
   - 每个模块独立管理自己的状态

3. **WebSocket连接的生命周期管理**
   ```dart
   @riverpod
   class TaskWebSocketService extends _$TaskWebSocketService {
     WebSocketChannel? _channel;
     Timer? _reconnectTimer;
     int _reconnectAttempts = 0;

     @override
     Stream<dynamic> build() {
       _connect();

       ref.onDispose(() {
         _reconnectTimer?.cancel();
         _channel?.sink.close();
       });

       return _channel!.stream.handleError((error) {
         _scheduleReconnect();
       });
     }

     void _connect() {
       _channel = WebSocketChannel.connect(
         Uri.parse('ws://api.example.com/tasks'),
       );
       _reconnectAttempts = 0;
     }

     void _scheduleReconnect() {
       if (_reconnectAttempts >= 5) return; // 最多重试5次

       final delay = Duration(seconds: math.pow(2, _reconnectAttempts).toInt());
       _reconnectTimer = Timer(delay, () {
         _reconnectAttempts++;
         _connect();
         ref.invalidateSelf();
       });
     }

     void send(Map<String, dynamic> data) {
       _channel?.sink.add(jsonEncode(data));
     }
   }
   ```
   - 使用`ref.onDispose`确保资源正确释放
   - 实现指数退避的自动重连机制
   - 将WebSocket逻辑封装在服务类中

4. **未读角标实时更新**
   ```dart
   @riverpod
   class BadgeCount extends _$BadgeCount {
     @override
     int build() {
       final unreadMessages = ref.watch(unreadMessageCountProvider);
       final unreadTasks = ref.watch(unreadTaskUpdateCountProvider);
       return unreadMessages + unreadTasks;
     }
   }

   @riverpod
   Future<int> unreadMessageCount(UnreadMessageCountRef ref) async {
     final isar = ref.watch(isarInstanceProvider);
     return await isar.messages.filter().isReadEqualTo(false).count();
   }

   @riverpod
   Future<int> unreadTaskUpdateCount(UnreadTaskUpdateCountRef ref) async {
     final isar = ref.watch(isarInstanceProvider);
     final lastSeen = ref.watch(lastSeenTaskTimestampProvider);
     return await isar.tasks
       .filter()
       .createdAtGreaterThan(lastSeen)
       .count();
   }
   ```
   - 组合多个Provider计算总未读数
   - 细粒度更新，只在相关数据变化时重建

## 实施建议

### 依赖配置（pubspec.yaml）

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 状态管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # 数据持久化
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.0

  # WebSocket
  web_socket_channel: ^2.4.0

  # 桌面窗口管理
  window_manager: ^0.3.7

  # 系统通知
  flutter_local_notifications: ^16.3.0

  # HTTP客户端（AI服务）
  dio: ^5.4.0

  # 工具
  shared_preferences: ^2.2.2
  uuid: ^4.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

  # 代码生成
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  isar_generator: ^3.1.0
```

### 初始化顺序

1. **初始化Isar数据库**
   ```dart
   Future<Isar> initializeIsar() async {
     final dir = await getApplicationDocumentsDirectory();
     return await Isar.open(
       [TaskSchema, MessageSchema, ConversationSchema, AIAgentSchema],
       directory: dir.path,
       inspector: kDebugMode,
     );
   }
   ```

2. **初始化Riverpod ProviderScope**
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     final isar = await initializeIsar();

     runApp(
       ProviderScope(
         overrides: [
           isarInstanceProvider.overrideWithValue(isar),
         ],
         child: MyApp(),
       ),
     );
   }
   ```

3. **初始化window_manager**
   ```dart
   Future<void> initializeWindow() async {
     await windowManager.ensureInitialized();

     WindowOptions windowOptions = WindowOptions(
       size: Size(1200, 800),
       center: true,
       backgroundColor: Colors.transparent,
       skipTaskbar: false,
       titleBarStyle: TitleBarStyle.normal,
     );

     windowManager.waitUntilReadyToShow(windowOptions, () async {
       await windowManager.show();
       await windowManager.focus();
     });
   }
   ```

## 性能优化建议

1. **Isar查询优化**
   - 为频繁查询的字段添加索引
   - 使用`.limit()`限制返回数量
   - 使用`.watch()`实时监听数据变化，而非轮询

2. **Riverpod缓存策略**
   - 使用`keepAlive()`保持Provider活跃，避免频繁重建
   - 对于昂贵的计算，使用`family` modifier缓存结果

3. **WebSocket优化**
   - 实现心跳机制检测连接状态
   - 批量处理推送消息，避免频繁UI更新
   - 使用节流（throttle）限制更新频率

## 总结

**技术栈决策**:
- **数据持久化**: Isar - 性能优异，查询强大，适合复杂数据关系
- **状态管理**: Riverpod 3 - 低样板代码，WebSocket友好，测试性好

**优势**:
- 出色的性能表现
- 较低的学习曲线
- 更少的样板代码
- 优秀的开发体验
- 面向未来的技术选择

**风险与缓解**:
| 风险 | 缓解措施 |
|------|---------|
| Isar学习曲线 | 参考官方文档和示例，先从简单场景开始 |
| WebSocket断线 | 实现指数退避重连和离线队列机制 |
| 桌面平台差异 | 早期在两个平台并行测试，隔离平台特定代码 |

---

**参考资料**:
- [Isar文档](https://isar.dev/)
- [Riverpod文档](https://riverpod.dev/)
- [window_manager插件](https://pub.dev/packages/window_manager)
- [Flutter桌面最佳实践](https://docs.flutter.dev/desktop)
