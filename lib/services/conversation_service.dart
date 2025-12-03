import 'package:isar/isar.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'storage_service.dart';

/// 会话管理服务 - 负责会话和消息的CRUD操作
class ConversationService {
  static ConversationService? _instance;
  final StorageService _storageService;

  ConversationService._() : _storageService = StorageService.instance;

  static ConversationService get instance {
    _instance ??= ConversationService._();
    return _instance!;
  }

  /// 获取Isar实例
  Isar get _isar => _storageService.isar;

  // ============================================
  // 会话CRUD操作
  // ============================================

  /// 创建新会话
  Future<int> createConversation({
    required String agentId,
    String? title,
  }) async {
    final conversation = ConversationBuilder.create(
      agentId: agentId,
      title: title,
    );

    await _isar.writeTxn(() async {
      await _isar.conversations.put(conversation);
    });

    print('✓ 会话已创建: ${conversation.title} (ID: ${conversation.id})');
    return conversation.id;
  }

  /// 根据ID获取会话
  Future<Conversation?> getConversationById(int id) async {
    return await _isar.conversations.get(id);
  }

  /// 获取智能体的所有活跃会话
  Future<List<Conversation>> getActiveConversationsByAgent(
      String agentId) async {
    return await _isar.conversations
        .filter()
        .agentIdEqualTo(agentId)
        .isActiveEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 获取所有活跃会话
  Future<List<Conversation>> getAllActiveConversations() async {
    return await _isar.conversations
        .filter()
        .isActiveEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 更新会话
  Future<void> updateConversation(Conversation conversation) async {
    conversation.touch();

    await _isar.writeTxn(() async {
      await _isar.conversations.put(conversation);
    });

    print('✓ 会话已更新: ${conversation.title}');
  }

  /// 删除会话 (软删除,标记为非活跃)
  Future<void> deleteConversation(int conversationId) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      print('✗ 会话不存在: $conversationId');
      return;
    }

    conversation.isActive = false;
    await updateConversation(conversation);

    print('✓ 会话已删除: ${conversation.title}');
  }

  /// 永久删除会话及其所有消息
  Future<void> permanentlyDeleteConversation(int conversationId) async {
    await _isar.writeTxn(() async {
      // 删除所有相关消息
      final messages = await getMessagesByConversation(conversationId);
      final messageIds = messages.map((m) => m.id).toList();
      await _isar.messages.deleteAll(messageIds);

      // 删除会话
      await _isar.conversations.delete(conversationId);
    });

    print('✓ 会话及消息已永久删除: $conversationId');
  }

  // ============================================
  // 消息CRUD操作
  // ============================================

  /// 添加消息到会话
  Future<int> addMessage({
    required int conversationId,
    required String agentId,
    required MessageRole role,
    required String content,
    MessageStatus status = MessageStatus.sent,
  }) async {
    final now = DateTime.now();
    final message = Message(
      conversationId: conversationId,
      agentId: agentId,
      role: role,
      content: content,
      status: status,
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.messages.put(message);
    });

    // 更新会话信息
    final conversation = await getConversationById(conversationId);
    if (conversation != null) {
      conversation.incrementMessageCount();
      conversation.updateLastMessage(content);
      await updateConversation(conversation);
    }

