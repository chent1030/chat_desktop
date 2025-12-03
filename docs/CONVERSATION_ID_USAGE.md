# Conversation ID 管理说明

## 功能概述

实现了后端conversation_id的自动管理，确保同一对话使用相同的conversation_id，让AI能够记住上下文。

## 工作流程

### 1. 首次对话
```
用户发送消息（conversation_id = null）
    ↓
POST /api/chat（不带conversation_id）
    ↓
后端创建新对话，返回conversation_id
    ↓
前端保存conversation_id
```

### 2. 后续对话
```
用户继续发送消息
    ↓
POST /api/chat（带上保存的conversation_id）
    ↓
后端识别为同一对话，维持上下文
    ↓
返回响应（可能再次包含conversation_id）
```

### 3. 新建会话
```
用户点击"新建会话"
    ↓
清空conversation_id（重置为null）
    ↓
下次发送消息时作为新对话
```

## 代码实现

### AIService (`lib/services/ai_service.dart`)

#### 新增 AIStreamResponse 类
```dart
class AIStreamResponse {
  final String? content;           // 文本内容
  final String? conversationId;    // 会话ID
  final bool isDone;               // 是否完成
}
```

#### SSE响应解析（带TODO标记）
```dart
// TODO: 根据实际API响应格式调整字段名
final content = data['content'] ??
              data['text'] ??
              data['delta'] ??
              data['answer'] ??
              data['message'];

// TODO: 从响应中提取conversation_id
// 通常在第一条消息或最后一条消息中返回
final responseConversationId = data['conversation_id'] ??
                              data['conversationId'] ??
                              data['session_id'] ??
                              data['sessionId'];
```

### ChatProvider (`lib/providers/chat_provider.dart`)

#### 新增状态变量
```dart
/// 后端返回的conversation_id（用于维持同一对话）
String? _backendConversationId;
```

#### 关键时机管理

**1. 创建新会话时重置**
```dart
Future<int?> createNewConversation(String? title) async {
  _backendConversationId = null; // 新会话重置
  // ...
}
```

**2. 发送消息时传递**
```dart
final stream = AIService.instance.sendMessageStream(
  apiUrl: agentConfig.apiUrl,
  apiKey: agentConfig.apiKey,
  messages: query,
  conversationId: _backendConversationId, // 传入保存的ID
);
```

**3. 接收响应时保存**
```dart
_streamSubscription = stream.listen(
  (response) async {
    // 如果收到conversation_id，保存它
    if (response.conversationId != null) {
      _backendConversationId = response.conversationId;
      print('✓ [Chat] 保存 conversation_id: $_backendConversationId');
    }
    // ...
  },
);
```

**4. 切换/清空会话时重置**
```dart
Future<void> loadConversation(int conversationId) async {
  _backendConversationId = null; // 切换会话时重置
  // ...
}

void clearConversation() {
  _backendConversationId = null; // 清空时重置
  // ...
}
```

## 需要您完成的部分

### 1. 调整SSE响应字段名

在 `lib/services/ai_service.dart` 的第121-135行，根据您的实际API响应格式修改：

**示例1：如果您的API返回格式是这样**
```json
{
  "answer": "AI的回复内容",
  "conversation_id": "abc123",
  "event": "message"
}
```

修改为：
```dart
final content = data['answer'];
final responseConversationId = data['conversation_id'];
```

**示例2：如果响应格式是这样**
```json
{
  "delta": "AI的",
  "session_id": "xyz789"
}
```

修改为：
```dart
final content = data['delta'];
final responseConversationId = data['session_id'];
```

### 2. 确认完成标志

在第143-147行，根据您的API确认对话结束的标志：

```dart
// 检查是否完成
final isDone = data['done'] == true ||           // 方式1
             data['finish_reason'] != null ||    // 方式2
             data['completed'] == true ||        // 方式3
             data['event'] == 'message_end' ||   // 方式4
             data['event'] == 'done';            // 方式5
```

选择适合您API的判断方式。

## 调试日志

代码中已添加详细日志，运行时可以在控制台看到：

```
💬 [Chat] 发送消息 - conversation_id: null          // 首次对话
📝 [AI] 收到 conversation_id: abc123                 // 收到ID
✓ [Chat] 保存 conversation_id: abc123               // 保存ID

💬 [Chat] 发送消息 - conversation_id: abc123        // 使用保存的ID
✓ [AI] SSE流接收完成
```

## 测试步骤

1. **首次对话测试**
   - 启动应用，创建新会话
   - 发送第一条消息
   - 查看控制台，应该看到 `conversation_id: null`
   - 收到响应后，应该看到 `保存 conversation_id: xxx`

2. **上下文保持测试**
   - 继续在同一会话中发送第二条消息
   - 查看控制台，应该看到 `conversation_id: xxx`（使用保存的ID）
   - AI应该能记住之前的对话内容

3. **新会话测试**
   - 点击"清除会话"或创建新会话
   - 发送消息
   - 查看控制台，应该重新显示 `conversation_id: null`

## 常见问题

### Q: conversation_id在哪条消息中返回？
A: 这取决于您的API设计。通常有两种情况：
- 在第一条SSE消息中返回（推荐）
- 在最后一条SSE消息中返回

代码会自动捕获任何消息中的conversation_id。

### Q: 如果API不返回conversation_id怎么办？
A: 检查SSE响应的JSON结构，找到对应的字段名，然后在TODO位置添加该字段名。

### Q: 可以手动设置conversation_id吗？
A: 可以，在ChatProvider中修改：
```dart
// 例如：从数据库加载之前的conversation_id
_backendConversationId = '从某处获取的ID';
```

### Q: conversation_id会持久化保存吗？
A: 当前实现中是内存保存，切换会话或重启应用会丢失。如需持久化，可以：
1. 保存到Conversation模型中
2. 使用SharedPreferences保存
3. 在数据库中添加backend_conversation_id字段

## 扩展建议

### 1. 持久化conversation_id
```dart
// 在Conversation模型中添加字段
class Conversation {
  String? backendConversationId;
  // ...
}

// 在ChatProvider中保存/加载
Future<void> loadConversation(int conversationId) async {
  final conversation = await _conversationService.getById(conversationId);
  _backendConversationId = conversation.backendConversationId;
  // ...
}
```

### 2. 错误重试时保持conversation_id
当前重试逻辑会保持conversation_id，确保重试时上下文不丢失。

### 3. 多个对话窗口
如果支持多窗口，每个ChatNotifier实例会独立管理自己的_backendConversationId。
