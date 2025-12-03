# 智能体数据架构设计文档

## 架构概览

本项目采用**只读客户端架构**，客户端不能创建/修改/删除智能体，只能从后端获取和使用。

**核心原则**:
- 🔒 **只读客户端**: 所有智能体管理由后端控制
- 📡 **实时同步**: 通过SSE推送智能体列表变化
- 💾 **本地缓存**: 离线可用，优先远程数据
- 🚀 **自动降级**: 网络失败时使用本地缓存

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Widgets)                   │
│              AgentSelector, AgentListView               │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              State Management (Riverpod)                │
│                  AgentProvider                          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│           Service Layer (缓存层)                         │
│                AIAgentService                           │
│    - 优先从API获取数据                                    │
│    - 失败时fallback到本地缓存                             │
│    - SSE实时同步到本地                                    │
└─────────┬───────────────────────────┬───────────────────┘
          │                           │
┌─────────▼─────────┐       ┌─────────▼─────────┐
│  AgentApiService  │       │  StorageService   │
│  (远程数据源)      │       │   (Isar本地库)    │
│  - HTTP请求       │       │                   │
│  - SSE实时推送    │       │                   │
└─────────┬─────────┘       └───────────────────┘
          │
┌─────────▼─────────┐
│  HttpClient +     │
│   SSEClient       │
│  (网络层工具)      │
└───────────────────┘
```

## 核心组件

### 1. HttpClient (`lib/services/http_client.dart`)

**职责**: 统一的HTTP请求处理

**特性**:
- 基于Dio，提供GET/POST/PUT/PATCH/DELETE方法
- 自动添加认证token（从.env读取）
- 统一的错误处理和日志
- 支持请求/响应拦截器
- 可配置超时时间

**使用示例**:
```dart
final client = HttpClient.instance;

// GET请求
final response = await client.get('/api/agents');

// POST请求
final response = await client.post(
  '/api/agents',
  data: {'name': 'GPT-4', 'modelName': 'gpt-4'},
);
```

**配置**:
在`.env`文件中设置：
```
API_BASE_URL=http://localhost:3000
API_TOKEN=your_token_here
```

### 2. SSEClient (`lib/services/sse_client.dart`)

**职责**: Server-Sent Events 客户端

**特性**:
- 支持SSE协议解析（event、data、id、retry字段）
- 自动重连机制（可配置重连次数和延迟）
- 断点续传（Last-Event-ID）
- 流式事件推送
- SSEManager用于管理多个连接

**使用示例**:
```dart
final sseClient = SSEClient(
  url: 'http://localhost:3000/api/agents/stream',
  autoReconnect: true,
  reconnectDelay: Duration(seconds: 5),
  maxReconnectAttempts: 10,
);

sseClient.stream.listen((event) {
  switch (event.type) {
    case SSEEventType.message:
      print('收到数据: ${event.data}');
      break;
    case SSEEventType.error:
      print('连接错误');
      break;
  }
});

// 关闭连接
sseClient.close();
```

**SSE事件格式**:
```
event: agents_update
data: [{"agentId":"gpt-4","name":"GPT-4",...}]
id: 12345

event: agent_created
data: {"agentId":"custom-123","name":"My Agent"}
```

### 3. AgentApiService (`lib/services/agent_api_service.dart`)

**职责**: 智能体API服务，负责与后端交互

**HTTP API方法** (只读):
- `fetchAgents()` - 获取所有智能体
- `fetchEnabledAgents()` - 获取启用的智能体
- `fetchAgentByAgentId(agentId)` - 获取单个智能体详情
- `incrementMessageCount(agentId)` - 通知后端使用（不阻塞）
- `updateLastUsedAt(agentId)` - 通知后端最后使用时间（不阻塞）

**SSE实时更新**:
```dart
// 连接SSE
AgentApiService.instance.connectAgentsSSE();

// 监听更新
AgentApiService.instance.agentsStream.listen((agents) {
  print('收到智能体列表更新: ${agents.length}个');
});

// 断开连接
AgentApiService.instance.disconnectAgentsSSE();
```

**API端点** (客户端只读):
```
GET    /api/agents                         - 获取所有智能体
GET    /api/agents?enabled=true            - 获取启用的智能体
GET    /api/agents/:agentId                - 获取智能体详情
POST   /api/agents/:agentId/use            - 通知使用（消息计数+1）
SSE    /api/agents/stream                  - 智能体列表实时推送
```

**注意**: 客户端不提供创建/更新/删除智能体的API，这些操作由后端管理员控制。

### 4. AIAgentService (`lib/services/ai_agent_service.dart`)

**职责**: 智能体缓存层，桥接API和本地存储

**核心策略**:
1. **优先远程**: 所有读取操作优先从API获取最新数据
2. **自动缓存**: API获取成功后自动缓存到Isar本地数据库
3. **离线降级**: 网络失败时fallback到本地缓存
4. **实时同步**: 监听SSE推送，自动同步到本地

**主要方法** (只读):
```dart
// 获取智能体（优先API，失败用缓存）
final agents = await AIAgentService.instance.getEnabledAgents();

// 强制从缓存读取（离线模式）
final agents = await AIAgentService.instance.getEnabledAgents(forceCache: true);

// 获取单个智能体
final agent = await AIAgentService.instance.getAgentByAgentId('gpt-4');

// 增加使用计数（仅通知后端，不阻塞）
await AIAgentService.instance.incrementAgentMessageCount('gpt-4');

// SSE连接管理
AIAgentService.instance.connectSSE();
AIAgentService.instance.disconnectSSE();
AIAgentService.instance.reconnectSSE();
```

**SSE自动同步流程**:
```
1. AIAgentService初始化时自动监听agentsStream
2. 收到SSE推送 → 触发_syncAgentsToLocal()
3. 清空本地数据 → 批量插入新数据
4. 本地缓存更新完成
```

## 数据流

### 场景1: 应用启动时获取智能体列表

```
1. AgentProvider.loadAgents()
   ↓
