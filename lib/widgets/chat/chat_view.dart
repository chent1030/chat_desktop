import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../models/conversation.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../utils/ai_assistants.dart';
import 'message_bubble.dart';
import 'chat_input.dart';

/// 聊天视图 Widget
/// 集成完整的对话界面,包括消息列表、输入框和智能体选择
class ChatView extends ConsumerStatefulWidget {
  final int? conversationId;
  final ValueChanged<int?>? onSelectConversation;

  const ChatView({
    super.key,
    this.conversationId,
    this.onSelectConversation,
  });

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _conversationMenuKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // 加载会话
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.conversationId != null) {
        ref
            .read(chatProvider.notifier)
            .loadConversation(widget.conversationId!);
      }
      // 移除自动创建新会话的逻辑
      // 新会话应该只由用户明确操作（点击新建会话按钮）时创建
    });
  }

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当conversationId变化时，重新加载该会话的消息
    if (widget.conversationId != oldWidget.conversationId) {
      // 使用addPostFrameCallback在widget构建完成后再修改provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.conversationId != null) {
          ref
              .read(chatProvider.notifier)
              .loadConversation(widget.conversationId!);
          // 滚动到底部
          _scrollToBottom();
        } else {
          // 如果conversationId变为null，清空当前会话
          ref.read(chatProvider.notifier).clearConversation();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 创建新会话
  Future<void> _createNewConversation() async {
    final id =
        await ref.read(chatProvider.notifier).createNewConversation(null);
    if (id != null) {
      // 刷新会话列表，确保下拉里能看到新会话
      await ref.read(conversationListProvider.notifier).loadConversations();
      widget.onSelectConversation?.call(id);
    }
  }

  Future<void> _deleteCurrentConversation() async {
    final id = widget.conversationId;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: const Text('确定要删除当前会话吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(conversationListProvider.notifier).deleteConversation(id);
    ref.read(chatProvider.notifier).clearConversation();
    widget.onSelectConversation?.call(null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('会话已删除')),
    );
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

        if (chatState.error != null)
          _buildErrorBanner(
            context,
            message: chatState.error!,
          ),

        // 消息列表
        Expanded(
          child: _buildMessageList(chatState),
        ),

        // 输入框
        ChatInput(
          onSend: _handleSendMessage,
          isEnabled: !chatState.isStreaming && !chatState.isLoading,
          hintText: '输入消息... (Enter发送，Shift+Enter换行)',
        ),
      ],
    );
  }

  /// 构建顶部工具栏
  Widget _buildToolbar(BuildContext context) {
    final conversationListState = ref.watch(conversationListProvider);
    final theme = Theme.of(context);
    final aiKey = ref.watch(aiAssistantKeyProvider);
    final currentConversation = widget.conversationId == null
        ? null
        : conversationListState.conversations
            .where((c) => c.id == widget.conversationId)
            .cast<Conversation?>()
            .firstWhere((c) => c != null, orElse: () => null);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'AI助手',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.loose,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: '切换AI助手（仅切换 API Key）',
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: AiAssistants.keyXinService,
                            label: Text('芯服务'),
                            icon: Icon(Icons.business_center_outlined),
                          ),
                          ButtonSegment(
                            value: AiAssistants.keyLocalQa,
                            label: Text('本地问答'),
                            icon: Icon(Icons.question_answer_outlined),
                          ),
                        ],
                        selected: {aiKey},
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onSelectionChanged: (selection) {
                          final key = selection.isEmpty
                              ? AiAssistants.keyXinService
                              : selection.first;
                          if (key == aiKey) return;
                          () async {
                            await ref
                                .read(aiAssistantKeyProvider.notifier)
                                .setKey(key);
                            ref.read(chatProvider.notifier).clearConversation();
                            widget.onSelectConversation?.call(null);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '已切换AI助手：${AiAssistants.optionForKey(key).label}',
                                ),
                              ),
                            );
                          }();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: conversationListState.isLoading
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('加载会话中...'),
                          ],
                        )
                      : PopupMenuButton<String>(
                          key: _conversationMenuKey,
                          tooltip: '选择会话',
                          position: PopupMenuPosition.under,
                          onSelected: (value) async {
                            if (value == 'new') {
                              widget.onSelectConversation?.call(null);
                              return;
                            }
                            if (value.startsWith('c:')) {
                              final id = int.tryParse(value.substring(2));
                              widget.onSelectConversation?.call(id);
                              return;
                            }
                            if (value.startsWith('del:')) {
                              final id = int.tryParse(value.substring(4));
                              if (id == null) return;
                              await ref
                                  .read(conversationListProvider.notifier)
                                  .deleteConversation(id);
                              ref
                                  .read(chatProvider.notifier)
                                  .clearConversation();
                              if (widget.conversationId == id) {
                                widget.onSelectConversation?.call(null);
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('会话已删除')),
                              );
                            }
                          },
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[];
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'new',
                                child: Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('新会话'),
                                  ],
                                ),
                              ),
                            );
                            items.add(const PopupMenuDivider());

                            if (conversationListState.conversations.isEmpty) {
                              items.add(
                                PopupMenuItem<String>(
                                  enabled: false,
                                  value: 'empty',
                                  child: Text(
                                    '暂无会话',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              for (final c
                                  in conversationListState.conversations) {
                                final selected = c.id == widget.conversationId;
                                items.add(
                                  PopupMenuItem<String>(
                                    value: 'c:${c.id}',
                                    child: Row(
                                      children: [
                                        Icon(
                                          selected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          size: 18,
                                          color: selected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface
                                                  .withOpacity(0.55),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.title.isEmpty
                                                    ? '会话 ${c.id}'
                                                    : c.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if ((c.lastMessageContent ?? '')
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 2,
                                                  ),
                                                  child: Text(
                                                    c.lastMessageContent ?? '',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: theme
                                                          .colorScheme.onSurface
                                                          .withOpacity(0.6),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: '删除会话',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: theme.colorScheme.error,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              'del:${c.id}',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }
                            return items;
                          },
                          child: Material(
                            color: theme.colorScheme.surfaceVariant
                                .withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                final state = _conversationMenuKey.currentState;
                                if (state is PopupMenuButtonState<String>) {
                                  state.showButtonMenu();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentConversation == null
                                                ? '新会话'
                                                : (currentConversation
                                                        .title.isEmpty
                                                    ? '会话 ${currentConversation.id}'
                                                    : currentConversation
                                                        .title),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (currentConversation != null &&
                                              (currentConversation
                                                          .lastMessageContent ??
                                                      '')
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                currentConversation
                                                        .lastMessageContent ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.expand_more,
                                      size: 18,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (ref.watch(chatProvider).isStreaming)
            IconButton(
              tooltip: '停止生成',
              onPressed: () {
                ref.read(chatProvider.notifier).cancelStream();
              },
              icon: Icon(Icons.stop, color: theme.colorScheme.error),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建会话',
            onPressed: () async {
              await _createNewConversation();
            },
          ),
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

  Widget _buildErrorBanner(
    BuildContext context, {
    required String message,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearError();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            child: const Text('关闭'),
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
    // 隐藏会话历史侧栏，改用 ChatView 顶部下拉选择会话，让对话区域更宽
    return ChatView(
      conversationId: _selectedConversationId,
      onSelectConversation: (id) {
        setState(() {
          _selectedConversationId = id;
        });
      },
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
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: '编辑标题',
                                  onPressed: () =>
                                      _showEditTitleDialog(conversation),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                // 删除按钮
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  tooltip: '删除会话',
                                  color: Colors.red.withOpacity(0.7),
                                  onPressed: () =>
                                      _showDeleteConfirmDialog(conversation),
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
