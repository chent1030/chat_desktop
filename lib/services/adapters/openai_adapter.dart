import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../ai_service.dart';
import '../../models/message.dart';

/// OpenAI API适配器
/// 支持GPT-4, GPT-3.5-turbo等模型
class OpenAIAdapter extends BaseAIServiceAdapter {
  final String endpoint;

  OpenAIAdapter({required this.endpoint});

  @override
  String get name => 'OpenAI';

  @override
  String get description => 'OpenAI GPT系列模型';

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
        throw AIServiceException('无效的OpenAI API密钥');
      }

      // 准备请求参数
      final params = {
        ...getDefaultModelParams(),
        ...?modelParams,
      };

      final requestBody = {
        'model': params['model'] ?? 'gpt-4',
        'messages': convertMessagesToAPIFormat(messages),
        'temperature': params['temperature'] ?? 0.7,
        'max_tokens': params['max_tokens'] ?? 2000,
        'stream': false,
      };

      // 发送请求
      final response = await dio.post(
        endpoint,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      // 提取响应内容
      return extractContentFromResponse(response.data);
    } on DioException catch (e) {
      throw handleHttpError(e);
    } catch (e) {
      throw AIServiceException('OpenAI请求失败: $e');
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
      throw AIServiceException('无效的OpenAI API密钥');
    }

    // 准备请求参数
    final params = {
      ...getDefaultModelParams(),
      ...?modelParams,
    };

    final requestBody = {
      'model': params['model'] ?? 'gpt-4',
      'messages': convertMessagesToAPIFormat(messages),
      'temperature': params['temperature'] ?? 0.7,
      'max_tokens': params['max_tokens'] ?? 2000,
      'stream': true,
    };

    try {
      final response = await dio.post(
        endpoint,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
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

        // 检查是否为结束标记
        if (data == '[DONE]') {
          break;
        }

        try {
          final json = jsonDecode(data);
          final delta = json['choices']?[0]?['delta'];

          if (delta != null && delta['content'] != null) {
            final content = delta['content'] as String;
            if (content.isNotEmpty) {
              yield content;
            }
          }
        } catch (e) {
          // 忽略JSON解析错误，继续处理下一行
          print('解析SSE数据时出错: $e');
        }
      }
    } on DioException catch (e) {
      throw handleHttpError(e);
    } catch (e) {
      throw AIServiceException('OpenAI流式请求失败: $e');
    }
  }

  @override
  String extractContentFromResponse(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw AIServiceException('响应中没有找到choices');
      }

      final message = choices[0]['message'];
      if (message == null || message['content'] == null) {
        throw AIServiceException('响应中没有找到消息内容');
      }

      return message['content'] as String;
    } catch (e) {
      throw AIServiceException('解析OpenAI响应失败: $e');
    }
  }

  @override
  int? extractTokenUsageFromResponse(Map<String, dynamic> response) {
    try {
      final usage = response['usage'];
      if (usage != null && usage['total_tokens'] != null) {
        return usage['total_tokens'] as int;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  bool validateAPIKey(String apiKey) {
    // OpenAI API密钥格式: sk-开头
    return apiKey.startsWith('sk-') && apiKey.length > 20;
  }

  @override
  Map<String, dynamic> getDefaultModelParams() {
    return {
      'model': 'gpt-4',
      'temperature': 0.7,
      'max_tokens': 2000,
      'top_p': 1.0,
      'frequency_penalty': 0.0,
      'presence_penalty': 0.0,
    };
  }

  @override
  List<Map<String, dynamic>> convertMessagesToAPIFormat(List<Message> messages) {
    return messages.map((msg) {
      return {
        'role': msg.role.name,
        'content': msg.content,
      };
    }).toList();
  }
}