    return message.id;
  }

  /// 根据ID获取消息
  Future<Message?> getMessageById(int id) async {
    return await _isar.messages.get(id);
  }

  /// 获取会话的所有消息
  Future<List<Message>> getMessagesByConversation(int conversationId) async {
    return await _isar.messages
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .findAll();
  }

  /// 获取会话的最近N条消息
  Future<List<Message>> getRecentMessages(int conversationId,
      {int limit = 20}) async {
    return await _isar.messages
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// 更新消息
  Future<void> updateMessage(Message message) async {
    message.touch();

    await _isar.writeTxn(() async {
      await _isar.messages.put(message);
    });
  }

  /// 删除消息
  Future<void> deleteMessage(int messageId) async {
    await _isar.writeTxn(() async {
      await _isar.messages.delete(messageId);
    });

    print('✓ 消息已删除: $messageId');
  }

  // ============================================
  // 会话管理
  // ============================================

  /// 设置会话标题
  Future<void> setConversationTitle(int conversationId, String title) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) return;

    conversation.setTitle(title);
    await updateConversation(conversation);
  }

  /// 切换会话固定状态
  Future<void> toggleConversationPin(int conversationId) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) return;

    conversation.togglePin();
    await updateConversation(conversation);
  }

  /// 获取固定的会话
  Future<List<Conversation>> getPinnedConversations() async {
    return await _isar.conversations
        .filter()
        .isPinnedEqualTo(true)
        .isActiveEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  // ============================================
  // 自动标题生成 (T046)
  // ============================================

  /// 从首条消息自动生成会话标题
  Future<void> generateTitleFromFirstMessage(int conversationId) async {
    final messages = await getMessagesByConversation(conversationId);
    if (messages.isEmpty) return;

    // 查找第一条用户消息
    final firstUserMessage = messages.firstWhere(
      (msg) => msg.role == MessageRole.user,
      orElse: () => messages.first,
    );

    final title = ConversationBuilder.generateTitleFromMessage(
      firstUserMessage.content,
    );

    await setConversationTitle(conversationId, title);
    print('✓ 自动生成会话标题: $title');
  }

  // ============================================
  // 查询和统计
  // ============================================

  /// 搜索会话
  Future<List<Conversation>> searchConversations(String keyword) async {
    final lowerKeyword = keyword.toLowerCase().trim();
    if (lowerKeyword.isEmpty) {
      return await getAllActiveConversations();
    }

    return await _isar.conversations
        .filter()
        .isActiveEqualTo(true)
        .titleContains(lowerKeyword, caseSensitive: false)
        .or()
        .lastMessageContentContains(lowerKeyword, caseSensitive: false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 获取会话总数
  Future<int> getConversationCount() async {
    return await _isar.conversations
        .filter()
        .isActiveEqualTo(true)
        .count();
  }

  /// 获取消息总数
  Future<int> getMessageCount(int conversationId) async {
    return await _isar.messages
        .filter()
        .conversationIdEqualTo(conversationId)
        .count();
  }

  /// 获取会话统计信息
  Future<Map<String, dynamic>> getConversationStatistics(
      int conversationId) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      return {};
    }

    final messages = await getMessagesByConversation(conversationId);
    final userMessages =
        messages.where((m) => m.role == MessageRole.user).length;
    final assistantMessages =
        messages.where((m) => m.role == MessageRole.assistant).length;
    final totalTokens = messages
        .where((m) => m.tokenCount != null)
        .fold(0, (sum, m) => sum + (m.tokenCount ?? 0));

    return {
      'totalMessages': messages.length,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'totalTokens': totalTokens,
      'createdAt': conversation.createdAt,
      'updatedAt': conversation.updatedAt,
    };
  }

  // ============================================
  // 工具方法
  // ============================================

  /// 监听会话变化
  Stream<void> watchConversations() {
    return _isar.conversations.watchLazy();
  }

  /// 监听特定会话的变化
  Stream<Conversation?> watchConversation(int conversationId) {
    return _isar.conversations.watchObject(conversationId);
  }

  /// 监听会话的消息变化
  Stream<void> watchConversationMessages(int conversationId) {
    return _isar.messages
        .filter()
        .conversationIdEqualTo(conversationId)
        .watch(fireImmediately: false);
  }

  /// 清空所有会话和消息 (用于测试)
  Future<void> clearAllConversations() async {
    await _isar.writeTxn(() async {
      await _isar.conversations.clear();
      await _isar.messages.clear();
    });

    print('✓ 已清空所有会话和消息');
  }

  /// 清理旧的非活跃会话 (保留最近N天)
  Future<void> cleanupOldConversations({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    final oldConversations = await _isar.conversations
        .filter()
        .isActiveEqualTo(false)
        .updatedAtLessThan(cutoffDate)
        .findAll();

    for (final conversation in oldConversations) {
      await permanentlyDeleteConversation(conversation.id);
    }

    print('✓ 已清理 ${oldConversations.length} 个旧会话');
  }
}
