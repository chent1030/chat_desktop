import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env` 配置统一管理
///
/// 目标：
/// - 所有业务代码不要直接读 `dotenv.env[...]`，统一从这里取，便于改名/加默认值/做校验。
/// - 变量名在这里集中管理，避免散落在各处导致配置不一致。
class EnvConfig {
  // ===== 全局调试开关 =====
  static const String keyDebug = 'DEBUG';

  // ===== Unify API（任务相关） =====
  static const String keyUnifyApiBaseUrl = 'UNIFY_API_BASE_URL';
  static const String keyUnifyCreateTaskPath = 'UNIFY_API_CREATE_TASK_PATH';
  static const String keyUnifyTaskReadPath = 'UNIFY_API_TASK_READ_PATH';
  static const String keyUnifyTaskCompletePath = 'UNIFY_API_TASK_COMPLETE_PATH';
  static const String keyUnifyTaskListPath = 'UNIFY_API_TASK_LIST_PATH';
  static const String keyUnifyDispatchCandidatesPath =
      'UNIFY_API_DISPATCH_CANDIDATES_PATH';
  static const String keyUnifyEmpNoCheckPath = 'UNIFY_API_EMP_NO_CHECK_PATH';

  // ===== 通用 HTTP 客户端（旧/通用后端）=====
  static const String keyApiBaseUrl = 'API_BASE_URL';
  static const String keyApiToken = 'API_TOKEN';

  // ===== AI（聊天/抽取）=====
  static const String keyAiApiUrl = 'AI_API_URL';
  static const String keyAiSseUrl = 'AI_SSE_URL';
  static const String keyAiApiKey = 'AI_API_KEY';
  static const String keyAiApiKeyXinService = 'AI_API_KEY_XIN_SERVICE';
  static const String keyAiApiKeyLocalQa = 'AI_API_KEY_LOCAL_QA';

  static const String keyAiApiKeyTaskExtract = 'AI_API_KEY_TASK_EXTRACT';
  static const String keyAiApiUrlTaskExtract = 'AI_API_URL_TASK_EXTRACT';
  static const String keyAiSseUrlTaskExtract = 'AI_SSE_URL_TASK_EXTRACT';

  // ===== MQTT =====
  static const String keyMqttBrokerHost = 'MQTT_BROKER_HOST';
  static const String keyMqttBrokerPort = 'MQTT_BROKER_PORT';
  static const String keyMqttUsername = 'MQTT_USERNAME';
  static const String keyMqttPassword = 'MQTT_PASSWORD';
  static const String keyMqttSessionExpirySeconds = 'MQTT_SESSION_EXPIRY_SECONDS';
  static const String keyMqttTopics = 'MQTT_TOPICS';

  // ===== 其他 =====
  static const String keyDeviceId = 'DEVICE_ID';
  static const String keyWebSocketUrl = 'WEBSOCKET_URL';
  static const String keyOutlookPathWindows = 'OUTLOOK_PATH_WINDOWS';
  static const String keyDingTalkPathWindows = 'DINGTALK_PATH_WINDOWS';
  static const String keyOpenAiApiKey = 'OPENAI_API_KEY';
  static const String keyAnthropicApiKey = 'ANTHROPIC_API_KEY';

  static String _getString(String key, {String defaultValue = ''}) {
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    final trimmed = value.trim();
    return trimmed.isEmpty ? defaultValue : trimmed;
  }

  static String? _getNullableString(String key) {
    final value = dotenv.env[key];
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _getInt(String key, {required int defaultValue}) {
    final raw = _getString(key);
    return int.tryParse(raw) ?? defaultValue;
  }

  static bool _getBool(String key, {bool defaultValue = false}) {
    final raw = _getString(key).toLowerCase();
    if (raw.isEmpty) return defaultValue;
    return raw == 'true' || raw == '1' || raw == 'yes' || raw == 'y';
  }

  /// 是否启用调试模式：Unify 接口全部使用 Mock 数据
  static bool get debug => _getBool(keyDebug, defaultValue: false);

  /// 重新加载 `.env`（用于运行时切换 DEBUG 等配置）
  static Future<void> reload() async {
    await dotenv.load(fileName: '.env');
  }

  // ===== Unify API（任务相关）=====
  static String get unifyApiBaseUrl => _getString(
        keyUnifyApiBaseUrl,
        defaultValue: 'https://cshzeroapi.uabcbattery.com/unify/v1/0',
      );

  static String get unifyCreateTaskPath => _getString(keyUnifyCreateTaskPath);

  static String get unifyTaskReadPath => _getString(keyUnifyTaskReadPath);

  static String get unifyTaskCompletePath =>
      _getString(keyUnifyTaskCompletePath);

  static String get unifyTaskListPath => _getString(keyUnifyTaskListPath);

  static String get unifyDispatchCandidatesPath =>
      _getString(keyUnifyDispatchCandidatesPath);

  static String get unifyEmpNoCheckPath => _getString(keyUnifyEmpNoCheckPath);

  // ===== 通用 HTTP 客户端（旧/通用后端）=====
  static String get apiBaseUrl =>
      _getString(keyApiBaseUrl, defaultValue: 'http://localhost:3000');

  static String? get apiToken => _getNullableString(keyApiToken);

  // ===== AI（聊天/抽取）=====
  static String get aiApiUrl => _getString(keyAiApiUrl);

  static String? get aiSseUrl => _getNullableString(keyAiSseUrl);

  static String get aiApiKey => _getString(keyAiApiKey);

  static String get aiApiKeyXinService =>
      _getString(keyAiApiKeyXinService, defaultValue: aiApiKey);

  static String get aiApiKeyLocalQa =>
      _getString(keyAiApiKeyLocalQa, defaultValue: aiApiKey);

  static String get aiTaskExtractApiUrl =>
      _getString(keyAiApiUrlTaskExtract, defaultValue: aiApiUrl);

  static String? get aiTaskExtractSseUrl =>
      _getNullableString(keyAiSseUrlTaskExtract) ?? aiSseUrl;

  static String get aiTaskExtractApiKey => _getString(keyAiApiKeyTaskExtract);

  // ===== MQTT =====
  static String get mqttBrokerHost =>
      _getString(keyMqttBrokerHost, defaultValue: 'localhost');

  static int get mqttBrokerPort => _getInt(keyMqttBrokerPort, defaultValue: 1883);

  static String? get mqttUsername => _getNullableString(keyMqttUsername);

  static String? get mqttPassword => _getNullableString(keyMqttPassword);

  static int get mqttSessionExpirySeconds =>
      _getInt(keyMqttSessionExpirySeconds, defaultValue: 0);

  static String get mqttTopicsRaw => _getString(keyMqttTopics);

  // ===== 其他 =====
  static String? get deviceId => _getNullableString(keyDeviceId);

  static String? get webSocketUrl => _getNullableString(keyWebSocketUrl);

  static String? get outlookPathWindows =>
      _getNullableString(keyOutlookPathWindows);

  static String? get dingTalkPathWindows =>
      _getNullableString(keyDingTalkPathWindows);

  static String? get openAIApiKey => _getNullableString(keyOpenAiApiKey);

  static String? get anthropicApiKey => _getNullableString(keyAnthropicApiKey);
}
