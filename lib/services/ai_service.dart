import 'dart:async';
import 'dart:convert';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:dio/dio.dart';
import '../models/message.dart';
import 'log_service.dart';
import 'config_service.dart';

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
/// 使用flutter_client_sse发送POST请求并接收SSE流式响应
class AIService {
  static AIService? _instance;

  /// 认证token
  String? token;

  AIService._internal();

  static AIService get instance {
    _instance ??= AIService._internal();
    return _instance!;
  }

  Map<String, dynamic> _buildRequestData({
    required String messages,
    required String responseMode,
    String? conversationId,
  }) {
    final empNo = ConfigService.instance.empNo?.trim();
    final userId = (empNo == null || empNo.isEmpty) ? 'unknown' : empNo;

    return {
      'query': messages,
      'response_mode': responseMode,
      'user': userId,
      'conversation_id': conversationId,
      'inputs': {
        'empName': '',
        'empNo': userId,
        'empLevel': '',
        'ansType': '',
      }
    };
  }

  /// 任务/工作流类 blocking 请求（不传提示词，只传 query + inputs）
  ///
  /// 请求体格式：
  /// {
  ///   "query": "...",
  ///   "response_mode": "blocking",
  ///   "user": "<empNo>",
  ///   "conversation_id": "",
  ///   "inputs": {...}
  /// }
  Future<String> sendWorkflowOnce({
    required String apiUrl,
    required String apiKey,
    required String query,
    required Map<String, dynamic> inputs,
    String conversationId = '',
  }) async {
    try {
      await LogService.instance.info('开始AI workflow blocking 请求', tag: 'AI');
      await LogService.instance.info('入参：${inputs}', tag: 'AI');
      final empNo = ConfigService.instance.empNo?.trim();
      if (empNo == null || empNo.isEmpty) {
        throw AIServiceException('当前未设置工号，无法发起AI请求');
      }

      final requestData = <String, dynamic>{
        'query': query,
        'response_mode': 'blocking',
        'user': empNo,
        'conversation_id': conversationId,
        'inputs': inputs,
      };
      await LogService.instance.debug(
        'workflow blocking 请求: url=$apiUrl, body=${jsonEncode(requestData)}',
        tag: 'AI',
      );

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          responseType: ResponseType.json,
        ),
      );