2. AIAgentService.getEnabledAgents()
   ↓
3. AgentApiService.fetchEnabledAgents()
   ↓ (成功)
4. AIAgentService更新Isar缓存
   ↓
5. 返回智能体列表到Provider
   ↓
6. UI更新显示

   (如果第3步失败)
   ↓
4. AIAgentService从Isar缓存读取
   ↓
5. 返回缓存数据（可能过期但可用）
```

### 场景2: 用户选择并使用智能体

```
1. 用户点击AgentSelector选择智能体
   ↓
2. AgentProvider.selectAgent(agentId)
   ↓
3. AIAgentService.getAgentByAgentId(agentId)
   ↓
4. 更新本地缓存（最后使用时间）
   ↓
5. 通知后端使用（不阻塞）
   AIAgentService.incrementAgentMessageCount(agentId)
   ↓
6. UI更新显示选中的智能体
```

### 场景3: SSE实时推送更新

```
1. 后端智能体数据变化
   ↓
2. 后端SSE推送 (event: agents_update)
   ↓
3. SSEClient接收并解析事件
   ↓
4. AgentApiService.agentsStream发射新数据
   ↓
5. AIAgentService._syncAgentsToLocal()
   ↓
6. 更新Isar缓存
   ↓
7. watchAgents()流通知UI
   ↓
8. UI自动刷新
```

## 错误处理

### HTTP错误

```dart
try {
  final agents = await AIAgentService.instance.getEnabledAgents();
} catch (e) {
  if (e is HttpException) {
    if (e.isNetworkError) {
      // 网络错误 → 已自动fallback到缓存
    } else if (e.isAuthError) {
      // 401/403 → 需要重新登录
    } else if (e.statusCode == 404) {
      // 资源不存在
    }
  }
}
```

### SSE错误

```dart
sseClient.stream.listen(
  (event) {
    if (event.type == SSEEventType.error) {
      // SSE连接错误
      // 自动重连机制会处理
    }
  },
  onError: (error) {
    // 流错误
  },
);
```

## 配置

### 环境变量 (`.env`)

```bash
# API基础URL
API_BASE_URL=http://localhost:3000

# API认证Token (可选)
API_TOKEN=your_token_here
```

### 超时配置

```dart
// 修改HTTP超时
HttpClient.instance.setTimeout(
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
);

// SSE超时（在创建SSEClient时设置）
SSEClient(
  url: '...',
  timeout: Duration(minutes: 5),
);
```

### SSE重连配置

```dart
SSEClient(
  url: '...',
  autoReconnect: true,            // 是否自动重连
  reconnectDelay: Duration(seconds: 3),  // 重连延迟
  maxReconnectAttempts: 5,        // 最大重连次数
);
```

## 测试

### 测试HTTP API

```bash
# 获取智能体列表
curl http://localhost:3000/api/agents

# 创建智能体
curl -X POST http://localhost:3000/api/agents \
  -H "Content-Type: application/json" \
  -d '{"name":"GPT-4","modelName":"gpt-4","endpoint":"https://api.openai.com/v1/chat/completions"}'
```

### 测试SSE

```bash
# 监听智能体更新
curl -N http://localhost:3000/api/agents/stream
```

## 性能优化

1. **缓存优先**: 离线模式或弱网环境下使用`forceCache: true`
2. **批量同步**: SSE推送时批量更新，减少数据库写入次数
3. **懒加载**: 只在需要时获取智能体详情
4. **连接复用**: HttpClient和SSEClient使用单例模式

## 扩展性

### 添加新的API端点

```dart
// 在AgentApiService中添加
Future<List<AIAgent>> fetchTrendingAgents() async {
  final response = await _httpClient.get('/api/agents/trending');
  return (response.data as List)
      .map((json) => AIAgent.fromJson(json))
      .toList();
}
```

### 添加新的SSE事件类型

```dart
// 在AgentApiService._handleSSEMessage()中添加
case 'agent_trending':
  // 处理热门智能体推送
  break;
```

## 注意事项

1. **Token安全**: 不要将API_TOKEN提交到版本控制
2. **SSE长连接**: 注意移动设备的电池消耗
3. **缓存过期**: 考虑添加缓存过期策略
4. **并发控制**: 避免同时多次调用相同API
5. **错误恢复**: 网络恢复后自动刷新数据

## 后端API要求

后端需要实现以下接口（客户端只读）：

```typescript
// REST API (只读)
GET    /api/agents                   // 返回 AIAgent[]
GET    /api/agents?enabled=true      // 返回启用的智能体
GET    /api/agents/:agentId          // 返回单个AIAgent
POST   /api/agents/:agentId/use      // 通知智能体被使用（消息计数+1）

// SSE推送 (实时同步)
GET    /api/agents/stream            // SSE endpoint
  → event: agents_update, data: AIAgent[]
    后端智能体列表变化时推送完整列表
```

**重要说明**:
- 客户端**不能创建/修改/删除**智能体
- 所有智能体管理由后端管理员控制
- 客户端只能读取和使用智能体
- 通过SSE实时推送变更给所有客户端

**AIAgent JSON格式**:
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

## 相关文件

- `lib/services/http_client.dart` - HTTP客户端
- `lib/services/sse_client.dart` - SSE客户端
- `lib/services/agent_api_service.dart` - 智能体API服务
- `lib/services/ai_agent_service.dart` - 智能体缓存层
- `lib/models/ai_agent.dart` - 智能体数据模型
- `lib/providers/agent_provider.dart` - 智能体状态管理
