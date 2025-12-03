import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';
import '../models/task_action.dart';
import '../models/ai_agent.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../utils/constants.dart';

/// 本地存储服务 - 管理Isar数据库
class StorageService {
  static StorageService? _instance;
  Isar? _isar;
  bool _initialized = false;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// 获取Isar实例
  Isar get isar {
    if (_isar == null) {
      throw StateError('StorageService未初始化，请先调用initialize()');
    }
    return _isar!;
  }

  bool get isInitialized => _initialized;

  /// 初始化Isar数据库
  /// 注意：Schema列表将在数据模型创建后添加
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 获取应用文档目录
      final dir = await getApplicationDocumentsDirectory();

      // 打开Isar数据库
      // Schema列表: Task, TaskAction, AIAgent, Message, Conversation
      _isar = await Isar.open(
        [
          TaskSchema,
          TaskActionSchema,
          AIAgentSchema,
          MessageSchema,
          ConversationSchema,
        ],
        directory: dir.path,
        name: AppConstants.isarDatabaseName,
        inspector: AppConstants.isarInspectorEnabled,
      );

      // 初始化预设数据（如AI智能体）
      await _initializeDefaultData();

      _initialized = true;
      print('✓ StorageService初始化成功: ${dir.path}');
    } catch (e) {
      print('✗ StorageService初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化默认数据（预设AI智能体等）
  Future<void> _initializeDefaultData() async {
    // 检查是否已有AI智能体
    final existingAgents = await isar.aIAgents.count();
    if (existingAgents > 0) {
      print('✓ AI智能体已存在，跳过初始化');
      return;
    }

    // 添加预设智能体
    final presets = AIAgentPresets.getAllPresets();

    await isar.writeTxn(() async {
      for (final agent in presets) {
        await isar.aIAgents.put(agent);
      }
    });

    print('✓ 已初始化 ${presets.length} 个预设AI智能体');
  }

  /// 关闭数据库连接
  Future<void> dispose() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      _initialized = false;
      print('✓ StorageService已关闭');
    }
  }

  /// 清空所有数据（仅用于测试）
  Future<void> clearAllData() async {
    if (!_initialized) return;

    await isar.writeTxn(() async {
      await isar.clear();
    });

    print('✓ 所有数据已清空');
  }
}