      final response = await dio.post(
        apiUrl,
        data: requestData,
        options: Options(
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );

      final data = response.data;
      if (data is Map) {
        final answer = data['answer'];
        if (answer is String && answer.trim().isNotEmpty) {
          return answer;
        }
      }

      throw AIServiceException('workflow blocking 响应解析失败: ${jsonEncode(data)}');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      final detail = (responseData == null)
          ? ''
          : ', response=${jsonEncode(responseData)}';
      await LogService.instance.error(
        'workflow blocking 请求失败: statusCode=$statusCode, message=${e.message}$detail',
        tag: 'AI',
      );
      throw AIServiceException(
        'workflow blocking 请求失败: statusCode=$statusCode, message=${e.message}$detail',
      );
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('workflow blocking 请求失败: $e');
    }
  }

  /// 任务/工作流类 streaming 请求（SSE）
  ///
  /// 适用于后端不支持 blocking 的场景。
  /// - 通过 `event=message/agent_message` 的 `answer` 字段输出分片
  /// - `event=message_end` 表示结束
  Stream<String> sendWorkflowStream({
    required String apiUrl,
    required String apiKey,
    required String query,
    required Map<String, dynamic> inputs,
    String conversationId = '',
  }) async* {
    await LogService.instance.info('开始AI workflow streaming 请求', tag: 'AI');

    final empNo = ConfigService.instance.empNo?.trim();
    if (empNo == null || empNo.isEmpty) {
      throw AIServiceException('当前未设置工号，无法发起AI请求');
    }

    final requestData = <String, dynamic>{
      'query': query,
      'response_mode': 'streaming',
      'user': empNo,
      'conversation_id': conversationId,
      'inputs': inputs,
    };
    await LogService.instance.debug(
      'workflow streaming 请求: url=$apiUrl, body=${jsonEncode(requestData)}',
      tag: 'AI',
    );

    try {
      final sseStream = SSEClient.subscribeToSSE(
        method: SSERequestType.POST,
        url: apiUrl,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestData,
      );

      await for (final event in sseStream) {
        if (event.data == null || event.data!.isEmpty) continue;

        try {
          final decoded = jsonDecode(event.data!);
          if (decoded is! Map) continue;

          final eventType = decoded['event'] as String?;
          if (eventType == 'message' || eventType == 'agent_message') {
            final answer = decoded['answer'] as String?;
            if (answer != null && answer.isNotEmpty) {
              yield answer;
            }
          } else if (eventType == 'message_end') {
            return;
          } else if (eventType == 'error') {
            final errorMessage = decoded['message'] ?? '未知错误';
            throw AIServiceException('workflow streaming 错误: $errorMessage');
          }
        } catch (e) {
          // SSE 数据解析异常：不中断流，继续读取后续事件
          await LogService.instance.warning(
            'workflow streaming 解析失败: $e, raw=${event.data}',
            tag: 'AI',
          );
        }
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('workflow streaming 请求失败: $e');
    }
  }

  /// 发送消息并获取一次性响应（非SSE）
  ///
  /// 适用于后端不支持 streaming 的场景。
  /// 约定：
  /// - Dify blocking 一般返回 `answer`
  /// - 若返回结构不同，会尝试兼容解析，否则抛异常
  Future<String> sendMessageOnce({
    required String apiUrl,
    required String apiKey,
    required String messages,
    String? conversationId,
  }) async {
    try {
      await LogService.instance.info('开始AI blocking 请求', tag: 'AI');

      final requestData = _buildRequestData(
        messages: messages,
        responseMode: 'blocking',
        conversationId: conversationId,
      );

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          responseType: ResponseType.json,
        ),
      );

      final response = await dio.post(
        apiUrl,
        data: requestData,
        options: Options(
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );

      final data = response.data;
      print('✓ blocking 响应数据: ${jsonEncode(data)}');
      if (data is Map) {
        final answer = data['answer'];
        if (answer is String && answer.trim().isNotEmpty) {
          return answer;
        }
        // 兼容部分实现把内容放到 message/content 中
        final message = data['message'];
        if (message is Map && message['content'] is String) {
          final content = (message['content'] as String).trim();
          if (content.isNotEmpty) return content;
        }
        // 兼容 OpenAI 风格
        final choices = data['choices'];
        if (choices is List && choices.isNotEmpty) {
          final first = choices.first;
          if (first is Map) {
            final m = first['message'];
            if (m is Map && m['content'] is String) {
              final content = (m['content'] as String).trim();
              if (content.isNotEmpty) return content;
            }
          }
        }
      }

      throw AIServiceException('blocking 响应解析失败: ${jsonEncode(data)}');
    } on DioException catch (e) {
      throw AIServiceException('blocking 请求失败: ${e.message}');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('blocking 请求失败: $e');
    }
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

      // 准备请求数据
      final requestData = _buildRequestData(
        messages: messages,
        responseMode: 'streaming',
        conversationId: conversationId,
      );

      print('📤 [AI] 发送消息到: $apiUrl');
      print('📤 [AI] 查询内容: $messages');
      print('📤 [AI] conversation_id: ${conversationId ?? "null (首次对话)"}');

      await LogService.instance.info('发送AI请求 - URL: $apiUrl', tag: 'AI');
      await LogService.instance.info('查询内容: $messages', tag: 'AI');
      await LogService.instance.info('会话ID: ${conversationId ?? "null (首次对话)"}', tag: 'AI');
      await LogService.instance.debug('请求数据: ${jsonEncode(requestData)}', tag: 'AI');

      print('✓ [AI] 开始接收SSE流 (使用flutter_client_sse)');
      await LogService.instance.info('开始接收SSE流 (使用flutter_client_sse)', tag: 'AI');

      // 使用flutter_client_sse发送POST请求并接收SSE流
      final sseStream = SSEClient.subscribeToSSE(
        method: SSERequestType.POST,
        url: apiUrl,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestData,
      );

      // 监听SSE事件流
      await for (final event in sseStream) {
        try {
          // 跳过空数据
          if (event.data == null || event.data!.isEmpty) {
            continue;
          }

          // 记录接收到的原始SSE数据（仅DEBUG级别，避免日志过多）
          await LogService.instance.debug('SSE接收: ${event.data}', tag: 'AI');
          print('📰 [AI] 接收SSE数据: ${event.data}');
          // 解析JSON数据
          final data = jsonDecode(event.data!);

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
            if (eventType == 'message' || eventType == 'agent_message') {
              // LLM返回文本块事件 (支持 message 和 agent_message)
              final answer = data['answer'] as String?;

              if (answer != null && answer.isNotEmpty) {
                await LogService.instance.info('收到AI回复内容 (长度: ${answer.length})', tag: 'AI');
                await LogService.instance.debug('回复内容: $answer', tag: 'AI');
                print('✅ [AI] 准备yield内容: "${answer.substring(0, answer.length > 20 ? 20 : answer.length)}..."');

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
          print('⚠️ [AI] 解析SSE数据失败: $e, 原始数据: ${event.data}');
          await LogService.instance.warning('解析SSE数据失败: $e', tag: 'AI');
          await LogService.instance.debug('原始SSE数据: ${event.data}', tag: 'AI');

          // 如果是AIServiceException，重新抛出让上层处理
          if (e is AIServiceException) {
            rethrow;
          }
          // 其他解析错误则跳过这条数据，继续处理下一条
        }
      }

      print('✓ [AI] SSE流接收结束');
      await LogService.instance.info('SSE流接收结束', tag: 'AI');
    } catch (e, stackTrace) {
      print('❌ [AI] 发送消息失败: $e');
      await LogService.instance.error('AI消息发送失败: $e', tag: 'AI');
      await LogService.instance.debug('错误堆栈: $stackTrace', tag: 'AI');

      // 如果是AIServiceException直接抛出，否则包装一下
      if (e is AIServiceException) {
        rethrow;
      }
      throw AIServiceException('发送消息失败: $e');
    }
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
