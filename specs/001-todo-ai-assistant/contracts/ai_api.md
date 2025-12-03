# AI服务API：多智能体对话

**功能**: 001-todo-ai-assistant
**日期**: 2025-11-27
**目的**: 定义客户端与AI服务的HTTP API接口，支持多智能体对话和流式响应

## 概述

应用支持多个AI智能体（如GPT-4、Claude等），每个智能体有独立的API端点和配置。本文档定义通用的API接口规范，具体智能体的端点由AIAgent实体配置。

## 通用规范

### 基础信息

- **协议**: HTTPS
- **内容类型**: `application/json`
- **字符编码**: UTF-8
- **认证方式**: API Key (Bearer Token)

### 请求头

```http
Content-Type: application/json
Authorization: Bearer <api_key>
X-Client-ID: <device_id>
X-Client-Version: 1.0.0
```

### 响应格式

所有API响应包含以下字段：

```json
{
  "success": true,
  "data": { /* 响应数据 */ },
  "error": null,
  "metadata": {
    "requestId": "req-123456",
    "timestamp": "2025-11-27T10:30:00Z"
  }
}
```

**错误响应**:
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {}
  },
  "metadata": {
    "requestId": "req-123456",
    "timestamp": "2025-11-27T10:30:00Z"
  }
}
```

## AI智能体配置接口

### 1. 获取智能体列表

**端点**: `GET /api/v1/agents`

**描述**: 获取所有可用的AI智能体配置

**请求**:
```http
GET /api/v1/agents HTTP/1.1
Host: api.example.com
Authorization: Bearer <api_key>
```

**响应**:
```json
{
  "success": true,
  "data": {
    "agents": [
      {
        "agentId": "gpt-4",
        "name": "GPT-4",
        "description": "通用AI助手，适合各类对话",
        "iconUrl": "https://cdn.example.com/icons/gpt4.png",
        "endpoint": "https://api.openai.com/v1/chat/completions",
        "capabilities": ["chat", "task_parsing"],
        "isEnabled": true,
        "sortOrder": 1
      },
      {
        "agentId": "claude-3",
        "name": "Claude 3",
        "description": "擅长分析和创作的AI助手",
        "iconUrl": "https://cdn.example.com/icons/claude.png",
        "endpoint": "https://api.anthropic.com/v1/messages",
        "capabilities": ["chat", "task_parsing", "analysis"],
        "isEnabled": true,
        "sortOrder": 2
      }
    ]
  },
  "metadata": {
    "requestId": "req-001",
    "timestamp": "2025-11-27T10:30:00Z"
  }
}
```

## 对话接口

### 2. 发送消息（非流式）

**端点**: `POST /api/v1/chat/completions`

**描述**: 向指定智能体发送消息，获取完整响应

**请求**:
```http
POST /api/v1/chat/completions HTTP/1.1
Host: api.example.com
Authorization: Bearer <api_key>
Content-Type: application/json

{
  "agentId": "gpt-4",
  "conversationId": "conv-123",
  "messages": [
    {
      "role": "user",
      "content": "帮我总结一下今天的待办任务"
    }
  ],
  "context": {
    "tasks": [
      {"title": "完成项目报告", "priority": "high"},
      {"title": "团队会议", "priority": "medium"}
    ]
  },
  "options": {
    "temperature": 0.7,
    "maxTokens": 2000
  }
}
```

**请求参数**:
- `agentId` (必需): 智能体标识符
- `conversationId` (可选): 会话ID，用于上下文关联
- `messages` (必需): 消息列表
  - `role`: `user`, `assistant`, `system`
  - `content`: 消息内容
- `context` (可选): 上下文信息（如当前任务列表）
- `options` (可选): 模型参数
  - `temperature`: 创造性，范围0-1
  - `maxTokens`: 最大token数

**响应**:
```json
{
  "success": true,
  "data": {
    "conversationId": "conv-123",
    "message": {
      "role": "assistant",
      "content": "根据您的任务列表，今天有以下待办事项：\n\n1. **完成项目报告**（高优先级）\n2. **团队会议**（中优先级）\n\n建议您优先处理项目报告。",
      "timestamp": "2025-11-27T10:30:05Z"
    },
    "usage": {
      "promptTokens": 150,
      "completionTokens": 80,
      "totalTokens": 230
    }
  },
  "metadata": {
    "requestId": "req-002",
    "timestamp": "2025-11-27T10:30:05Z",
    "latency": 1250
  }
}
```

### 3. 发送消息（流式）

**端点**: `POST /api/v1/chat/stream`

**描述**: 向指定智能体发送消息，获取流式响应（Server-Sent Events）

**请求**:
```http
POST /api/v1/chat/stream HTTP/1.1
Host: api.example.com
Authorization: Bearer <api_key>
Content-Type: application/json
Accept: text/event-stream

