# WebSocket协议：任务同步

**功能**: 001-todo-ai-assistant
**日期**: 2025-11-27
**目的**: 定义客户端与服务器之间的WebSocket通信协议，用于实时同步待办任务

## 概述

客户端与服务器建立持久WebSocket连接，实现双向实时数据同步。协议使用JSON格式，支持任务的增删改查操作、批量同步和心跳机制。

## 连接信息

**端点**: `wss://api.example.com/ws/tasks`
**协议**: WSS (WebSocket Secure)
**认证**: 设备ID（临时版本）/ 域账户Token（未来版本）

## 连接建立

### 握手请求

```http
GET /ws/tasks HTTP/1.1
Host: api.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
X-Device-ID: <uuid>
X-Client-Version: 1.0.0
```

### 握手响应

```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
X-Session-ID: <session_id>
```

## 消息格式

所有消息使用JSON格式，包含以下通用字段：

```json
{
  "type": "message_type",
  "id": "unique_message_id",
  "timestamp": "2025-11-27T10:30:00Z",
  "payload": {}
}
```

**字段说明**:
- `type`: 消息类型（见下文类型列表）
- `id`: 消息唯一标识符（UUID）
- `timestamp`: 消息时间戳（ISO 8601格式）
- `payload`: 消息负载，根据类型不同而不同

## 消息类型

### 1. 心跳（Heartbeat）

**用途**: 保持连接活跃，检测连接状态

**客户端 -> 服务器 (PING)**:
```json
{
  "type": "ping",
  "id": "msg-001",
  "timestamp": "2025-11-27T10:30:00Z",
  "payload": {}
}
```

**服务器 -> 客户端 (PONG)**:
```json
{
  "type": "pong",
  "id": "msg-001",
  "timestamp": "2025-11-27T10:30:01Z",
  "payload": {
    "serverTime": "2025-11-27T10:30:01Z"
  }
}
```

**频率**: 客户端每30秒发送一次PING

### 2. 任务创建（Task Create）

**客户端 -> 服务器**:
```json
{
  "type": "task_create",
  "id": "msg-002",
  "timestamp": "2025-11-27T10:31:00Z",
  "payload": {
    "tempId": "temp-123",
    "task": {
      "title": "完成项目报告",
      "description": "准备Q4季度总结",
      "priority": "high",
      "dueDate": "2025-12-01T17:00:00Z",
      "createdAt": "2025-11-27T10:31:00Z"
    }
  }
}
```

**服务器 -> 客户端 (ACK)**:
```json
{
  "type": "task_create_ack",
  "id": "msg-002",
  "timestamp": "2025-11-27T10:31:01Z",
  "payload": {
    "tempId": "temp-123",
    "serverId": "task-5678",
    "status": "success"
  }
}
```

**错误响应**:
```json
{
  "type": "task_create_ack",
  "id": "msg-002",
  "timestamp": "2025-11-27T10:31:01Z",
  "payload": {
    "tempId": "temp-123",
    "status": "error",
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "任务标题不能为空"
    }
  }
}
```

### 3. 任务更新（Task Update）

**客户端 -> 服务器**:
```json
{
  "type": "task_update",
  "id": "msg-003",
  "timestamp": "2025-11-27T10:32:00Z",
  "payload": {
    "serverId": "task-5678",
    "changes": {
      "priority": "medium",
      "isCompleted": true,
      "completedAt": "2025-11-27T10:32:00Z"
    },
    "lastSyncedAt": "2025-11-27T10:31:01Z"
  }
}
```

**服务器 -> 客户端 (ACK)**:
```json
{
  "type": "task_update_ack",
  "id": "msg-003",
  "timestamp": "2025-11-27T10:32:01Z",
  "payload": {
    "serverId": "task-5678",
    "status": "success",
    "version": 2
  }
}
```

### 4. 任务删除（Task Delete）

**客户端 -> 服务器**:
```json
{
  "type": "task_delete",
  "id": "msg-004",
  "timestamp": "2025-11-27T10:33:00Z",
  "payload": {
    "serverId": "task-5678"
  }
}
```

**服务器 -> 客户端 (ACK)**:
```json
{
  "type": "task_delete_ack",
  "id": "msg-004",
  "timestamp": "2025-11-27T10:33:01Z",
  "payload": {
    "serverId": "task-5678",
    "status": "success"
  }
}
```

