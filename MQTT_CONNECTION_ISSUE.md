# MQTT连接频繁断开问题排查

## 问题现象

MQTT连接成功后仅维持5秒就断开，然后自动重连，形成循环。

```
✓ [MQTT] 连接成功
✓ [MQTT] 订阅成功
... (约5秒后)
⚠️ [MQTT] onDisconnected 回调触发
🔄 [MQTT] 将在5秒后尝试重连...
```

## 诊断步骤

### 1. 检查EMQX服务器状态

```bash
# 方法1: 检查进程
ps aux | grep emqx

# 方法2: 检查端口占用
lsof -i :1883
# 或
netstat -an | grep 1883

# 方法3: 如果使用Docker
docker ps | grep emqx
docker logs emqx
```

**期望结果**: 应该看到EMQX进程在运行，端口1883被监听。

### 2. 查看EMQX日志

```bash
# 查看EMQX日志（根据实际安装路径调整）
tail -f /opt/emqx/log/emqx.log.1

# 或Docker方式
docker logs -f emqx
```

**关注内容**:
- 客户端连接和断开记录
- 是否有错误或警告
- 是否有"kickout"、"conflict"等关键词

### 3. 测试基本连接

使用MQTTX客户端测试：

```
Host: localhost
Port: 1883
Client ID: test_client_123
```

**观察**: 如果MQTTX也频繁断开，说明是EMQX问题；如果MQTTX正常，说明是应用配置问题。

### 4. 检查客户端ID冲突

你的客户端ID: `chat_desktop_61016968`

**问题**: 如果同时运行多个应用实例，EMQX会踢掉旧连接。

**验证**:
```bash
# 检查是否有多个chat_desktop进程
ps aux | grep chat_desktop
```

**解决**: 只保留一个应用实例运行。

### 5. 检查EMQX Dashboard

访问 EMQX Dashboard:
```
http://localhost:18083
默认账号: admin
默认密码: public
```

查看:
- **连接管理**: 查看客户端连接状态
- **日志**: 查看详细的连接/断开记录
- **配置**: 检查是否有连接限制

## 常见原因和解决方案

### 原因1: EMQX未启动

**症状**: 能建立TCP连接，但立即断开

**解决**:
```bash
# 启动EMQX
./bin/emqx start

# 或Docker方式
docker start emqx
# 或
docker run -d --name emqx -p 1883:1883 -p 18083:18083 emqx/emqx:latest
```

**验证**:
```bash
./bin/emqx status
# 应该显示: Node 'emqx@127.0.0.1' is started
```

### 原因2: 客户端ID冲突

**症状**: 连接5秒后被踢掉，日志中显示"kickout"

**解决**: 修改客户端ID生成逻辑，添加随机后缀

```dart
// lib/services/mqtt_service.dart
final clientId = 'chat_desktop_${empNo}_${DateTime.now().millisecondsSinceEpoch}';
_client = MqttServerClient(broker, clientId);
```

### 原因3: EMQX配置限制

**症状**: 连接后立即断开，无明显错误

**检查配置**: `etc/emqx.conf`
```conf
# 检查这些配置
zone.external.idle_timeout = 15s  # 如果太短会导致断连
zone.external.max_connections = 1024000
```

**解决**: 调整配置后重启EMQX
```bash
./bin/emqx restart
```

### 原因4: 防火墙或网络问题

**症状**: 间歇性断开

**检查**:
```bash
# 测试端口连通性
telnet localhost 1883

# 检查防火墙规则
sudo iptables -L -n | grep 1883  # Linux
# 或检查macOS防火墙设置
```

## 调试技巧

### 1. 启用详细日志

已在代码中启用:
```dart
_client!.logging(on: true);
```

### 2. 监控EMQX指标

在EMQX Dashboard中查看:
- 连接数变化
- 消息流量
- 断连原因统计

### 3. 使用Wireshark抓包

```bash
# 抓取localhost的MQTT流量
sudo tcpdump -i lo0 port 1883 -w mqtt.pcap
```

分析是否有异常的断连包。

## 临时解决方案

如果EMQX确实有问题但暂时无法解决，可以：

### 方案1: 增加重连间隔

```dart
// lib/services/mqtt_service.dart
_reconnectTimer = Timer(const Duration(seconds: 10), () async {
  // 从5秒改为10秒
```

### 方案2: 添加重连次数限制

```dart
int _reconnectAttempts = 0;
final maxReconnectAttempts = 5;

void _scheduleReconnect() {
  if (_reconnectAttempts >= maxReconnectAttempts) {
    print('❌ [MQTT] 达到最大重连次数，停止重连');
    return;
  }
  _reconnectAttempts++;
  // ... 重连逻辑
}

void _onConnected() {
  _reconnectAttempts = 0; // 重置计数
  // ...
}
```

## 验证修复

修复后，正常日志应该是：

```
✓ [MQTT] 连接成功
✓ [MQTT] 订阅成功: mqtt_app/tasks/61016968/#
... (保持连接，不断开)
```

如果需要发送心跳，应该看到PING/PONG日志（60秒间隔）：

```
-- MqttConnectionKeepAlive::_sendPing
-- MqttConnectionKeepAlive::_pongReceived
```

## 推荐配置

### EMQX配置 (etc/emqx.conf)

```conf
# 连接空闲超时（默认15秒太短）
zone.external.idle_timeout = 60s

# 心跳倍数（2倍keepAlive时间）
zone.external.keepalive_backoff = 0.75

# 允许匿名连接（开发环境）
allow_anonymous = true

# 最大连接数
zone.external.max_connections = 102400
```

### 客户端配置优化

```dart
_client!.keepAlivePeriod = 60;
_client!.autoReconnect = false; // 手动控制更可靠

// 添加连接超时
_client!.connectTimeoutPeriod = 5000; // 5秒超时
```

## 常见问题

### Q: 为什么只维持5秒？
A: 5秒可能是EMQX的默认idle_timeout或者服务器主动断开。

### Q: 重连会影响功能吗？
A: 重连期间无法接收MQTT消息，但本地功能不受影响。

### Q: 如何永久解决？
A: 确保EMQX正常运行，配置合理的超时时间，避免客户端ID冲突。

### Q: 可以禁用自动重连吗？
A: 可以，但不推荐。自动重连能保证网络恢复后自动连接。

## 联系支持

如果以上方法都无法解决，请提供：
1. 完整的MQTT日志
2. EMQX日志
3. EMQX版本和配置
4. 网络环境信息

---

**快速检查命令**:
```bash
# 一键检查EMQX状态
ps aux | grep emqx && lsof -i :1883 && curl -s http://localhost:18083 > /dev/null && echo "EMQX运行正常" || echo "EMQX可能未运行"
```