{
  "agentId": "claude-3",
  "conversationId": "conv-456",
  "messages": [
    {
      "role": "user",
      "content": "请分析这个任务的优先级"
    }
  ],
  "options": {
    "temperature": 0.7
  }
}
```

**响应（Server-Sent Events）**:
```
event: message_start
data: {"conversationId":"conv-456","messageId":"msg-789","timestamp":"2025-11-27T10:31:00Z"}

event: content_delta
data: {"delta":"根据","index":0}

event: content_delta
data: {"delta":"任务","index":1}

event: content_delta
data: {"delta":"的","index":2}

event: content_delta
data: {"delta":"紧急程度","index":3}

event: content_delta
data: {"delta":"和","index":4}

event: content_delta
data: {"delta":"重要性","index":5}

event: message_end
data: {"messageId":"msg-789","usage":{"promptTokens":120,"completionTokens":60,"totalTokens":180},"finishReason":"stop"}

event: done
data: {}
```

**事件类型**:
- `message_start`: 消息开始
- `content_delta`: 内容增量
- `message_end`: 消息结束
- `error`: 错误事件
- `done`: 流结束

### 4. 获取对话历史

**端点**: `GET /api/v1/conversations/:conversationId/messages`

**描述**: 获取指定会话的历史消息

**请求**:
```http
GET /api/v1/conversations/conv-123/messages?limit=50&before=msg-100 HTTP/1.1
Host: api.example.com
Authorization: Bearer <api_key>
```

**查询参数**:
- `limit` (可选): 返回消息数量，默认50，最大100
- `before` (可选): 游标，返回指定消息之前的消息
- `after` (可选): 游标，返回指定消息之后的消息

**响应**:
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "messageId": "msg-001",
        "role": "user",
        "content": "你好",
        "timestamp": "2025-11-27T09:00:00Z"
      },
      {
        "messageId": "msg-002",
        "role": "assistant",
        "content": "你好！有什么可以帮助您的吗？",
        "timestamp": "2025-11-27T09:00:02Z"
      }
    ],
    "pagination": {
      "hasMore": true,
      "nextCursor": "msg-050",
      "total": 150
    }
  },
  "metadata": {
    "requestId": "req-003",
    "timestamp": "2025-11-27T10:32:00Z"
  }
}
```

## 任务解析接口

### 5. 解析自然语言任务

**端点**: `POST /api/v1/tasks/parse`

**描述**: 使用AI解析自然语言输入，提取任务属性

**请求**:
```http
POST /api/v1/tasks/parse HTTP/1.1
Host: api.example.com
Authorization: Bearer <api_key>
Content-Type: application/json

{
  "agentId": "gpt-4",
  "input": "明天下午3点完成项目报告，这是高优先级任务"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "parsedTask": {
      "title": "完成项目报告",
      "description": null,
      "priority": "high",
      "dueDate": "2025-11-28T15:00:00Z"
    },
    "confidence": 0.95,
    "suggestions": [
      "建议添加任务描述，明确报告内容",
      "建议设置提醒，避免遗漏"
    ]
  },
  "metadata": {
    "requestId": "req-004",
    "timestamp": "2025-11-27T10:33:00Z"
  }
}
```

