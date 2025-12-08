import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/message.dart';
import 'sse_client.dart';
import 'log_service.dart';

/// AI响应流数据
class AIStreamResponse {
  /// 文本内容
  final String? content;

  /// 会话ID（首次对话时返回，后续使用此ID）
  final String? conversationId;

  /// 是否完成
  final bool isDone;

  AIStreamResponse({
    this.content,
    this.conversationId,
    this.isDone = false,
  });
}

/// AI服务类
/// 使用POST请求发送消息，通过SSE接收流式响应
class AIService {
  static AIService? _instance;
  final Dio _dio;

  /// 认证token
  String? token;

  /// 认证token响应
  Response? tokenResponse;

  AIService._internal() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  static AIService get instance {
    _instance ??= AIService._internal();
    return _instance!;
  }

  /// 发送消息并获取流式响应
  ///
  /// [apiUrl] - API端点地址
  /// [sseUrl] - SSE端点地址（如果为空则使用apiUrl）
  /// [apiKey] - API密钥
  /// [messages] - 用户消息内容
  /// [conversationId] - 会话ID（首次对话传null，后续使用返回的ID）
  ///
  /// 返回一个Stream，每次emit AIStreamResponse（包含文本内容和conversation_id）
  Stream<AIStreamResponse> sendMessageStream({
    required String apiUrl,
    String? sseUrl,
    required String apiKey,
    required String messages,
    String? conversationId,
  }) async* {
    try {
      await LogService.instance.info('开始AI消息请求', tag: 'AI');

      // 2. 准备请求数据
      final requestData = {
        'query': messages,
        'response_mode': 'streaming',
        'user': '61016968',
        'url': 'http://10.133.29.112/v1/chat-messages',
        'conversation_id': conversationId,
        'authorization': 'Bearer $apiKey',
        'inputs': {
          'empName': '测试用户',
          'empNo': '61016968',
          'empLevel': '8',
          'ansType': ''
        }
      };

      print('📤 [AI] 发送消息到: $apiUrl');
      print('📤 [AI] 查询内容: $messages');
      print('📤 [AI] conversation_id: ${conversationId ?? "null (首次对话)"}');

      await LogService.instance.info('发送AI请求 - URL: $apiUrl', tag: 'AI');
      await LogService.instance.info('查询内容: $messages', tag: 'AI');
      await LogService.instance.info('会话ID: ${conversationId ?? "null (首次对话)"}', tag: 'AI');
      await LogService.instance.debug('请求数据: ${jsonEncode(requestData)}', tag: 'AI');

      // 4. 发送POST请求（响应本身就是SSE流）
      final response = await _dio.post<ResponseBody>(
        apiUrl,
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      await LogService.instance.info('HTTP响应状态码: ${response.statusCode}', tag: 'AI');

      if (response.statusCode != 200) {
        await LogService.instance.error('HTTP请求失败: ${response.statusCode}', tag: 'AI');
        throw AIServiceException(
          '请求失败: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      print('✓ [AI] 开始接收SSE流');
      await LogService.instance.info('开始接收SSE流', tag: 'AI');

      // 5. 直接从POST响应的stream中解析SSE数据
      final stream = response.data!.stream;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        if (mounted) {
          final text = utf8.decode(chunk);
          buffer.write(text);

          // 处理完整的事件（以双换行符分隔）
          final lines = buffer.toString().split('\n');
          buffer.clear();

          String? eventData;

          for (var i = 0; i < lines.length; i++) {
            final line = lines[i].trim();

            // 记录接收到的原始SSE行（仅DEBUG级别，避免日志过多）
            if (line.isNotEmpty && line.startsWith('data:')) {
              await LogService.instance.debug('SSE接收: $line', tag: 'AI');
            }

            // 保留未完成的行
            if (i == lines.length - 1 && line.isNotEmpty && !line.startsWith('data:')) {
              buffer.write(line);
              continue;
            }

            // 解析 data: 开头的行
            if (line.startsWith('data:')) {
              eventData = line.substring(5).trim(); // 去掉 "data:" 前缀

              if (eventData.isEmpty) continue;

              try {
                // 解析JSON数据
                final data = jsonDecode(eventData);

                if (data is Map) {
                  final eventType = data['event'] as String?;
                  final responseConversationId = data['conversation_id'];

                  // 记录事件类型
                  await LogService.instance.debug('收到AI事件: $eventType', tag: 'AI');

                  // 记录conversation_id
                  if (responseConversationId != null) {
                    print('📝 [AI] 收到 conversation_id: $responseConversationId');
                    await LogService.instance.info('收到会话ID: $responseConversationId', tag: 'AI');
                  }

                  // 根据不同的event类型处理
                  if (eventType == 'message') {
                    // LLM返回文本块事件
                    final answer = data['answer'] as String?;

                    if (answer != null && answer.isNotEmpty) {
                      await LogService.instance.info('收到AI回复内容 (长度: ${answer.length})', tag: 'AI');
                      await LogService.instance.debug('回复内容: $answer', tag: 'AI');

                      yield AIStreamResponse(
                        content: answer,
                        conversationId: responseConversationId?.toString(),
                        isDone: false,
                      );
                    }
                  } else if (eventType == 'message_end') {
                    // 消息结束事件
                    print('✓ [AI] 收到message_end，流式接收完成');
                    await LogService.instance.info('AI流式响应完成 (message_end)', tag: 'AI');

                    yield AIStreamResponse(
                      conversationId: responseConversationId?.toString(),
                      isDone: true,
                    );
                    return; // 结束stream
                  } else if (eventType == 'error') {
                    // 错误事件
                    final errorMessage = data['message'] ?? '未知错误';
                    print('❌ [AI] 收到error事件: $errorMessage');
                    await LogService.instance.error('AI返回错误: $errorMessage', tag: 'AI');
                    throw AIServiceException('Dify API错误: $errorMessage');
                  } else if (eventType == 'ping') {
                    // ping事件，保持连接
                    print('💓 [AI] 收到ping保活事件');
                    await LogService.instance.debug('收到ping保活事件', tag: 'AI');
                  } else if (eventType == 'workflow_started' ||
                            eventType == 'node_started' ||
                            eventType == 'node_finished' ||
                            eventType == 'workflow_finished') {
                    // 工作流相关事件
                    print('🔄 [AI] 收到工作流事件: $eventType');
                    await LogService.instance.debug('工作流事件: $eventType', tag: 'AI');
                  } else if (eventType == 'message_file') {
                    // 文件事件
                    print('📎 [AI] 收到文件事件');
                    await LogService.instance.info('收到文件事件', tag: 'AI');
                  } else if (eventType == 'message_replace') {
                    // 内容替换事件（审查相关）
                    final answer = data['answer'] as String?;
                    print('🔄 [AI] 收到message_replace事件');
                    await LogService.instance.info('收到内容替换事件', tag: 'AI');

                    if (answer != null && answer.isNotEmpty) {
                      await LogService.instance.debug('替换后内容: $answer', tag: 'AI');

                      yield AIStreamResponse(
                        content: answer,
                        conversationId: responseConversationId?.toString(),
                        isDone: false,
                      );
                    }
                  }
                }
              } catch (e) {
                print('⚠️ [AI] 解析SSE数据失败: $e, 原始数据: $eventData');
                await LogService.instance.warning('解析SSE数据失败: $e', tag: 'AI');
                await LogService.instance.debug('原始SSE数据: $eventData', tag: 'AI');
              }

              eventData = null;
            }
          }
        }
      }

      print('✓ [AI] SSE流接收结束');
      await LogService.instance.info('SSE流接收结束', tag: 'AI');
    } on DioException catch (e) {
      print('❌ [AI] HTTP请求失败: $e');
      await LogService.instance.error('HTTP请求异常: ${e.type} - ${e.message}', tag: 'AI');
      if (e.response != null) {
        await LogService.instance.error('响应状态码: ${e.response?.statusCode}', tag: 'AI');
        await LogService.instance.debug('响应数据: ${e.response?.data}', tag: 'AI');
      }
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      print('❌ [AI] 发送消息失败: $e');
      await LogService.instance.error('AI消息发送失败: $e', tag: 'AI');
      await LogService.instance.debug('错误堆栈: $stackTrace', tag: 'AI');
      throw AIServiceException('发送消息失败: $e');
    }
  }

  /// 用于判断stream是否还在运行
  bool get mounted => true;

  /// 处理Dio错误
  AIServiceException _handleDioError(DioException error) {
    LogService.instance.error('处理Dio错误: ${error.type}', tag: 'AI');

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String message = 'HTTP错误';
      if (data is Map) {
        message = data['error'] ?? data['message'] ?? message;
      } else if (data is String) {
        message = data;
      }

      LogService.instance.error('HTTP错误 [$statusCode]: $message', tag: 'AI');

      return AIServiceException(
        message,
        statusCode: statusCode,
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      LogService.instance.error('请求超时: ${error.type}', tag: 'AI');
      return AIServiceException(
        '请求超时，请检查网络连接',
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      LogService.instance.error('连接错误: 无法连接到服务器', tag: 'AI');
      return AIServiceException(
        '无法连接到服务器，请检查网络设置',
        originalError: error,
      );
    }

    LogService.instance.error('未知Dio错误: ${error.message}', tag: 'AI');
    return AIServiceException(
      '未知错误: ${error.message}',
      originalError: error,
    );
  }
}

/// AI服务异常类
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AIServiceException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'AIServiceException ($statusCode): $message';
    }
    return 'AIServiceException: $message';
  }
}
