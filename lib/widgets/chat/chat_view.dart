import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../models/conversation.dart';
import 'message_bubble.dart';
import 'chat_input.dart';

/// 聊天视图 Widget
/// 集成完整的对话界面,包括消息列表、输入框和智能体选择
class ChatView extends ConsumerStatefulWidget {
  final int? conversationId;

  const ChatView({
    super.key,
    this.conversationId,
  });

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 加载会话
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.conversationId != null) {
        ref.read(chatProvider.notifier).loadConversation(widget.conversationId!);
      }
      // 移除自动创建新会话的逻辑
      // 新会话应该只由用户明确操作（点击新建会话按钮）时创建
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 创建新会话
  Future<void> _createNewConversation() async {
    await ref.read(chatProvider.notifier).createNewConversation(null);
  }

  /// 发送消息
  void _handleSendMessage(String content) async {
    final chatNotifier = ref.read(chatProvider.notifier);

    // 如果没有当前会话,创建新会话
    if (chatNotifier.currentConversationId == null) {
      await _createNewConversation();
    }

    // 发送消息
    await chatNotifier.sendMessage(content);

    // 滚动到底部
    _scrollToBottom();
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Column(
      children: [
        // 顶部工具栏
        _buildToolbar(context),

        // 消息列表
        Expanded(
          child: _buildMessageList(chatState),
        ),

        // 输入框
        ChatInput(
          onSend: _handleSendMessage,
          isEnabled: !chatState.isStreaming && !chatState.isLoading,
          hintText: '输入消息... (Cmd/Ctrl+Enter 发送)',
        ),
      ],
    );
  }

  /// 构建顶部工具栏
  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题
          Text(
            'AI助手',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const Spacer(),

          // 取消流式响应按钮
          if (ref.watch(chatProvider).isStreaming)
            TextButton.icon(
              onPressed: () {
                ref.read(chatProvider.notifier).cancelStream();
              },
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('停止生成'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),

          // 清除会话按钮
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除会话',
            onPressed: () {
              _showClearConversationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// 构建消息列表
  Widget _buildMessageList(chatState) {
    // 加载中
    if (chatState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 错误状态
    if (chatState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              chatState.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // 清除错误并重试
                ref.read(chatProvider.notifier).clearConversation();
                _createNewConversation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (chatState.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    // 消息列表
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        return MessageBubble(
          message: message,
          onRetry: () {
            ref.read(chatProvider.notifier).retryMessage(message.id);
          },
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '开始与AI助手对话',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '在下方输入框输入消息开始对话',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  /// 显示清除会话确认对话框
  void _showClearConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除会话'),
        content: const Text('确定要清除当前会话吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearConversation();
              Navigator.pop(context);
              _createNewConversation();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

/// 聊天面板 Widget (带侧边栏的完整聊天界面)
class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  int? _selectedConversationId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 会话历史侧边栏 (可选)
        if (MediaQuery.of(context).size.width > 800) _buildConversationList(),

        // 主聊天区域
        Expanded(
          child: ChatView(
            conversationId: _selectedConversationId,
          ),
        ),
      ],
    );
  }

  /// 构建会话列表侧边栏
  Widget _buildConversationList() {
    final conversationListState = ref.watch(conversationListProvider);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题和新建按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '会话历史',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '新建会话',
                  onPressed: () {
                    setState(() {
                      _selectedConversationId = null;
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 会话列表
          Expanded(
            child: conversationListState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : conversationListState.conversations.isEmpty
                    ? const Center(child: Text('暂无会话'))
                    : ListView.builder(
                        itemCount: conversationListState.conversations.length,
                        itemBuilder: (context, index) {
                          final conversation =
                              conversationListState.conversations[index];
                          final isSelected =
                              conversation.id == _selectedConversationId;

                          return ListTile(
                            selected: isSelected,
                            title: Text(
                              conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              conversation.lastMessageContent ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 编辑按钮
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: '编辑标题',
                                  onPressed: () => _showEditTitleDialog(conversation),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                // 删除按钮
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  tooltip: '删除会话',
                                  color: Colors.red.withOpacity(0.7),
                                  onPressed: () => _showDeleteConfirmDialog(conversation),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedConversationId = conversation.id;
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 显示编辑标题对话框
  void _showEditTitleDialog(Conversation conversation) {
    final titleController = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑会话标题'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入标题',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('标题不能为空'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // 调用provider更新标题
              await ref
                  .read(conversationListProvider.notifier)
                  .setConversationTitle(conversation.id, newTitle);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('标题已更新'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ).then((_) {
      titleController.dispose();
    });
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定要删除会话「${conversation.title}」吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 调用provider删除会话
              await ref
                  .read(conversationListProvider.notifier)
                  .deleteConversation(conversation.id);

              if (mounted) {
                Navigator.pop(context);

                // 如果删除的是当前选中的会话，清除选中状态
                if (conversation.id == _selectedConversationId) {
                  setState(() {
                    _selectedConversationId = null;
                  });
                  // 清除当前会话
                  ref.read(chatProvider.notifier).clearConversation();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('会话已删除'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