### 5. 服务器推送任务（Task Push）

**服务器 -> 客户端**:
```json
{
  "type": "task_push",
  "id": "msg-005",
  "timestamp": "2025-11-27T10:34:00Z",
  "payload": {
    "action": "create",
    "task": {
      "serverId": "task-9999",
      "title": "团队会议",
      "description": "讨论项目进度",
      "priority": "high",
      "dueDate": "2025-11-28T14:00:00Z",
      "createdAt": "2025-11-27T10:34:00Z",
      "source": "server"
    }
  }
}
```

**action字段**: `create`, `update`, `delete`

**客户端 -> 服务器 (ACK)**:
```json
{
  "type": "task_push_ack",
  "id": "msg-005",
  "timestamp": "2025-11-27T10:34:01Z",
  "payload": {
    "serverId": "task-9999",
    "status": "received"
  }
}
```

### 6. 批量同步（Batch Sync）

**客户端 -> 服务器（请求增量同步）**:
```json
{
  "type": "sync_request",
  "id": "msg-006",
  "timestamp": "2025-11-27T10:35:00Z",
  "payload": {
    "lastSyncedAt": "2025-11-27T09:00:00Z",
    "limit": 100
  }
}
```

**服务器 -> 客户端（返回变更）**:
```json
{
  "type": "sync_response",
  "id": "msg-006",
  "timestamp": "2025-11-27T10:35:01Z",
  "payload": {
    "tasks": [
      {
        "action": "create",
        "task": { /* task object */ }
      },
      {
        "action": "update",
        "serverId": "task-1234",
        "changes": { /* changed fields */ }
      },
      {
        "action": "delete",
        "serverId": "task-5555"
      }
    ],
    "hasMore": false,
    "nextCursor": null
  }
}
```

### 7. 连接状态（Connection Status）

**服务器 -> 客户端（连接建立后）**:
```json
{
  "type": "connected",
  "id": "msg-000",
  "timestamp": "2025-11-27T10:30:00Z",
  "payload": {
    "sessionId": "session-abc123",
    "deviceId": "device-xyz789",
    "serverVersion": "1.0.0"
  }
}
```

**服务器 -> 客户端（即将断开）**:
```json
{
  "type": "disconnect",
  "id": "msg-999",
  "timestamp": "2025-11-27T11:00:00Z",
  "payload": {
    "reason": "server_maintenance",
    "message": "服务器维护，将在5分钟后重新上线",
    "reconnectAfter": 300
  }
}
```

## 错误处理

### 错误码

| 错误码 | 说明 | 处理方式 |
|--------|------|---------|
| `VALIDATION_ERROR` | 数据验证失败 | 修正数据后重试 |
| `NOT_FOUND` | 任务不存在 | 从本地删除该任务 |
| `CONFLICT` | 数据冲突 | 执行冲突解决策略 |
| `RATE_LIMIT` | 请求频率过高 | 延迟后重试 |
| `UNAUTHORIZED` | 认证失败 | 重新认证 |
| `INTERNAL_ERROR` | 服务器内部错误 | 稍后重试 |

### 错误消息格式

```json
{
  "type": "error",
  "id": "msg-002",
  "timestamp": "2025-11-27T10:31:01Z",
  "payload": {
    "code": "VALIDATION_ERROR",
    "message": "任务标题不能为空",
    "details": {
      "field": "title",
      "constraint": "not_empty"
    }
  }
}
```

## 重连机制

### 客户端重连策略

1. **指数退避算法**:
   - 第1次重连：立即
   - 第2次重连：2秒后
   - 第3次重连：4秒后
   - 第4次重连：8秒后
   - 第5次重连：16秒后
   - 最大间隔：60秒

2. **重连时的数据同步**:
   ```dart
   Future<void> onReconnected() async {
     // 1. 发送sync_request获取断线期间的变更
     await sendSyncRequest(lastSyncedTimestamp);

     // 2. 上传本地未同步的变更
     final unsyncedTasks = await getUnsyncedTasks();
     for (final task in unsyncedTasks) {
       await sendTaskUpdate(task);
     }
   }
   ```

