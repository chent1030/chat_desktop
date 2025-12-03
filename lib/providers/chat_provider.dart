import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/conversation_service.dart';
import '../services/ai_service.dart';
import 'agent_provider.dart';

/// 对话状态
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final Message? streamingMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.streamingMessage,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    Message? streamingMessage,
    bool clearError = false,
    bool clearStreamingMessage = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
      streamingMessage: clearStreamingMessage
          ? null
          : (streamingMessage ?? this.streamingMessage),
    );
  }
}

/// 对话Provider - 管理当前会话的消息和AI交互
class ChatNotifier extends StateNotifier<ChatState> {
  final ConversationService _conversationService;
  final Ref _ref;
  int? _currentConversationId;
  StreamSubscription? _streamSubscription;

  /// 后端返回的conversation_id（用于维持同一对话）
  String? _backendConversationId;

  ChatNotifier(this._conversationService, this._ref)
      : super(const ChatState());

  /// 获取当前会话ID
  int? get currentConversationId => _currentConversationId;

  /// 加载会话消息
  Future<void> loadConversation(int conversationId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      _currentConversationId = conversationId;
      _backendConversationId = null; // 切换会话时重置conversation_id

      final messages =
          await _conversationService.getMessagesByConversation(conversationId);

      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );

      print('✓ 已加载会话消息: $conversationId (${messages.length}条)');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载消息失败: $e',
      );
      print('✗ 加载消息失败: $e');
    }
  }

  /// 创建新会话并加载
  Future<int?> createNewConversation(String? title) async {
    try {
      final conversationId = await _conversationService.createConversation(
        agentId: 'default',
        title: title,
      );

      _currentConversationId = conversationId;
      _backendConversationId = null; // 新会话重置conversation_id
      state = state.copyWith(messages: []);

      print('✓ 已创建新会话: $conversationId');
      return conversationId;
    } catch (e) {
      state = state.copyWith(error: '创建会话失败: $e');
      print('✗ 创建会话失败: $e');
      return null;
    }
  }

  /// 发送消息
  Future<void> sendMessage(String content) async {
    if (_currentConversationId == null) {
      state = state.copyWith(error: '未选择会话');
      return;
    }

    try {
      // 1. 添加用户消息到数据库和UI
      await _conversationService.addMessage(
        conversationId: _currentConversationId!,
        agentId: 'default',
        role: MessageRole.user,
        content: content,
        status: MessageStatus.sent,
      );

      // 重新加载消息
      await _refreshMessages();

      // 2. 创建AI助手响应消息占位符
      final assistantMessageId = await _conversationService.addMessage(
        conversationId: _currentConversationId!,
        agentId: 'default',
        role: MessageRole.assistant,
        content: '',
        status: MessageStatus.streaming,
      );

      // 开始流式响应
      await _streamAIResponse(assistantMessageId);
    } catch (e) {
      state = state.copyWith(error: '发送消息失败: $e');
      print('✗ 发送消息失败: $e');
    }
  }

  /// 流式接收AI响应
  Future<void> _streamAIResponse(
    int assistantMessageId,
  ) async {
    try {
      state = state.copyWith(isStreaming: true, clearError: true);

      // 获取AI配置
      final agentConfig = _ref.read(agentConfigProvider);

      // 获取会话历史
      final messages = await _conversationService.getMessagesByConversation(
        _currentConversationId!,
      );

      // 过滤掉streaming状态的消息（当前正在生成的消息）
      final historyMessages = messages
          .where((m) => m.id != assistantMessageId)
          .toList();

      // TODO: 获取最新的用户消息内容作为query
      // 这里需要从historyMessages中获取最后一条用户消息
      final lastUserMessage = historyMessages
          .lastWhere((m) => m.role == MessageRole.user,
              orElse: () => historyMessages.last);
      final query = lastUserMessage.content;

      print('💬 [Chat] 发送消息 - conversation_id: $_backendConversationId');

      // 流式调用AI服务
      final stream = AIService.instance.sendMessageStream(
        apiUrl: agentConfig.apiUrl,
        sseUrl: agentConfig.sseUrl,
        apiKey: agentConfig.apiKey,
        messages: query, // 传入最新的用户消息
        conversationId: _backendConversationId, // 传入后端的conversation_id
      );

      // 累积的响应内容
      String accumulatedContent = '';

      _streamSubscription = stream.listen(
        (response) async {
          // 如果收到conversation_id，保存它
          if (response.conversationId != null) {
            _backendConversationId = response.conversationId;
            print('✓ [Chat] 保存 conversation_id: $_backendConversationId');
          }

          // 如果有文本内容，累积并更新
          if (response.content != null && response.content!.isNotEmpty) {
            accumulatedContent += response.content!;

            // 更新数据库中的消息
            final message =
                await _conversationService.getMessageById(assistantMessageId);
            if (message != null) {
              message.content = accumulatedContent;
              message.markAsStreaming();
              await _conversationService.updateMessage(message);
            }

            // 刷新UI
            await _refreshMessages();
          }
        },
        onDone: () async {
          // 流式传输完成，标记消息为已发送
          final message =
              await _conversationService.getMessageById(assistantMessageId);
          if (message != null) {
            message.markAsSent();
            await _conversationService.updateMessage(message);
          }

          // 自动生成会话标题（如果是第一条消息）
          if (messages.length <= 2) {
            await _conversationService.generateTitleFromFirstMessage(
              _currentConversationId!,
            );
          }

          state = state.copyWith(
            isStreaming: false,
            clearStreamingMessage: true,
          );

          await _refreshMessages();

          print('✓ AI响应完成');
        },
        onError: (error) async {
          // 标记消息为失败
          final message =
              await _conversationService.getMessageById(assistantMessageId);
          if (message != null) {
            message.markAsFailed(error.toString());
            await _conversationService.updateMessage(message);
          }

          state = state.copyWith(
            isStreaming: false,
            error: 'AI响应失败: $error',
            clearStreamingMessage: true,
          );

          await _refreshMessages();

          print('✗ AI响应失败: $error');
        },
        cancelOnError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        error: 'AI响应失败: $e',
      );
      print('✗ AI响应失败: $e');
    }
  }

  /// 取消流式响应
  void cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    state = state.copyWith(
      isStreaming: false,
      clearStreamingMessage: true,
    );
    print('✓ 已取消流式响应');
  }

  /// 刷新消息列表
  Future<void> _refreshMessages() async {
    if (_currentConversationId == null) return;

    final messages = await _conversationService.getMessagesByConversation(
      _currentConversationId!,
    );

    state = state.copyWith(messages: messages);
  }

  /// 重发消息
  Future<void> retryMessage(int messageId) async {
    try {
      final message = await _conversationService.getMessageById(messageId);
      if (message == null || message.role != MessageRole.user) {
        return;
      }

      // 删除失败的AI响应消息（如果有）
      final allMessages = state.messages;
      final messageIndex = allMessages.indexWhere((m) => m.id == messageId);
      if (messageIndex >= 0 && messageIndex < allMessages.length - 1) {
        final nextMessage = allMessages[messageIndex + 1];
        if (nextMessage.role == MessageRole.assistant &&
            nextMessage.status == MessageStatus.failed) {
          await _conversationService.deleteMessage(nextMessage.id);
        }
      }

      // 重新发送
      await sendMessage(message.content);
    } catch (e) {
      state = state.copyWith(error: '重发消息失败: $e');
      print('✗ 重发消息失败: $e');
    }
  }

  /// 清空当前会话
  void clearConversation() {
    _currentConversationId = null;
    _backendConversationId = null; // 清空时重置conversation_id
    _streamSubscription?.cancel();
    _streamSubscription = null;
    state = const ChatState();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

/// 对话Provider实例
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ConversationService.instance, ref);
});

