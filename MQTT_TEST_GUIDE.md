# MQTT功能测试指南

## 概述

本项目已成功集成MQTT待办事项同步功能，支持：
- ✅ 接收后端推送的待办事项
- ✅ 发布待办事项给其他用户
- ✅ UUID去重机制
- ✅ 系统通知提醒
- ✅ 断线自动重连

---

## 一、启动MQTT Broker

### 1. 使用Docker快速启动（推荐）

```bash
docker run -d --name mosquitto \
  -p 1883:1883 \
  -p 9001:9001 \
  eclipse-mosquitto:latest
```

### 2. 本地安装Mosquitto

**macOS:**
```bash
brew install mosquitto
brew services start mosquitto
```

**Ubuntu/Debian:**
```bash
sudo apt-get install mosquitto mosquitto-clients
sudo systemctl start mosquitto
```

**Windows:**
下载安装包：https://mosquitto.org/download/

---

## 二、运行应用

### 1. 启动应用
```bash
flutter run
```

### 2. 首次启动 - 输入工号
- 应用启动后会弹出"输入工号"弹窗
- 输入工号（例如：`123456`）
- 点击"确认"
- 应用将自动连接到 `localhost:1883`

### 3. 查看日志
观察控制台输出，确认MQTT连接成功：
```
📡 [MQTT] 正在连接到 localhost:1883...
✓ [MQTT] 连接成功
📬 [MQTT] 已订阅: mqtt_app/tasks/123456/#
✓ [MQTT] onConnected 回调触发
```

---

## 三、测试MQTT功能

### 测试1：接收创建待办消息

使用MQTT客户端发布消息：

```bash
mosquitto_pub -h localhost -t "mqtt_app/tasks/123456/create" -m '{
  "action": "create",
  "timestamp": "2025-12-04 15:30:00",
  "task": {
    "uuid": "test-uuid-001",
    "title": "测试待办事项",
    "description": "这是通过MQTT推送的待办",
    "priority": 2,
    "dueDate": "2025-12-06 18:00:00",
    "tags": "测试,MQTT",
    "source": 1,
    "createdByAgentId": "backend_system",
    "isCompleted": false,
    "createdAt": "2025-12-04 15:30:00",
    "updatedAt": "2025-12-04 15:30:00"
  }
}'
```

**预期结果：**
- ✅ 应用收到消息并创建待办
- ✅ 待办列表显示新任务
- ✅ 系统弹出通知："新待办事项 - 测试待办事项"

### 测试2：接收更新待办消息

```bash
mosquitto_pub -h localhost -t "mqtt_app/tasks/123456/update" -m '{
  "action": "update",
  "timestamp": "2025-12-04 16:00:00",
  "uuid": "test-uuid-001",
  "changes": {
    "title": "更新后的标题",
    "priority": 0,
    "description": "描述已更新"
  }
}'
```

**预期结果：**
- ✅ 待办标题和优先级被更新
- ✅ 系统弹出通知："待办已更新 - 更新后的标题"

### 测试3：接收完成待办消息

```bash
mosquitto_pub -h localhost -t "mqtt_app/tasks/123456/complete" -m '{
  "action": "complete",
  "timestamp": "2025-12-04 17:00:00",
  "uuid": "test-uuid-001",
  "isCompleted": true
}'
```

**预期结果：**
- ✅ 待办标记为已完成
- ✅ 系统弹出通知："待办已完成 - 更新后的标题"

### 测试4：接收删除待办消息

```bash
mosquitto_pub -h localhost -t "mqtt_app/tasks/123456/delete" -m '{
  "action": "delete",
  "timestamp": "2025-12-04 18:00:00",
  "uuid": "test-uuid-001"
}'
```

**预期结果：**
- ✅ 待办从列表中删除
- ✅ 系统弹出通知："待办已删除 - 更新后的标题"

### 测试5：UUID去重测试

再次发送相同UUID的创建消息：

```bash
mosquitto_pub -h localhost -t "mqtt_app/tasks/123456/create" -m '{
  "action": "create",
  "timestamp": "2025-12-04 19:00:00",
  "task": {
    "uuid": "test-uuid-001",
    "title": "重复的待办",
    "description": "这条消息应该被忽略",
    "priority": 1,
    "isCompleted": false,
    "createdAt": "2025-12-04 19:00:00",
    "updatedAt": "2025-12-04 19:00:00"
  }
}'
```

**预期结果：**
- ✅ 控制台输出：`⚠️ [MQTT] 任务已存在，跳过创建 (UUID: test-uuid-001)`
- ✅ 不创建重复待办

---

## 四、测试客户端发布功能

### 方法1：通过代码调用MqttService

在应用中添加测试按钮或调用：

```dart
final mqttService = MqttService.instance;
final task = Task(
  title: "发送给同事的待办",
  description: "请帮忙审核文档",
  priority: Priority.high,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 发送给工号为654321的用户
await mqttService.publishCreateTask(
  targetEmpNo: "654321",
  task: task,
);
```

### 方法2：订阅其他用户的Topic进行测试

