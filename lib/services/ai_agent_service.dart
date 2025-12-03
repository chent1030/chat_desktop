import 'package:isar/isar.dart';
import '../models/ai_agent.dart';
import 'storage_service.dart';
import 'agent_api_service.dart';

/// AI智能体管理服务 (缓存层)
/// 从后端API获取数据，缓存到本地Isar数据库
/// 支持离线使用和SSE实时同步
class AIAgentService {
  static AIAgentService? _instance;
  final StorageService _storageService;
  final AgentApiService _apiService;
  bool _isSSEConnected = false;

  AIAgentService._()
      : _storageService = StorageService.instance,
        _apiService = AgentApiService.instance;

  static AIAgentService get instance {
    _instance ??= AIAgentService._();
    return _instance!;
  }

  /// 获取Isar实例
  Isar get _isar => _storageService.isar;


  // ============================================
  // CRUD操作
  // ============================================

  /// 创建或更新AI智能体
  Future<int> saveAgent(AIAgent agent) async {
    agent.touch();

    await _isar.writeTxn(() async {
      await _isar.aIAgents.put(agent);
    });

    print('✓ AI智能体已保存: ${agent.name}');
    return agent.id;
  }

  /// 根据ID获取智能体
  Future<AIAgent?> getAgentById(int id) async {
    return await _isar.aIAgents.get(id);
  }

  /// 根据agentId获取智能体
  Future<AIAgent?> getAgentByAgentId(String agentId) async {
    return await _isar.aIAgents
        .filter()
        .agentIdEqualTo(agentId)
        .findFirst();
  }

  /// 获取所有启用的智能体
  /// 优先从API获取，失败则从本地缓存读取
  Future<List<AIAgent>> getEnabledAgents({bool forceCache = false}) async {
    if (forceCache) {
      // 强制从缓存读取
      return await _getEnabledAgentsFromCache();
    }

    try {
      // 尝试从API获取
      final agents = await _apiService.fetchEnabledAgents();

      // 更新到本地缓存
      await _isar.writeTxn(() async {
        // 先清空现有启用的智能体
        final existing = await _isar.aIAgents
            .filter()
            .isEnabledEqualTo(true)
            .findAll();
        for (final agent in existing) {
          await _isar.aIAgents.delete(agent.id);
        }
        // 插入新数据
        await _isar.aIAgents.putAll(agents);
      });

      print('✓ 已从API获取并缓存 ${agents.length} 个启用的智能体');
      return agents;
    } catch (e) {
      print('⚠️ 从API获取智能体失败，使用本地缓存: $e');
      return await _getEnabledAgentsFromCache();
    }
  }

  /// 从缓存获取启用的智能体
  Future<List<AIAgent>> _getEnabledAgentsFromCache() async {
    return await _isar.aIAgents
        .filter()
        .isEnabledEqualTo(true)
        .sortBySortOrder()
        .findAll();
  }

  /// 获取所有智能体
  /// 优先从API获取，失败则从本地缓存读取
  Future<List<AIAgent>> getAllAgents({bool forceCache = false}) async {
    if (forceCache) {
      // 强制从缓存读取
      return await _getAllAgentsFromCache();
    }

    try {
      // 尝试从API获取
      final agents = await _apiService.fetchAgents();

      // 更新到本地缓存
      await _isar.writeTxn(() async {
        await _isar.aIAgents.clear();
        await _isar.aIAgents.putAll(agents);
      });

      print('✓ 已从API获取并缓存 ${agents.length} 个智能体');
      return agents;
    } catch (e) {
      print('⚠️ 从API获取智能体失败，使用本地缓存: $e');
      return await _getAllAgentsFromCache();
    }
  }

  /// 从缓存获取所有智能体
  Future<List<AIAgent>> _getAllAgentsFromCache() async {
    return await _isar.aIAgents.where().sortBySortOrder().findAll();
  }

  /// 获取默认智能体
  Future<AIAgent?> getDefaultAgent() async {
    return await _isar.aIAgents
        .filter()
        .isDefaultEqualTo(true)
        .isEnabledEqualTo(true)
        .findFirst();
  }

  /// 删除智能体 (通过数据库ID)
  Future<void> deleteAgent(int id) async {
    await _isar.writeTxn(() async {
      await _isar.aIAgents.delete(id);
    });

    print('✓ AI智能体已删除: $id');
  }

