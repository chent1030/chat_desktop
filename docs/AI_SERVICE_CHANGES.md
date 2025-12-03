# AI服务修改说明

## 修改概述

将应用从**多智能体选择模式**简化为**单一智能体配置模式**，并将对话方式从原有的适配器模式改为**POST请求+SSE流式响应**方式。

## 主要修改

### 1. 环境配置（.env.example）

新增以下配置项：
```env
# AI服务配置
AI_API_URL=https://your-api-server.com/api/chat
AI_API_KEY=your-api-key-here

# SSE接收地址（如果与发送地址不同，可选）
AI_SSE_URL=https://your-api-server.com/api/chat/stream
```

移除了原有的：
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`

### 2. AgentProvider 简化

**文件**: `lib/providers/agent_provider.dart`

- **删除**: 智能体列表管理功能、智能体选择功能
- **新增**: `AgentConfig` 类 - 从环境变量读取单一AI配置
- **新增**: `agentConfigProvider` - 提供全局AI配置

### 3. AI服务重构

**文件**: `lib/services/ai_service.dart`

完全重写AI服务类，采用**POST+SSE方式**：

1. **POST请求发送消息**
   - 将对话历史转换为标准格式
   - 发送POST请求到配置的API端点
   - 携带Bearer Token认证

2. **SSE接收流式响应**
   - 建立SSE连接接收流式响应
   - 逐字符返回AI生成的内容
   - 支持中断和错误处理

#### API请求格式

```json
POST /api/chat
Headers:
  Authorization: Bearer {API_KEY}
  Content-Type: application/json

Body:
{
  "messages": [
    { "role": "user", "content": "用户消息" },
    { "role": "assistant", "content": "AI回复" }
  ]
}
```

#### SSE响应格式（需根据实际API调整）

```
data: {"content": "文本片段", "done": false}

data: {"content": "更多文本", "done": false}

data: {"content": "", "done": true}
```

**注意**: 代码中的SSE数据解析部分需要根据您的实际API响应格式进行调整（第99-123行）。

### 4. ChatProvider 更新

**文件**: `lib/providers/chat_provider.dart`

- 移除对`selectedAgentProvider`的依赖
- 使用`agentConfigProvider`获取AI配置
- 简化`createNewConversation`方法，不再需要传入agentId
- 简化`_streamAIResponse`方法，直接调用新的AIService

### 5. UI组件更新

#### ChatView (`lib/widgets/chat/chat_view.dart`)

- **移除**: AgentSelector智能体选择器
- **移除**: 对`selectedAgentProvider`的引用
- **更新**: 顶部工具栏显示固定标题"AI助手"
- **更新**: 空状态提示文案

#### HomeScreen (`lib/screens/home_screen.dart`)

- 清理未使用的导入

### 6. 删除的组件

以下文件/代码不再需要，但保留以供参考：
- `lib/widgets/chat/agent_selector.dart` - 智能体选择器组件（UI已不再使用）
- `lib/services/adapters/openai_adapter.dart` - OpenAI适配器（已不再使用）
- `lib/services/adapters/anthropic_adapter.dart` - Anthropic适配器（已不再使用）
- `lib/services/agent_api_service.dart` - 智能体API服务（已不再使用）

## 使用说明

### 配置环境变量

1. 复制 `.env.example` 到 `.env`
2. 填写您的AI服务配置：
   ```env
   AI_API_URL=https://your-api.com/chat
   AI_API_KEY=your-api-key
   # 如果SSE端点不同，设置AI_SSE_URL
   AI_SSE_URL=https://your-api.com/chat/stream
   ```

### 适配您的API

在 `lib/services/ai_service.dart` 中需要根据您的实际API调整以下部分：

#### 1. POST请求响应处理（第71-83行）

如果您的API在POST响应中返回stream_id：
```dart
final streamId = response.data['stream_id'] ?? response.data['id'];
```

#### 2. SSE数据解析（第99-123行）

根据您的SSE响应格式调整：
```dart
// 当前代码支持以下格式:
// { "content": "文本", "done": false }
// { "text": "文本", "finish_reason": null }
// { "delta": "文本", "completed": false }

// 如果您的格式不同，需要修改这部分代码
final content = data['content'] ?? data['text'] ?? data['delta'];
```

### 测试对话功能

1. 运行应用: `flutter run`
2. 在聊天界面输入消息
3. 观察控制台日志确认：
   - POST请求成功发送
   - SSE连接建立成功
   - 流式响应正常接收

## 注意事项

1. **API兼容性**: 确保您的后端API支持POST+SSE方式
2. **认证方式**: 当前使用Bearer Token认证，如需其他方式请修改headers
3. **错误处理**: 已包含基本的错误处理和重试逻辑
4. **网络超时**: 默认连接超时30秒，接收超时60秒，可根据需要调整

## 回滚方案

如需恢复原有的多智能体+适配器模式，可以：
1. 从Git历史恢复修改前的文件
2. 恢复 `.env.example` 配置
3. 运行 `flutter pub get` 确保依赖正确

## 调试技巧

启用详细日志查看请求/响应：
```dart
// 在 lib/services/ai_service.dart 中
print('📤 [AI] 发送消息到: $apiUrl');
print('✓ [AI] POST请求成功，准备接收SSE流');
print('⚠️ [AI] 解析SSE数据失败');
```

控制台会显示详细的网络交互过程。