在另一个终端订阅：

```bash
mosquitto_sub -h localhost -t "mqtt_app/tasks/654321/#" -v
```

然后通过应用发布消息，观察订阅者是否收到。

---

## 五、监控MQTT流量

### 订阅所有消息（调试用）

```bash
mosquitto_sub -h localhost -t "mqtt_app/tasks/#" -v
```

这将显示所有用户的所有待办消息，方便调试。

---

## 六、常见问题

### 1. 连接失败
**问题：** `❌ [MQTT] 连接异常`

**解决方案：**
- 确认MQTT Broker已启动：`telnet localhost 1883`
- 检查防火墙设置
- 确认broker地址和端口正确

### 2. 消息未收到
**问题：** 发送消息后应用无反应

**解决方案：**
- 检查Topic是否正确（工号是否匹配）
- 确认JSON格式正确（使用在线JSON验证器）
- 查看应用控制台是否有错误日志

### 3. 通知未显示
**问题：** 待办创建成功但没有通知

**解决方案：**
- macOS: 系统偏好设置 → 通知 → 允许应用通知
- Windows: 设置 → 系统 → 通知 → 允许应用通知

### 4. 重复连接
**问题：** 每次启动都要输入工号

**解决方案：**
- 工号已保存在SharedPreferences中
- 如需重置，删除应用数据或调用 `ConfigService.instance.clearEmpNo()`

---

## 七、后端集成示例

### Node.js 后端推送示例

```javascript
const mqtt = require('mqtt');
const client = mqtt.connect('mqtt://localhost:1883');

client.on('connect', () => {
  console.log('MQTT连接成功');

  // 推送待办给工号123456的用户
  const message = {
    action: 'create',
    timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
    task: {
      uuid: `task-${Date.now()}`,
      title: '后端推送的任务',
      description: '请完成本周报告',
      priority: 2,
      dueDate: '2025-12-10 18:00:00',
      tags: '工作,紧急',
      source: 1,
      createdByAgentId: 'backend_system',
      isCompleted: false,
      createdAt: new Date().toISOString().replace('T', ' ').substring(0, 19),
      updatedAt: new Date().toISOString().replace('T', ' ').substring(0, 19),
    }
  };

  client.publish('mqtt_app/tasks/123456/create', JSON.stringify(message));
  console.log('消息已发送');
});
```

---

## 八、Topic命名规范

```
个人待办：
  mqtt_app/tasks/{empNo}/create
  mqtt_app/tasks/{empNo}/update
  mqtt_app/tasks/{empNo}/delete
  mqtt_app/tasks/{empNo}/complete

团队待办（未来扩展）：
  mqtt_app/tasks/team/{teamId}/create
  mqtt_app/tasks/team/{teamId}/update
  mqtt_app/tasks/team/{teamId}/delete
  mqtt_app/tasks/team/{teamId}/complete
```

---

## 九、开发配置

### 修改MQTT Broker地址

编辑 `lib/utils/constants.dart`:

```dart
// MQTT配置
static const String mqttBrokerHost = 'your-broker.com';  // 修改为实际地址
static const int mqttBrokerPort = 1883;
```

### 添加认证

编辑 `lib/widgets/common/emp_no_dialog.dart`，在连接时添加用户名和密码：

```dart
await _mqttService.connect(
  broker: AppConstants.mqttBrokerHost,
  port: AppConstants.mqttBrokerPort,
  empNo: empNo,
  username: 'your_username',  // 添加
  password: 'your_password',  // 添加
);
```

---

Topic规则总结

  | 操作   | Topic格式                        | 说明         |
  |------|--------------------------------|------------|
  | 创建待办 | mqtt_app/tasks/{目标工号}/create   | 给指定工号推送新待办 |
  | 更新待办 | mqtt_app/tasks/{目标工号}/update   | 更新指定工号的待办  |
  | 删除待办 | mqtt_app/tasks/{目标工号}/delete   | 删除指定工号的待办  |
  | 完成待办 | mqtt_app/tasks/{目标工号}/complete | 标记待办为完成    |

  实际示例

  场景1：项目经理给团队成员分配任务

  # 给张三(工号123456)分配任务
  mosquitto_pub -h localhost -t "mqtt_app/tasks/123456/create" -m '{...}'

  # 给李四(工号654321)分配任务
  mosquitto_pub -h localhost -t "mqtt_app/tasks/654321/create" -m '{...}'

  # 给王五(工号789012)分配任务
  mosquitto_pub -h localhost -t "mqtt_app/tasks/789012/create" -m '{...}'

---

## 十、下一步计划

- [ ] 添加团队待办功能
- [ ] 实现待办冲突解决机制
- [ ] 添加MQTT消息队列持久化
- [ ] 支持TLS/SSL加密连接
- [ ] 添加离线消息缓存

---

## 技术支持

如有问题，请查看：
- MqttService代码：`lib/services/mqtt_service.dart`
- Task模型定义：`lib/models/task.dart`
- 工号配置：`lib/services/config_service.dart`

**祝测试顺利！** 🎉
