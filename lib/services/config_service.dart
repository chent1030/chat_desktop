import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

/// 环境配置管理服务
class ConfigService {
  static ConfigService? _instance;
  late final SharedPreferences _prefs;
  bool _initialized = false;

  ConfigService._();

  static ConfigService get instance {
    _instance ??= ConfigService._();
    return _instance!;
  }

  /// 初始化配置服务
  Future<void> initialize() async {
    if (_initialized) return;

    // 加载环境变量
    await dotenv.load(fileName: '.env');

    // 初始化SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // 确保设备ID存在
    await _ensureDeviceId();

    _initialized = true;
  }

  /// 确保设备ID存在
  Future<void> _ensureDeviceId() async {
    String? deviceId = _prefs.getString(AppConstants.prefKeyDeviceId);

    if (deviceId == null || deviceId.isEmpty) {
      // 尝试从环境变量获取
      deviceId = dotenv.env[AppConstants.envKeyDeviceId];

      if (deviceId == null || deviceId.isEmpty) {
        // 生成新的设备ID
        deviceId = const Uuid().v4();
      }

      // 保存到SharedPreferences
      await _prefs.setString(AppConstants.prefKeyDeviceId, deviceId);
    }
  }

  /// 获取设备ID
  String get deviceId {
    return _prefs.getString(AppConstants.prefKeyDeviceId) ?? '';
  }

  /// 获取OpenAI API密钥
  String? get openAIApiKey {
    return dotenv.env[AppConstants.envKeyOpenAIApiKey];
  }

  /// 获取Anthropic API密钥
  String? get anthropicApiKey {
    return dotenv.env[AppConstants.envKeyAnthropicApiKey];
  }

  /// 获取WebSocket URL
  String? get webSocketUrl {
    return dotenv.env[AppConstants.envKeyWebSocketUrl];
  }

  /// 检查API密钥是否已配置
  bool get hasOpenAIKey {
    final key = openAIApiKey;
    return key != null && key.isNotEmpty;
  }

  bool get hasAnthropicKey {
    final key = anthropicApiKey;
    return key != null && key.isNotEmpty;
  }

  bool get hasWebSocketUrl {
    final url = webSocketUrl;
    return url != null && url.isNotEmpty;
  }

  /// 获取上次使用的智能体ID
  String? get lastUsedAgentId {
    return _prefs.getString(AppConstants.prefKeyLastUsedAgent);
  }

  /// 设置上次使用的智能体ID
  Future<void> setLastUsedAgentId(String agentId) async {
    await _prefs.setString(AppConstants.prefKeyLastUsedAgent, agentId);
  }

  /// 获取窗口状态
  String? get windowState {
    return _prefs.getString(AppConstants.prefKeyWindowState);
  }

  /// 设置窗口状态
  Future<void> setWindowState(String state) async {
    await _prefs.setString(AppConstants.prefKeyWindowState, state);
  }

  /// 获取窗口位置
  Map<String, double>? get windowPosition {
    final x = _prefs.getDouble('${AppConstants.prefKeyWindowPosition}_x');
    final y = _prefs.getDouble('${AppConstants.prefKeyWindowPosition}_y');

    if (x != null && y != null) {
      return {'x': x, 'y': y};
    }
    return null;
  }

  /// 设置窗口位置
  Future<void> setWindowPosition(double x, double y) async {
    await _prefs.setDouble('${AppConstants.prefKeyWindowPosition}_x', x);
    await _prefs.setDouble('${AppConstants.prefKeyWindowPosition}_y', y);
  }

  /// 获取窗口大小
  Map<String, double>? get windowSize {
    final width = _prefs.getDouble('${AppConstants.prefKeyWindowSize}_width');
    final height =
        _prefs.getDouble('${AppConstants.prefKeyWindowSize}_height');

    if (width != null && height != null) {
      return {'width': width, 'height': height};
    }
    return null;
  }

  /// 设置窗口大小
  Future<void> setWindowSize(double width, double height) async {
    await _prefs.setDouble('${AppConstants.prefKeyWindowSize}_width', width);
    await _prefs.setDouble('${AppConstants.prefKeyWindowSize}_height', height);
  }

  /// 获取小窗口位置
  Map<String, double>? get miniWindowPosition {
    final x =
        _prefs.getDouble('${AppConstants.prefKeyMiniWindowPosition}_x');
    final y =
        _prefs.getDouble('${AppConstants.prefKeyMiniWindowPosition}_y');

    if (x != null && y != null) {
      return {'x': x, 'y': y};
    }
    return null;
  }

  /// 设置小窗口位置
  Future<void> setMiniWindowPosition(double x, double y) async {
    await _prefs.setDouble('${AppConstants.prefKeyMiniWindowPosition}_x', x);
    await _prefs.setDouble('${AppConstants.prefKeyMiniWindowPosition}_y', y);
  }

  /// 获取最后查看任务的时间戳
  DateTime get lastSeenTaskTimestamp {
    final timestamp =
        _prefs.getInt(AppConstants.prefKeyLastSeenTaskTimestamp) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 更新最后查看任务的时间戳
  Future<void> updateLastSeenTaskTimestamp() async {
    await _prefs.setInt(
      AppConstants.prefKeyLastSeenTaskTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 清除所有配置（用于测试或重置）
  Future<void> clearAll() async {
    await _prefs.clear();
    await _ensureDeviceId();
  }
}