**字段说明**:
- `parsedTask`: 解析出的任务属性
- `confidence`: 置信度，范围0-1
- `suggestions`: AI的建议

### 6. 任务操作确认

**端点**: `POST /api/v1/tasks/actions/confirm`

**描述**: 确认AI建议的任务操作（FR-019要求）

**请求**:
```http
POST /api/v1/tasks/actions/confirm HTTP/1.1
Host: api.example.com
Authorization: Bearer <api_key>
Content-Type: application/json

{
  "actionId": "action-123",
  "confirmed": true,
  "modifications": {
    "priority": "medium"
  }
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "actionId": "action-123",
    "status": "confirmed",
    "appliedTask": {
      "serverId": "task-9999",
      "title": "完成项目报告",
      "priority": "medium"
    }
  },
  "metadata": {
    "requestId": "req-005",
    "timestamp": "2025-11-27T10:34:00Z"
  }
}
```

## 错误码

| 错误码 | HTTP状态码 | 说明 | 处理方式 |
|--------|-----------|------|---------|
| `INVALID_API_KEY` | 401 | API密钥无效 | 检查配置，重新设置 |
| `RATE_LIMIT_EXCEEDED` | 429 | 请求频率过高 | 实现指数退避重试 |
| `AGENT_NOT_FOUND` | 404 | 智能体不存在 | 检查agentId是否正确 |
| `INVALID_REQUEST` | 400 | 请求参数错误 | 检查请求格式 |
| `CONTEXT_TOO_LONG` | 400 | 上下文过长 | 减少消息历史或任务数量 |
| `MODEL_ERROR` | 500 | AI模型错误 | 稍后重试或切换智能体 |
| `TIMEOUT` | 504 | 请求超时 | 重试或调整超时设置 |

## 速率限制

### 限制规则

- **每分钟请求数（RPM）**: 60
- **每天请求数（RPD）**: 10000
- **并发连接数**: 5

### 响应头

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1701086400
```

### 超限响应

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "已超过请求频率限制",
    "details": {
      "limit": 60,
      "remaining": 0,
      "resetAt": "2025-11-27T10:35:00Z"
    }
  },
  "metadata": {
    "requestId": "req-006",
    "timestamp": "2025-11-27T10:34:30Z"
  }
}
```

## 多智能体适配

### OpenAI GPT适配

```dart
class OpenAIAdapter implements AIServiceAdapter {
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final response = await dio.post(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-4',
        'messages': request.messages.map((m) => {
          'role': m.role,
          'content': m.content,
        }).toList(),
        'temperature': request.options.temperature,
        'max_tokens': request.options.maxTokens,
      },
      options: Options(headers: {
        'Authorization': 'Bearer ${agent.apiKey}',
      }),
    );

    return ChatResponse.fromOpenAI(response.data);
  }

  @override
  Stream<ChatDelta> sendMessageStream(ChatRequest request) async* {
    final response = await dio.post(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-4',
        'messages': request.messages.map((m) => {
          'role': m.role,
          'content': m.content,
        }).toList(),
        'stream': true,
      },
      options: Options(
        headers: {'Authorization': 'Bearer ${agent.apiKey}'},
        responseType: ResponseType.stream,
      ),
    );

    await for (final chunk in response.data.stream) {
      final lines = utf8.decode(chunk).split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') return;

          final json = jsonDecode(data);
          yield ChatDelta(
            content: json['choices'][0]['delta']['content'] ?? '',
          );
        }
      }
    }
  }
}
```

### Anthropic Claude适配

