/// AI助手选项（仅负责 UI 和 Key，不包含任何密钥）
class AiAssistants {
  static const String keyXinService = 'xin_service';
  static const String keyLocalQa = 'local_qa';

  static const List<AiAssistantOption> options = [
    AiAssistantOption(
      key: keyXinService,
      label: '芯服务',
    ),
    AiAssistantOption(
      key: keyLocalQa,
      label: '本地问答',
    ),
  ];

  static AiAssistantOption optionForKey(String key) {
    for (final o in options) {
      if (o.key == key) return o;
    }
    return options.first;
  }
}

class AiAssistantOption {
  final String key;
  final String label;

  const AiAssistantOption({
    required this.key,
    required this.label,
  });
}
