import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 应用程序通用常量定义
class AppConstants {
  // 应用信息
  static const String appName = '芯服务';
  static const String appVersion = '1.0.0';

  // 窗口配置
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;

  // 小窗口模式配置
  static const double miniWindowSize = 80;
  static const double miniWindowPadding = 16;
  static const double badgeSize = 20;

  // WebSocket配置
  static const int websocketHeartbeatInterval = 30; // 秒
  static const int websocketReconnectMaxAttempts = 10;
  static const List<int> websocketReconnectDelays = [0, 2, 4, 8, 16, 32, 60]; // 秒
  static const int websocketTimeout = 30; // 秒

  // AI服务配置
  static const int aiResponseTimeout = 60; // 秒
  static const int aiStreamTimeout = 120; // 秒
  static const double aiTemperatureDefault = 0.7;
  static const int aiMaxTokensDefault = 2000;

  // 数据库配置
  static const String isarDatabaseName = 'chat_desktop';
  static const bool isarInspectorEnabled = true; // 开发环境启用

  // 任务配置
  static const int taskListPageSize = 50;
  static const int taskTitleMaxLength = 200;
  static const int taskDescriptionMaxLength = 2000;

  // 对话配置
  static const int conversationHistoryLimit = 100;
  static const int messageMaxLength = 10000;
  static const int conversationTitleMaxLength = 100;

  // SharedPreferences键名
  static const String prefKeyLastUsedAgent = 'last_used_agent';
  static const String prefKeyWindowState = 'window_state';
  static const String prefKeyWindowPosition = 'window_position';
  static const String prefKeyWindowSize = 'window_size';
  static const String prefKeyMiniWindowPosition = 'mini_window_position';
  static const String prefKeyLastSeenTaskTimestamp = 'last_seen_task_timestamp';
  static const String prefKeyDeviceId = 'device_id';
  static const String prefKeyEmpNo = 'emp_no'; // 用户工号

  // 环境变量键名
  static const String envKeyOpenAIApiKey = 'OPENAI_API_KEY';
  static const String envKeyAnthropicApiKey = 'ANTHROPIC_API_KEY';
  static const String envKeyWebSocketUrl = 'WEBSOCKET_URL';
  static const String envKeyDeviceId = 'DEVICE_ID';
  static const String envKeyDifyApiUrl = 'DIFY_API_URL';
  static const String envKeyDifyApiKey = 'DIFY_API_KEY';

  // MQTT配置 (从环境变量读取)
  static String get mqttBrokerHost =>
      dotenv.env['MQTT_BROKER_HOST'] ?? 'localhost';
  static int get mqttBrokerPort =>
      int.tryParse(dotenv.env['MQTT_BROKER_PORT'] ?? '1883') ?? 1883;

  // API端点
  static const String openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String anthropicEndpoint = 'https://api.anthropic.com/v1/messages';

  // 预设AI智能体ID
  static const String agentIdGPT4 = 'gpt-4';
  static const String agentIdClaude3 = 'claude-3';

  // 任务排序选项
  static const String sortByCreatedAt = 'created_at';
  static const String sortByDueDate = 'due_date';
  static const String sortByPriority = 'priority';

  // 任务筛选选项
  static const String filterAll = 'all';
  static const String filterActive = 'active';
  static const String filterCompleted = 'completed';

  // 错误消息
  static const String errorNetworkUnavailable = '网络连接不可用';
  static const String errorWebSocketDisconnected = 'WebSocket连接已断开';
  static const String errorAIServiceTimeout = 'AI服务响应超时';
  static const String errorInvalidInput = '输入内容无效';
  static const String errorTaskNotFound = '任务不存在';
  static const String errorAgentNotFound = '智能体不存在';

  // 成功消���
  static const String successTaskCreated = '任务创建成功';
  static const String successTaskUpdated = '任务更新成功';
  static const String successTaskDeleted = '任务删除成功';
  static const String successTaskCompleted = '任务标记为已完成';

  // 动画配置
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // 防抖延迟
  static const Duration debounceDelay = Duration(milliseconds: 500);
}
