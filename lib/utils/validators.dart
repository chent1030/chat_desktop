import 'constants.dart';

/// 表单验证工具类
class Validators {
  /// 验证任务标题
  static String? validateTaskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '任务标题不能为空';
    }

    if (value.trim().length > AppConstants.taskTitleMaxLength) {
      return '任务标题不能超过${AppConstants.taskTitleMaxLength}个字符';
    }

    if (value.trim() != value) {
      return '任务标题不能只包含空格';
    }

    return null;
  }

  /// 验证任务描述
  static String? validateTaskDescription(String? value) {
    if (value == null) return null;

    if (value.length > AppConstants.taskDescriptionMaxLength) {
      return '任务描述不能超过${AppConstants.taskDescriptionMaxLength}个字符';
    }

    return null;
  }

  /// 验证AI消息内容
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '消息内容不能为空';
    }

    if (value.length > AppConstants.messageMaxLength) {
      return '消息内容不能超过${AppConstants.messageMaxLength}个字符';
    }

    // 检查恶意内容
    final prohibitedPatterns = [
      'ignore previous instructions',
      'system prompt',
      'disregard',
    ];

    final lowerContent = value.toLowerCase();
    for (final pattern in prohibitedPatterns) {
      if (lowerContent.contains(pattern)) {
        return '消息内容包含禁止的指令';
      }
    }

    return null;
  }

  /// 验证会话标题
  static String? validateConversationTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '会话标题不能为空';
    }

    if (value.length > AppConstants.conversationTitleMaxLength) {
      return '会话标题不能超过${AppConstants.conversationTitleMaxLength}个字符';
    }

    return null;
  }

  /// 验证API密钥格式
  static String? validateApiKey(String? value, {required String provider}) {
    if (value == null || value.trim().isEmpty) {
      return 'API密钥不能为空';
    }

    // OpenAI密钥格式：sk-开头
    if (provider == 'openai' && !value.startsWith('sk-')) {
      return 'OpenAI API密钥格式错误（应以sk-开头）';
    }

    // Anthropic密钥格式：sk-ant-开头
    if (provider == 'anthropic' && !value.startsWith('sk-ant-')) {
      return 'Anthropic API密钥格式错误（应以sk-ant-开头）';
    }

    if (value.length < 20) {
      return 'API密钥长度不足';
    }

    return null;
  }

  /// 验证WebSocket URL
  static String? validateWebSocketUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WebSocket URL不能为空';
    }

    if (!value.startsWith('ws://') && !value.startsWith('wss://')) {
      return 'WebSocket URL格式错误（应以ws://或wss://开头）';
    }

    try {
      Uri.parse(value);
    } catch (e) {
      return 'WebSocket URL格式错误';
    }

    return null;
  }

  /// 验证日期
  static String? validateDueDate(DateTime? value) {
    if (value == null) return null;

    final now = DateTime.now();
    if (value.isBefore(now.subtract(const Duration(days: 1)))) {
      return '截止日期不能早于今天';
    }

    return null;
  }

  /// 验证邮箱格式（未来可能使用）
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '邮箱不能为空';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return '邮箱格式错误';
    }

    return null;
  }

  /// 清理和标准化输入
  static String sanitizeInput(String input) {
    // 移除多余的空格
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 检查字符串是否为空或只包含空格
  static bool isEmptyOrWhitespace(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// 截断字符串到指定长度
  static String truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }
}
