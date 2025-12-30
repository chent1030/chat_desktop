import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/config_service.dart';
import '../utils/ai_assistants.dart';

/// 当前选择的 AI 助手（仅 Key），持久化到 SharedPreferences
final aiAssistantKeyProvider =
    StateNotifierProvider<AiAssistantKeyNotifier, String>((ref) {
  return AiAssistantKeyNotifier();
});

final aiAssistantLabelProvider = Provider<String>((ref) {
  final key = ref.watch(aiAssistantKeyProvider);
  return AiAssistants.optionForKey(key).label;
});

class AiAssistantKeyNotifier extends StateNotifier<String> {
  AiAssistantKeyNotifier() : super(_initialKey());

  static String _initialKey() {
    try {
      return ConfigService.instance.aiAssistantKey;
    } catch (_) {
      return AiAssistants.keyXinService;
    }
  }

  Future<void> setKey(String key) async {
    if (key == state) return;
    state = key;
    try {
      await ConfigService.instance.setAiAssistantKey(key);
    } catch (_) {}
  }
}