// ============================================
// 会话历史Provider
// ============================================

/// 会话列表状态
class ConversationListState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  const ConversationListState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationListState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 会话列表Provider
class ConversationListNotifier extends StateNotifier<ConversationListState> {
  final ConversationService _conversationService;

  ConversationListNotifier(this._conversationService)
      : super(const ConversationListState(isLoading: true)) {
    loadConversations();
  }

  /// 加载所有活跃会话
  Future<void> loadConversations() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final conversations =
          await _conversationService.getAllActiveConversations();

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );

      print('✓ 已加载 ${conversations.length} 个会话');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载会话失败: $e',
      );
      print('✗ 加载会话失败: $e');
    }
  }

  /// 根据智能体加载会话
  Future<void> loadConversationsByAgent(String agentId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final conversations =
          await _conversationService.getActiveConversationsByAgent(agentId);

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );

      print('✓ 已加载智能体会话: $agentId (${conversations.length}个)');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载会话失败: $e',
      );
      print('✗ 加载会话失败: $e');
    }
  }

  /// 搜索会话
  Future<void> searchConversations(String keyword) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final conversations =
          await _conversationService.searchConversations(keyword);

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );

      print('✓ 搜索到 ${conversations.length} 个会话');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '搜索会话失败: $e',
      );
      print('✗ 搜索会话失败: $e');
    }
  }

  /// 删除会话
  Future<void> deleteConversation(int conversationId) async {
    try {
      await _conversationService.deleteConversation(conversationId);

      // 重新加载会话列表
      await loadConversations();

      print('✓ 已删除会话: $conversationId');
    } catch (e) {
      state = state.copyWith(error: '删除会话失败: $e');
      print('✗ 删除会话失败: $e');
    }
  }

  /// 设置会话标题
  Future<void> setConversationTitle(int conversationId, String title) async {
    try {
      await _conversationService.setConversationTitle(conversationId, title);

      // 重新加载会话列表
      await loadConversations();

      print('✓ 已设置会话标题: $title');
    } catch (e) {
      state = state.copyWith(error: '设置标题失败: $e');
      print('✗ 设置标题失败: $e');
    }
  }

  /// 切换会话固定状态
  Future<void> togglePin(int conversationId) async {
    try {
      await _conversationService.toggleConversationPin(conversationId);

      // 重新加载会话列表
      await loadConversations();

      print('✓ 已切换固定状态: $conversationId');
    } catch (e) {
      state = state.copyWith(error: '切换固定失败: $e');
      print('✗ 切换固定失败: $e');
    }
  }
}

/// 会话列表Provider实例
final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, ConversationListState>(
        (ref) {
  return ConversationListNotifier(ConversationService.instance);
});

/// 固定会话Provider
final pinnedConversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  return await ConversationService.instance.getPinnedConversations();
});

/// 会话统计Provider
final conversationStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, conversationId) async {
  return await ConversationService.instance
      .getConversationStatistics(conversationId);
});
