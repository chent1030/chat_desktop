# MQTT环境变量配置说明

## 配置方式

MQTT连接配置通过`.env`环境变量文件管理，便于在不同环境下快速切换配置。

## 配置步骤

### 1. 编辑.env文件

项目根目录下的`.env`文件包含以下MQTT配置：

```env
# MQTT配置
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
```

### 2. 修改配置

根据实际EMQX服务器地址修改：

**本地开发环境：**
```env
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
```

**远程服务器：**
```env
MQTT_BROKER_HOST=10.133.29.112
MQTT_BROKER_PORT=1883
```

**自定义端口：**
```env
MQTT_BROKER_HOST=mqtt.example.com
MQTT_BROKER_PORT=8883
```

### 3. 重启应用

修改`.env`文件后，**必须重新启动应用**才能生效。热重载不会重新加载环境变量。

```bash
# 停止应用后重新运行
flutter run
```

## 配置验证

应用启动时会在控制台输出环境变量加载状态：

```
✓ 环境变量加载成功
✓ ConfigService初始化成功
✓ StorageService初始化成功
```

如果MQTT连接使用了正确的配置，会看到：

```
📡 [MQTT] 正在连接到 localhost:1883...
✓ [MQTT] 连接成功
```

## 配置文件说明

- **`.env`** - 实际使用的配置文件（不提交到Git，包含敏感信息）
- **`.env.example`** - 配置模板文件（提交到Git，供团队参考）

## 其他环境变量

`.env`文件还包含其他配置：

```env
# AI服务API密钥
AI_API_URL=https://your-api-server.com/api/chat
AI_API_KEY=your-api-key-here

# WebSocket服务端点
WEBSOCKET_URL=wss://api.example.com/ws/tasks

# MQTT配置
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883

# 设备ID（首次启动时自动生成）
DEVICE_ID=
```

## 常见问题

### Q: 修改.env后为什么没有生效？
A: 必须完全重启应用，热重载不会重新加载环境变量。

### Q: 如何查看当前使用的配置？
A: 在代码中打印：
```dart
print('MQTT Host: ${AppConstants.mqttBrokerHost}');
print('MQTT Port: ${AppConstants.mqttBrokerPort}');
```

### Q: .env文件丢失怎么办？
A: 复制`.env.example`为`.env`，然后根据实际情况修改配置。

### Q: 团队协作如何管理配置？
A:
- 每个开发者维护自己的`.env`文件（不提交到Git）
- 通过`.env.example`共享配置模板
- 在团队文档中说明各环境的配置值

## 代码实现

配置在代码中的使用方式：

```dart
// lib/utils/constants.dart
static String get mqttBrokerHost =>
    dotenv.env['MQTT_BROKER_HOST'] ?? 'localhost';
static int get mqttBrokerPort =>
    int.tryParse(dotenv.env['MQTT_BROKER_PORT'] ?? '1883') ?? 1883;

// 使用示例
await _mqttService.connect(
  broker: AppConstants.mqttBrokerHost,  // 从.env读取
  port: AppConstants.mqttBrokerPort,     // 从.env读取
  empNo: empNo,
);
```

## 参考文档

- [EMQX连接配置指南](./EMQX_CONFIG.md)
- [MQTT测试指南](./MQTT_TEST_GUIDE.md)
