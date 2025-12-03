import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../ai_service.dart';
import '../../models/message.dart';

/// Anthropic API适配器
/// 支持Claude 3 Opus, Sonnet, Haiku等模型
class AnthropicAdapter extends BaseAIServiceAdapter {
  final String endpoint;

  AnthropicAdapter({required this.endpoint});

  @override
  String get name => 'Anthropic';

  @override
  String get description => 'Anthropic Claude系列模型';

  @override
  bool get supportsStreaming => true;

  @override
  Future<String> sendMessage({
    required List<Message> messages,
    required String apiKey,
    Map<String, dynamic>? modelParams,
  }) async {
    try {
      // 验证API密钥
      if (!validateAPIKey(apiKey)) {
        throw AIServiceException('无效的Anthropic API密钥');
      }

      // 准备请求参数
      final params = {
        ...getDefaultModelParams(),
        ...?modelParams,
      };

      // Anthropic API格式需要分离system消息
      final (systemMessage, conversationMessages) =
          _separateSystemMessage(messages);

      final requestBody = {
        'model': params['model'] ?? 'claude-3-opus-20240229',
        'messages': conversationMessages,
        'max_tokens': params['max_tokens'] ?? 2000,
        'temperature': params['temperature'] ?? 0.7,
        'stream': false,
      };

      // 如果有system消息，添加到请求中
      if (systemMessage != null) {
        requestBody['system'] = systemMessage;
      }

      // 发送请求
      final response = await dio.post(
        endpoint,
        data: requestBody,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
        ),
      );

      // 提取响应内容
      return extractContentFromResponse(response.data);
    } on DioException catch (e) {
      throw handleHttpError(e);
    } catch (e) {
      throw AIServiceException('Anthropic请求失败: $e');
    }
  }

  @override
  Stream<String> sendMessageStream({
    required List<Message> messages,
    required String apiKey,
    Map<String, dynamic>? modelParams,
  }) async* {
    // 验证API密钥
    if (!validateAPIKey(apiKey)) {
      throw AIServiceException('无效的Anthropic API密钥');
    }

    // 准备请求参数
    final params = {
      ...getDefaultModelParams(),
      ...?modelParams,
    };

    // 分离system消息
    final (systemMessage, conversationMessages) =
        _separateSystemMessage(messages);

    final requestBody = {
      'model': params['model'] ?? 'claude-3-opus-20240229',
      'messages': conversationMessages,
      'max_tokens': params['max_tokens'] ?? 2000,
      'temperature': params['temperature'] ?? 0.7,
      'stream': true,
    };

    if (systemMessage != null) {
      requestBody['system'] = systemMessage;
    }

    try {
      final response = await dio.post(
        endpoint,
        data: requestBody,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
      );

      // 处理Server-Sent Events (SSE)流
      final stream = response.data.stream;
      final lines = stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.isEmpty || !line.startsWith('data: ')) {
          continue;
        }

        final data = line.substring(6); // 移除 "data: " 前缀

        try {
          final json = jsonDecode(data);
          final type = json['type'];

          // Anthropic的流式响应格式
          if (type == 'content_block_delta') {
            final delta = json['delta'];
            if (delta != null && delta['type'] == 'text_delta') {
              final text = delta['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            }
          } else if (type == 'message_stop') {
            // 消息结束
            break;
          }
        } catch (e) {
          // 忽略JSON解析错误，继续处理下一行
          print('解析SSE数据时出错: $e');
        }
      }
    } on DioException catch (e) {
      throw handleHttpError(e);
    } catch (e) {
      throw AIServiceException('Anthropic流式请求失败: $e');
    }
  }

  @override
  String extractContentFromResponse(Map<String, dynamic> response) {
    try {
      final content = response['content'] as List?;
      if (content == null || content.isEmpty) {
        throw AIServiceException('响应中没有找到content');
      }

      // Anthropic的响应可能包含多个content块
      final textBlocks = content
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String)
          .toList();

      if (textBlocks.isEmpty) {
        throw AIServiceException('响应中没有找到文本内容');
      }

      return textBlocks.join('');
    } catch (e) {
      throw AIServiceException('解析Anthropic响应失败: $e');
    }
  }

  @override
  int? extractTokenUsageFromResponse(Map<String, dynamic> response) {
    try {
      final usage = response['usage'];
      if (usage != null) {
        final inputTokens = usage['input_tokens'] as int? ?? 0;
        final outputTokens = usage['output_tokens'] as int? ?? 0;
        return inputTokens + outputTokens;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  bool validateAPIKey(String apiKey) {
    // Anthropic API密钥格式: sk-ant-开头
    return apiKey.startsWith('sk-ant-') && apiKey.length > 20;
  }

  @override
  Map<String, dynamic> getDefaultModelParams() {
    return {
      'model': 'claude-3-opus-20240229',
      'temperature': 0.7,
      'max_tokens': 2000,
      'top_p': 1.0,
    };
  }

  @override
  List<Map<String, dynamic>> convertMessagesToAPIFormat(List<Message> messages) {
    // Anthropic不允许连续相同角色的消息，需要过滤system消息
    return messages
        .where((msg) => msg.role != MessageRole.system)
        .map((msg) {
      return {
        'role': msg.role == MessageRole.assistant ? 'assistant' : 'user',
        'content': msg.content,
      };
    }).toList();
  }

  /// 分离system消息和对话消息
  /// Anthropic API要求system消息单独传递
  ///
  /// 返回: (systemMessage, conversationMessages)
  (String?, List<Map<String, dynamic>>) _separateSystemMessage(
      List<Message> messages) {
    String? systemMessage;
    final conversationMessages = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg.role == MessageRole.system) {
        // 合并所有system消息
        if (systemMessage == null) {
          systemMessage = msg.content;
        } else {
          systemMessage += '\n${msg.content}';
        }
      } else {
        conversationMessages.add({
          'role': msg.role == MessageRole.assistant ? 'assistant' : 'user',
          'content': msg.content,
        });
      }
    }

    return (systemMessage, conversationMessages);
  }
}
