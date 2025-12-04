# EMQX连接配置指南

## 问题分析

错误信息：
```
mqtt-client::NoConnectionException: The maximum allowed connection attempts ({3}) were exceeded.
The broker is not responding to the connection request message (Missing Connection Acknowledgement?
```

这表示客户端发送了连接请求，但没有收到EMQX的CONNACK响应。

## 已修复的问题

### 1. 移除不完整的遗嘱消息配置
**之前：**
```dart
.withWillQos(MqttQos.atLeastOnce);  // 只设置QoS，缺少topic和payload
```

**现在：**
```dart
.keepAliveFor(60);  // 完整的keepAlive配置
```

### 2. 添加认证支持
- 新增用户名密码输入选项
- 支持匿名连接（不输入认证信息）

### 3. 开启日志调试
```dart
_client!.logging(on: true);  // 开启日志，查看详细连接过程
```

## 配置步骤

### 方案1：匿名连接（EMQX默认允许）

1. **检查EMQX配置**
   ```bash
   # 确认EMQX允许匿名连接
   # 编辑 etc/emqx.conf
   allow_anonymous = true
   ```

2. **运行应用**
   ```bash
   flutter run
   ```

3. **输入配置**
   - 工号：`123456`
   - **不要**勾选"MQTT需要认证"
   - 点击确认

### 方案2：使用认证（推荐）

1. **在EMQX中创建用户**
   ```bash
   # 通过EMQX Dashboard创建用户
   # 或使用CLI
   ./bin/emqx_ctl users add <username> <password>
   ```

2. **运行应用**
   ```bash
   flutter run
   ```

3. **输入配置**
   - 工号：`123456`
   - ✅ 勾选"MQTT需要认证"
   - MQTT用户名：`emqx_test`
   - MQTT密码：`emqx_test_password`
   - 点击确认

## 修改Broker地址

如果你的EMQX不在localhost，修改 `lib/utils/constants.dart`：

```dart
// MQTT配置
static const String mqttBrokerHost = '10.133.29.112';  // 你的EMQX地址
static const int mqttBrokerPort = 1883;
```

## 测试连接

### 1. 查看详细日志

运行应用后，控制台会显示详细的MQTT日志：
```
📡 [MQTT] 正在连接到 localhost:1883...
2025-12-04 12:00:00.000 -- MqttClient::connect
2025-12-04 12:00:00.100 -- MqttConnectionHandler::connect
2025-12-04 12:00:00.200 -- MqttConnection::_onData CONNACK
✓ [MQTT] 连接成功
```

### 2. 使用MQTTX验证配置

先用MQTTX测试相同的连接参数：
- Host: `localhost`
- Port: `1883`
- Client ID: `test_client`
- Username: `emqx_test`（如果需要）
- Password: `emqx_test_password`（如果需要）

如果MQTTX能连接，说明EMQX配置正确。

### 3. 常见问题排查

#### 问题1：连接超时
**原因：** EMQX未启动或防火墙阻止
**解决：**
```bash
# 检查EMQX状态
./bin/emqx status

# 检查端口监听
netstat -an | grep 1883

# 测试端口连通性
telnet localhost 1883
```

#### 问题2：认证失败
**原因：** 用户名密码错误
**解决：**
```bash
# 查看EMQX日志
tail -f log/emqx.log.1

# 检查认证配置
cat etc/plugins/emqx_auth_mnesia.conf
```

#### 问题3：协议版本不匹配
**原因：** EMQX只接受特定MQTT版本
**解决：** EMQX默认支持MQTT 3.1.1和5.0，mqtt_client默认使用3.1.1，应该没问题。

## 验证连接成功

连接成功后会看到：
```
✓ [MQTT] 连接成功
📬 [MQTT] 已订阅: mqtt_app/tasks/123456/#
✓ [MQTT] onConnected 回调触发
```

然后可以发送测试消息：
```bash
mosquitto_pub -h localhost -t "mqtt_app/tasks/123456/create" -m '{
  "action": "create",
  "timestamp": "2025-12-04 15:30:00",
  "task": {
    "uuid": "test-001",
    "title": "测试待办",
    "description": "EMQX推送测试",
    "priority": 2,
    "isCompleted": false,
    "createdAt": "2025-12-04 15:30:00",
    "updatedAt": "2025-12-04 15:30:00"
  }
}'
```

## EMQX Dashboard

访问EMQX Dashboard查看连接状态：
```
http://localhost:18083
默认账号: admin
默认密码: public
```

在Dashboard中可以看到：
- 客户端连接状态
- 订阅的Topic
- 消息发送接收统计

## 下一步

连接成功后，参考 `MQTT_TEST_GUIDE.md` 进行完整的功能测试。
