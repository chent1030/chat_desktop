# 智能体API集成指南

## 快速开始

### 1. 配置环境变量

在项目根目录创建`.env`文件：

```bash
# 后端API地址（必需）
API_BASE_URL=http://localhost:3000

# API认证Token（可选，如果后端需要认证）
API_TOKEN=your_token_here
```

### 2. 初始化智能体服务

在应用启动时调用：

```dart
import 'package:chat_desktop/services/ai_agent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存储服务
  await StorageService.instance.initialize();

  // 初始化智能体（从后端获取并连接SSE）
  await AIAgentService.instance.initializeAgents();

  runApp(MyApp());
}
```

### 3. 使用智能体

```dart
// 在Provider中获取智能体列表
final agentListState = ref.watch(agentListProvider);

// 选择智能体
await ref.read(agentListProvider.notifier).selectAgent('gpt-4');

// 获取当前选中的智能体
final selectedAgent = ref.watch(selectedAgentProvider);
```

## 核心特性

### ✅ 支持的操作

- 📥 **获取智能体列表** - 从后端获取可用的AI智能体
- 🎯 **选择智能体** - 选择要使用的智能体
- 📊 **使用统计** - 自动记录智能体使用次数
- 📡 **实时同步** - 通过SSE自动同步后端变更
- 💾 **离线缓存** - 网络失败时使用本地缓存

### ❌ 不支持的操作

- ⛔ 创建智能体
- ⛔ 修改智能体配置
- ⛔ 删除智能体
- ⛔ 启用/禁用智能体

**所有智能体管理操作由后端控制。**

## 架构说明

```
┌──────────────┐
│  UI Layer    │ ← 用户界面（AgentSelector等）
├──────────────┤
│ Provider     │ ← 状态管理（AgentProvider）
├──────────────┤
│ Cache Layer  │ ← 智能体缓存（AIAgentService）
│              │   • 优先API获取
│              │   • 失败用缓存
│              │   • SSE实时同步
├──────────────┤
│  API Layer   │ ← 后端交互（AgentApiService）
│              │   • HTTP GET请求
│              │   • SSE事件监听
└──────────────┘
```

## 后端API要求

后端需要实现以下端点：

### REST API（只读）

```bash
# 获取所有智能体
GET /api/agents
Response: AIAgent[]

# 获取启用的智能体
GET /api/agents?enabled=true
Response: AIAgent[]

# 获取单个智能体详情
GET /api/agents/:agentId
Response: AIAgent

# 通知智能体被使用
POST /api/agents/:agentId/use
Request: {}
Response: { success: true }
```

### SSE推送（实时同步）

```bash
# 智能体列表实时推送
GET /api/agents/stream

# SSE事件格式
event: agents_update
data: [{"agentId":"gpt-4","name":"GPT-4",...}]
id: 12345
```

### AIAgent数据格式

```json
{
  "id": 1,
  "agentId": "gpt-4",
  "name": "GPT-4",
  "description": "通用AI助手",
  "endpoint": "https://api.openai.com/v1/chat/completions",
  "modelName": "gpt-4",
  "apiKey": "sk-...",
  "avatar": "https://...",
  "isEnabled": true,
  "isDefault": true,
  "isPreset": true,
  "sortOrder": 1,
  "messageCount": 0,
  "lastUsedAt": "2025-12-01T10:00:00Z",
  "modelParams": "{\"temperature\":0.7,\"max_tokens\":2000}",
  "createdAt": "2025-12-01T10:00:00Z",
  "updatedAt": "2025-12-01T10:00:00Z"
}
```

## 常见问题

### Q: 如何添加新的智能体？

A: 在后端管理界面添加，客户端会通过SSE自动同步。

### Q: 如何修改智能体配置？

A: 在后端修改，变更会通过SSE实时推送给所有客户端。

### Q: 离线时能使用智能体吗？

A: 可以，会使用本地缓存的智能体列表，但无法获取最新变更。

### Q: SSE断开后会怎样？

A: 会自动重连（最多10次），同时API请求正常工作。

### Q: 如何强制刷新智能体列表？

A: 重启应用或调用：
```dart
await AIAgentService.instance.getEnabledAgents(forceCache: false);
```

## 使用示例

### 示例1: 加载智能体列表

```dart
class AgentListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentListState = ref.watch(agentListProvider);

    if (agentListState.isLoading) {
      return CircularProgressIndicator();
    }

    if (agentListState.error != null) {
      return Text('错误: ${agentListState.error}');
    }

    return ListView.builder(
      itemCount: agentListState.agents.length,
      itemBuilder: (context, index) {
        final agent = agentListState.agents[index];
        return ListTile(
          title: Text(agent.name),
          subtitle: Text(agent.description ?? ''),
          onTap: () {
            ref.read(agentListProvider.notifier).selectAgent(agent.agentId);
          },
        );
      },
    );
  }
}
```

### 示例2: 显示当前选中的智能体

```dart
class SelectedAgentWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAgent = ref.watch(selectedAgentProvider);

    if (selectedAgent == null) {
      return Text('未选择智能体');
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前智能体: ${selectedAgent.name}'),
            Text('模型: ${selectedAgent.modelName}'),
            Text('使用次数: ${selectedAgent.messageCount}'),
          ],
        ),
      ),
    );
  }
}
```

### 示例3: 手动刷新智能体列表

```dart
ElevatedButton(
  onPressed: () async {
    await ref.read(agentListProvider.notifier).loadAgents();
  },
  child: Text('刷新'),
);
```

## 测试

### 测试后端API

```bash
# 测试获取智能体列表
curl http://localhost:3000/api/agents

# 测试SSE连接
curl -N http://localhost:3000/api/agents/stream

# 测试使用通知
curl -X POST http://localhost:3000/api/agents/gpt-4/use
```

### 测试客户端

```dart
// 在测试环境中
await AIAgentService.instance.clearAllAgents(); // 清空缓存
await AIAgentService.instance.initializeAgents(); // 重新同步
```

## 相关文档

- [详细架构文档](./ARCHITECTURE.md) - 完整的技术架构说明
- [API规范](./API_SPEC.md) - 后端API详细规范（待创建）

## 故障排查

### 问题: 智能体列表为空

检查项：
1. `.env`文件中的`API_BASE_URL`是否正确
2. 后端服务是否运行
3. 查看控制台日志

### 问题: SSE连接失败

检查项：
1. 后端是否实现了`/api/agents/stream`端点
2. 查看网络请求是否被CORS阻止
3. 检查SSE事件格式是否正确

### 问题: 网络请求超时

解决方法：
```dart
// 调整超时时间
HttpClient.instance.setTimeout(
  connectTimeout: Duration(seconds: 60),
  receiveTimeout: Duration(seconds: 60),
);
```

## 联系支持

如有问题，请查阅：
- 控制台日志中的错误信息
- [详细架构文档](./ARCHITECTURE.md)
- 项目Issue追踪
