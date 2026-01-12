import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_assistant_provider.dart';
import '../utils/ai_assistants.dart';
import '../utils/env_config.dart';

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
  factory AgentConfig.fromEnv({required String aiAssistantKey}) {
    final apiUrl = EnvConfig.aiApiUrl;
    final sseUrl = EnvConfig.aiSseUrl;
    final apiKey = switch (aiAssistantKey) {
      AiAssistants.keyXinService => EnvConfig.aiApiKeyXinService,
      AiAssistants.keyLocalQa => EnvConfig.aiApiKeyLocalQa,
      _ => EnvConfig.aiApiKey,
    };

    if (apiUrl.isEmpty) {
      throw Exception('未配置AI_API_URL环境变量');
    }

    if (apiKey.isEmpty) {
      throw Exception(
          '未配置AI_API_KEY（或对应的 AI_API_KEY_XIN_SERVICE/AI_API_KEY_LOCAL_QA）');
    }

    return AgentConfig(
      apiUrl: apiUrl,
      sseUrl: sseUrl,
      apiKey: apiKey,
    );
  }

  /// 语音创建任务抽取专用配置
  /// 支持单独指定 Key（必要）与 URL（可选覆盖）
  factory AgentConfig.fromEnvForTaskExtract() {
    final apiUrl = EnvConfig.aiTaskExtractApiUrl;
    final sseUrl = EnvConfig.aiTaskExtractSseUrl;
    final apiKey = EnvConfig.aiTaskExtractApiKey;

    if (apiUrl.isEmpty) {
      throw Exception('未配置AI_API_URL（或 AI_API_URL_TASK_EXTRACT）环境变量');
    }
    if (apiKey.isEmpty) {
      throw Exception('未配置AI_API_KEY_TASK_EXTRACT环境变量');
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
  final key = ref.watch(aiAssistantKeyProvider);
  return AgentConfig.fromEnv(aiAssistantKey: key);
});

/// 任务语音抽取专用配置 Provider
final taskExtractAgentConfigProvider = Provider<AgentConfig>((ref) {
  return AgentConfig.fromEnvForTaskExtract();
});