  // ============================================
  // 客户端只读，不提供创建/更新/删除操作
  // 所有智能体管理由后端控制，客户端通过SSE同步
  // ============================================

  // ============================================
  // 智能体管理
  // ============================================

  /// 设置默认智能体
  Future<void> setDefaultAgent(String agentId) async {
    // 取消所有智能体的默认状态
    final allAgents = await getAllAgents();
    for (final agent in allAgents) {
      if (agent.isDefault) {
        agent.isDefault = false;
        await saveAgent(agent);
      }
    }

    // 设置新的默认智能体
    final newDefault = await getAgentByAgentId(agentId);
    if (newDefault != null) {
      newDefault.isDefault = true;
      await saveAgent(newDefault);
      print('✓ 默认智能体已设置: ${newDefault.name}');
    }
  }


  /// 通知智能体被使用
  /// 同时更新本地计数和通知后端（不阻塞）
  Future<void> incrementAgentMessageCount(String agentId) async {
    // 先更新本地缓存（立即生效）
    final agent = await getAgentByAgentId(agentId);
    if (agent != null) {
      agent.incrementMessageCount();
      await _isar.writeTxn(() async {
        await _isar.aIAgents.put(agent);
      });
    }

    // 异步通知后端（不阻塞，不抛异常）
    _apiService.notifyAgentUsed(agentId).catchError((e) {
      print('⚠️ 通知后端失败: $e');
    });
  }

  /// 更新智能体排序
  Future<void> updateAgentSortOrder(String agentId, int sortOrder) async {
    final agent = await getAgentByAgentId(agentId);
    if (agent == null) return;

    agent.sortOrder = sortOrder;
    await saveAgent(agent);
  }

  // ============================================
  // 初始化 - 从后端同步智能体列表
  // ============================================

  /// 初始化智能体列表（从后端获取）
  Future<void> initializeAgents() async {
    try {
      print('📡 正在从后端同步智能体列表...');

      // 从API获取并缓存
      final agents = await getEnabledAgents();

      if (agents.isEmpty) {
        print('⚠️ 后端暂无可用智能体');
      } else {
        print('✓ 已从后端同步 ${agents.length} 个智能体');
      }
    } catch (e) {
      print('❌ 初始化智能体失败: $e');
      print('⚠️ 将使用本地缓存数据');

      // 尝试从本地缓存加载
      final cachedAgents = await _getAllAgentsFromCache();
      if (cachedAgents.isNotEmpty) {
        print('✓ 已加载本地缓存的 ${cachedAgents.length} 个智能体');
      }
    }
  }

  // ============================================
  // 查询和统计
  // ============================================

  /// 获取智能体总数
  Future<int> getAgentCount() async {
    return await _isar.aIAgents.count();
  }

  /// 获取启用的智能体数量
  Future<int> getEnabledAgentCount() async {
    return await _isar.aIAgents
        .filter()
        .isEnabledEqualTo(true)
        .count();
  }

  /// 获取最常用的智能体
  Future<List<AIAgent>> getMostUsedAgents({int limit = 5}) async {
    return await _isar.aIAgents
        .filter()
        .isEnabledEqualTo(true)
        .sortByMessageCountDesc()
        .limit(limit)
        .findAll();
  }

  /// 获取最近使用的智能体
  Future<List<AIAgent>> getRecentlyUsedAgents({int limit = 5}) async {
    return await _isar.aIAgents
        .filter()
        .isEnabledEqualTo(true)
        .sortByLastUsedAtDesc()
        .limit(limit)
        .findAll();
  }

  // ============================================
  // 工具方法
  // ============================================

  /// 监听智能体变化
  Stream<void> watchAgents() {
    return _isar.aIAgents.watchLazy();
  }

  /// 监听特定智能体的变化
  Stream<AIAgent?> watchAgent(int agentId) {
    return _isar.aIAgents.watchObject(agentId);
  }

  /// 清空所有智能体 (用于测试)
  Future<void> clearAllAgents() async {
    await _isar.writeTxn(() async {
      await _isar.aIAgents.clear();
    });

    print('✓ 已清空所有AI智能体');
  }

}
