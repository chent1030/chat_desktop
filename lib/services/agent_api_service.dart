import '../models/ai_agent.dart';
import 'http_client.dart';

/// 智能体API服务
/// 负责从后端API获取智能体数据（列表、详情等）
class AgentApiService {
  static AgentApiService? _instance;
  final HttpClient _httpClient;

  AgentApiService._() : _httpClient = HttpClient.instance;

  static AgentApiService get instance {
    _instance ??= AgentApiService._();
    return _instance!;
  }

  // ============================================
  // HTTP API 请求方法
  // ============================================

  /// 获取所有智能体列表
  Future<List<AIAgent>> fetchAgents() async {
    try {
      print('📡 [AgentAPI] 获取智能体列表');

      final response = await _httpClient.get('/api/agents');

      if (response.data is List) {
        final agents = (response.data as List)
            .map((json) => AIAgent.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✓ [AgentAPI] 获取到 ${agents.length} 个智能体');
        return agents;
      }

      throw Exception('无效的响应数据格式');
    } catch (e) {
      print('❌ [AgentAPI] 获取智能体列表失败: $e');
      rethrow;
    }
  }

  /// 获取启用的智能体列表
  Future<List<AIAgent>> fetchEnabledAgents() async {
    try {
      print('📡 [AgentAPI] 获取启用的智能体列表');

      final response = await _httpClient.get('/api/agents', queryParameters: {
        'enabled': true,
      });

      if (response.data is List) {
        final agents = (response.data as List)
            .map((json) => AIAgent.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✓ [AgentAPI] 获取到 ${agents.length} 个启用的智能体');
        return agents;
      }

      throw Exception('无效的响应数据格式');
    } catch (e) {
      print('❌ [AgentAPI] 获取启用的智能体列表失败: $e');
      rethrow;
    }
  }

  /// 根据agentId获取智能体详情
  Future<AIAgent?> fetchAgentByAgentId(String agentId) async {
    try {
      print('📡 [AgentAPI] 获取智能体详情: $agentId');

      final response = await _httpClient.get('/api/agents/$agentId');

      if (response.data != null) {
        final agent = AIAgent.fromJson(response.data as Map<String, dynamic>);
        print('✓ [AgentAPI] 获取智能体详情成功: ${agent.name}');
        return agent;
      }

      return null;
    } catch (e) {
      if (e is HttpException && e.statusCode == 404) {
        print('⚠️ [AgentAPI] 智能体不存在: $agentId');
        return null;
      }
      print('❌ [AgentAPI] 获取智能体详情失败: $e');
      rethrow;
    }
  }

  // ============================================
  // 客户端只读，不提供创建/更新/删除操作
  // 所有智能体管理由后端控制
  // ============================================

  /// 通知智能体被使用
  /// 用于统计使用次数，不阻塞主流程
  Future<void> notifyAgentUsed(String agentId) async {
    try {
      await _httpClient.post('/api/agents/$agentId/use');
      print('✓ [AgentAPI] 已通知智能体使用: $agentId');
    } catch (e) {
      print('⚠️ [AgentAPI] 通知智能体使用失败: $e');
      // 不抛出异常，使用通知失败不应影响主流程
    }
  }
}
