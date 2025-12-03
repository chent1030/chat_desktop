# Dify API 集成说明

## 修改概述

根据Dify.md文档，完整适配了Dify的ChunkChatCompletionResponse流式响应格式。

## Dify API 关键特点

### 1. Event类型（按重要性排序）

| Event | 说明 | 关键字段 |
|-------|------|---------|
| `message` | LLM文本块 | `answer`, `conversation_id`, `message_id` |
| `message_end` | 消息结束标志 | `conversation_id`, `metadata` |
| `error` | 错误事件 | `message`, `code`, `status` |
| `ping` | 保活事件（每10秒） | - |
| `workflow_*` | 工作流事件 | 多个workflow相关事件 |
| `message_file` | 文件事件 | `url`, `type` |
| `message_replace` | 内容替换（审查） | `answer` |
| `tts_message` | TTS音频流 | `audio` (base64) |

### 2. 关键字段说明

**文本内容字段是 `answer`**（不是content/text/delta）

**conversation_id**：
- 在每个 `message` 事件中都有
- 在 `message_end` 事件中也有
- 用于维持同一对话上下文

**结束判断**：
- 收到 `event: "message_end"` 即表示流式返回结束
- 收到 `event: "error"` 表示发生错误并结束

### 3. 流式响应示例

```
data: {"event": "message", "conversation_id": "xxx", "answer": " I", "created_at": 1679586595}

data: {"event": "message", "conversation_id": "xxx", "answer": "'m", "created_at": 1679586595}

data: {"event": "message", "conversation_id": "xxx", "answer": " glad", "created_at": 1679586595}

data: {"event": "message_end", "id": "xxx", "conversation_id": "xxx", "metadata": {...}}
```

## 代码实现

### 修改位置
`lib/services/ai_service.dart` 第129-219行

### 核心处理逻辑

```dart
final eventType = data['event'] as String?;
final responseConversationId = data['conversation_id'];

if (eventType == 'message') {
  // 提取answer字段作为文本内容
  final answer = data['answer'] as String?;
  yield AIStreamResponse(
    content: answer,
    conversationId: responseConversationId?.toString(),
    isDone: false,
  );
}
else if (eventType == 'message_end') {
  // 消息结束，返回最终的conversation_id
  yield AIStreamResponse(
    conversationId: responseConversationId?.toString(),
    isDone: true,
  );
  sseClient.close();
  break;
}
else if (eventType == 'error') {
  // 错误处理
  throw AIServiceException('Dify API错误: ${data['message']}');
}
// ... 其他event类型
```

### 支持的Event类型

✅ **已实现**：
- `message` - 提取answer字段，返回文本内容
- `message_end` - 结束标志，关闭SSE连接
- `message_replace` - 内容替换（审查相关）
- `error` - 错误处理，抛出异常
- `ping` - 保活事件，记录日志

📝 **已识别但暂不处理**：
- `workflow_started/node_started/node_finished/workflow_finished` - 工作流事件（仅记录日志）
- `message_file` - 文件事件（仅记录日志）
- `tts_message/tts_message_end` - TTS音频流（暂不处理）

## 调试日志

运行时控制台会显示详细的event处理日志：

```
📝 [AI] 收到 conversation_id: 45701982-8118-4bc5-8e9b-64562b4555f2
✓ [AI] 收到message_end，流式接收完成
💓 [AI] 收到ping保活事件
🔄 [AI] 收到工作流事件: node_started
📎 [AI] 收到文件事件
❌ [AI] 收到error事件: xxx
```

## 完整工作流程

### 首次对话
```
1. POST请求（conversation_id=null）
   ↓
2. 收到SSE流：
   - event: message → 提取answer累积文本
   - event: message → 继续累积
   - ...
   - event: message_end → 提取conversation_id并保存
   ↓
3. 前端保存conversation_id
```

### 后续对话
```
1. POST请求（带上保存的conversation_id）
   ↓
2. 收到SSE流：
   - event: message → 提取answer累积文本
   - event: message_end → 验证conversation_id
   ↓
3. 维持同一对话上下文
```

## 错误处理

### Dify API错误
当收到 `event: "error"` 时：
```json
{
  "event": "error",
  "message": "错误描述",
  "status": 400,
  "code": "error_code"
}
```

代码会抛出 `AIServiceException` 异常，包含错误消息。

### 常见错误码（文档摘录）
- 404 - 对话不存在
- 400, invalid_param - 传入参数异常
- 400, app_unavailable - App配置不可用
- 400, provider_not_initialize - 无可用模型凭据
- 400, provider_quota_exceeded - 模型调用额度不足
- 400, completion_request_error - 文本生成失败
- 500 - 服务内部异常

## 测试要点

### 1. 基础对话测试
- ✅ 发送消息，查看是否正确接收 `message` 事件
- ✅ 检查 `answer` 字段是否正确提取
- ✅ 验证文本是否逐块累积
- ✅ 确认收到 `message_end` 时对话结束

### 2. Conversation ID测试
- ✅ 首次对话后检查是否保存conversation_id
- ✅ 后续对话查看是否使用相同的conversation_id
- ✅ 验证AI能否记住对话上下文

### 3. 特殊Event测试
- ✅ 长对话（>10秒）验证ping事件
- ✅ 触发错误查看error事件处理
- ✅ 如果使用工作流，查看workflow事件日志

### 4. 控制台日志验证
```
📤 [AI] 发送消息到: xxx
📝 [AI] 收到 conversation_id: xxx
💬 [Chat] 保存 conversation_id: xxx
✓ [AI] 收到message_end，流式接收完成
```

## 与原有TODO对比

### 原来的TODO（已删除）
```dart
// TODO: 根据实际API响应格式调整字段名
final content = data['content'] ?? data['text'] ?? data['delta'] ...

// TODO: 从响应中提取conversation_id
final responseConversationId = data['conversation_id'] ?? ...
```

### 现在的实现
```dart
// 明确使用Dify的字段名
final answer = data['answer'] as String?;
final responseConversationId = data['conversation_id'];

// 明确使用Dify的event类型
if (eventType == 'message') { ... }
else if (eventType == 'message_end') { ... }
```

## 未来扩展

### 1. 文件支持
如需支持图片等文件，处理 `message_file` 事件：
```dart
else if (eventType == 'message_file') {
  final url = data['url'];
  final type = data['type']; // 'image'
  // 显示图片或下载文件
}
```

### 2. TTS支持
如需语音播放，处理 `tts_message` 事件：
```dart
else if (eventType == 'tts_message') {
  final audioBase64 = data['audio'];
  // 解码base64并播放音频
}
```

### 3. 工作流可视化
如需显示工作流执行过程：
```dart
else if (eventType == 'node_started') {
  final nodeName = data['data']['title'];
  // 更新UI显示当前执行节点
}
```

### 4. Metadata使用
`message_end` 事件包含丰富的metadata：
```dart
final metadata = data['metadata'];
final usage = metadata['usage'];
final totalTokens = usage['total_tokens'];
final totalPrice = usage['total_price'];
// 显示token使用量和费用
```

## 参考文档
- Dify.md - 完整API文档
- CONVERSATION_ID_USAGE.md - Conversation ID管理说明
- AI_SERVICE_CHANGES.md - AI服务修改总览
