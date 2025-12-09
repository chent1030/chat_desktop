import 'dart:async';
import 'dart:convert';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import '../models/message.dart';
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
      final requestData = {
        'query': messages,
        'response_mode': 'streaming',
        'user': '61016968',
        'conversation_id': conversationId,
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