```dart
class AnthropicAdapter implements AIServiceAdapter {
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final response = await dio.post(
      'https://api.anthropic.com/v1/messages',
      data: {
        'model': 'claude-3-opus-20240229',
        'messages': request.messages.map((m) => {
          'role': m.role,
          'content': m.content,
        }).toList(),
        'max_tokens': request.options.maxTokens ?? 4096,
      },
      options: Options(headers: {
        'x-api-key': agent.apiKey,
        'anthropic-version': '2023-06-01',
      }),
    );

    return ChatResponse.fromAnthropic(response.data);
  }

  @override
  Stream<ChatDelta> sendMessageStream(ChatRequest request) async* {
    final response = await dio.post(
      'https://api.anthropic.com/v1/messages',
      data: {
        'model': 'claude-3-opus-20240229',
        'messages': request.messages.map((m) => {
          'role': m.role,
          'content': m.content,
        }).toList(),
        'stream': true,
      },
      options: Options(
        headers: {
          'x-api-key': agent.apiKey,
          'anthropic-version': '2023-06-01',
        },
        responseType: ResponseType.stream,
      ),
    );

    await for (final chunk in response.data.stream) {
      final lines = utf8.decode(chunk).split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          final json = jsonDecode(data);

          if (json['type'] == 'content_block_delta') {
            yield ChatDelta(
              content: json['delta']['text'] ?? '',
            );
          }
        }
      }
    }
  }
}
```

## 性能优化

### 1. 请求缓存

对于相同的请求，缓存响应：

```dart
class CachedAIService {
  final _cache = <String, ChatResponse>{};

  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final cacheKey = _generateCacheKey(request);

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final response = await _aiService.sendMessage(request);
    _cache[cacheKey] = response;

    return response;
  }
}
```

### 2. 请求合并

将短时间内的多个请求合并：

```dart
class BatchedAIService {
  final _pendingRequests = <ChatRequest>[];
  Timer? _batchTimer;

  Future<ChatResponse> sendMessage(ChatRequest request) async {
    _pendingRequests.add(request);

    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(milliseconds: 100), _flushBatch);

    // 返回Future，等待批量处理结果
  }

  Future<void> _flushBatch() async {
    if (_pendingRequests.isEmpty) return;

    // 发送批量请求到后端
    final response = await _aiService.sendBatchMessages(_pendingRequests);

    // 分发结果
  }
}
```

### 3. 超时控制

```dart
Future<ChatResponse> sendMessageWithTimeout(ChatRequest request) async {
  return await _aiService.sendMessage(request).timeout(
    Duration(seconds: 30),
    onTimeout: () {
      throw TimeoutException('AI响应超时');
    },
  );
}
```

## 安全性

### 1. API Key保护

- 不在代码中硬编码API Key
- 使用环境变量或安全存储
- 定期轮换API Key

```dart
class SecureKeyStorage {
  Future<String> getAPIKey(String agentId) async {
    // 从安全存储读取（如Keychain/Credential Manager）
    final secureStorage = FlutterSecureStorage();
    return await secureStorage.read(key: 'api_key_$agentId') ?? '';
  }
}
```

### 2. 输入验证

```dart
bool validateMessage(String content) {
  if (content.isEmpty || content.length > 10000) {
    return false;
  }

  // 检查恶意内容
  final prohibitedPatterns = [
    'ignore previous instructions',
    'system prompt',
  ];

  for (final pattern in prohibitedPatterns) {
    if (content.toLowerCase().contains(pattern)) {
      return false;
    }
  }

  return true;
}
```

### 3. 敏感信息过滤

```dart
String sanitizeContent(String content) {
  // 移除可能的API Key
  content = content.replaceAll(RegExp(r'sk-[a-zA-Z0-9]{20,}'), '[REDACTED]');

  // 移除可能的密码
  content = content.replaceAll(RegExp(r'password[:\s]*\S+'), 'password: [REDACTED]');

  return content;
}
```

## 监控与日志

### 关键指标

- API调用次数
- 平均响应时间
- 错误率
- Token使用量
- 成本估算

### 日志格式

```dart
void logAPICall({
  required String agentId,
  required String endpoint,
  required int statusCode,
  required int latency,
  required int tokens,
}) {
  final log = {
    'timestamp': DateTime.now().toIso8601String(),
    'agentId': agentId,
    'endpoint': endpoint,
    'statusCode': statusCode,
    'latency': latency,
    'tokens': tokens,
  };

  debugPrint('[AI API] ${jsonEncode(log)}');
}
```

---

## 版本历史

- **v1.0.0** (2025-11-27): 初始版本，支持多智能体对话和任务解析