3. **最大重试次数**: 10次
   - 超过10次后，显示"连接失败"提示
   - 用户可手动触发重连

## 数据一致性

### 冲突解决

当客户端和服务器都修改了同一任务时：

1. **比较lastSyncedAt时间戳**
2. **最后写入胜出（Last Write Wins）**
3. **服务器响应冲突通知**:
   ```json
   {
     "type": "task_update_ack",
     "id": "msg-003",
     "timestamp": "2025-11-27T10:32:01Z",
     "payload": {
       "serverId": "task-5678",
       "status": "conflict",
       "serverVersion": {
         "title": "完成项目报告（修订版）",
         "lastSyncedAt": "2025-11-27T10:31:30Z"
       }
     }
   }
   ```
4. **客户端处理冲突**: 使用服务器版本覆盖本地

### 离线队列

当连接断开时，客户端缓存所有操作：

```dart
class OfflineQueue {
  final List<PendingOperation> _queue = [];

  void enqueue(PendingOperation op) {
    _queue.add(op);
    _persistQueue(); // 持久化到本地
  }

  Future<void> flush() async {
    for (final op in _queue) {
      await _sendOperation(op);
    }
    _queue.clear();
  }
}
```

## 性能优化

### 批量操作

一次性发送多个任务变更：

```json
{
  "type": "batch_operations",
  "id": "msg-010",
  "timestamp": "2025-11-27T10:40:00Z",
  "payload": {
    "operations": [
      {
        "type": "task_create",
        "tempId": "temp-201",
        "task": { /* task object */ }
      },
      {
        "type": "task_update",
        "serverId": "task-1234",
        "changes": { /* changes */ }
      }
    ]
  }
}
```

### 压缩

对于大量数据传输，使用gzip压缩：

```http
Sec-WebSocket-Extensions: permessage-deflate
```

## 安全性

### 认证

1. **设备ID认证**（当前版本）:
   - 客户端生成UUID作为设备ID
   - 握手时通过`X-Device-ID`头传递
   - 服务器为设备创建临时会话

2. **域账户认证**（未来版本）:
   - 获取Windows域账户或macOS系统账户
   - 使用JWT Token认证
   - 握手时通过`Authorization`头传递

### 数据加密

- 使用WSS（WebSocket Secure）协议
- 所有数据传输经过TLS 1.3加密

## 监控与调试

### 日志记录

客户端应记录：
- 所有发送和接收的消息（脱敏）
- 连接状态变更
- 错误和重连事件

```dart
void logMessage(String type, dynamic payload) {
  debugPrint('[WebSocket] ${DateTime.now()} $type: ${jsonEncode(payload)}');
}
```

### 性能指标

- 连接建立时间
- 消息往返时间（RTT）
- 重连次数和频率
- 离线队列大小

## 示例实现

### Dart/Flutter客户端

```dart
class TaskWebSocketService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  final _offlineQueue = OfflineQueue();

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://api.example.com/ws/tasks'),
        headers: {
          'X-Device-ID': await getDeviceId(),
          'X-Client-Version': '1.0.0',
        },
      );

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );

      _startHeartbeat();
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _sendPing();
    });
  }

  void _sendPing() {
    final message = {
      'type': 'ping',
      'id': Uuid().v4(),
      'timestamp': DateTime.now().toIso8601String(),
      'payload': {},
    };
    _channel?.sink.add(jsonEncode(message));
  }

  void _onMessage(dynamic data) {
    final message = jsonDecode(data);
    switch (message['type']) {
      case 'pong':
        // 心跳响应
        break;
      case 'task_push':
        _handleTaskPush(message['payload']);
        break;
      case 'task_create_ack':
        _handleCreateAck(message);
        break;
      // ... 处理其他消息类型
    }
  }

  Future<void> createTask(Task task) async {
    final message = {
      'type': 'task_create',
      'id': Uuid().v4(),
      'timestamp': DateTime.now().toIso8601String(),
      'payload': {
        'tempId': task.id.toString(),
        'task': task.toJson(),
      },
    };

    if (_isConnected) {
      _channel?.sink.add(jsonEncode(message));
    } else {
      _offlineQueue.enqueue(PendingOperation(message));
    }
  }
}
```

---

## 版本历史

- **v1.0.0** (2025-11-27): 初始版本，支持基础任务同步
