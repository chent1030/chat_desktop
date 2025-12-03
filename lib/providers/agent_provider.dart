import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 单智能体配置
/// 从环境变量读取AI配置，不再从API获取智能体列表
class AgentConfig {
  final String apiUrl;
  final String? sseUrl;
  final String apiKey;

  const AgentConfig({
    required this.apiUrl,
    this.sseUrl,
    required this.apiKey,
  });

  /// 从环境变量加载配置
  factory AgentConfig.fromEnv() {
    final apiUrl = dotenv.env['AI_API_URL'] ?? '';
    final sseUrl = dotenv.env['AI_SSE_URL'];
    final apiKey = dotenv.env['AI_API_KEY'] ?? '';

    if (apiUrl.isEmpty) {
      throw Exception('未配置AI_API_URL环境变量');
    }

    if (apiKey.isEmpty) {
      throw Exception('未配置AI_API_KEY环境变量');
    }

    return AgentConfig(
      apiUrl: apiUrl,
      sseUrl: sseUrl,
      apiKey: apiKey,
    );
  }

  /// 获取SSE URL（如果未配置则使用API URL）
  String get effectiveSseUrl => sseUrl ?? apiUrl;
}

/// 智能体配置Provider
final agentConfigProvider = Provider<AgentConfig>((ref) {
  return AgentConfig.fromEnv();
});
