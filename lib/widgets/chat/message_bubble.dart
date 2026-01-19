import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/message.dart';
import '../common/app_markdown.dart';

/// 消息气泡 Widget
/// 显示单条对话消息,支持用户消息和AI助手消息的不同样式
class MessageBubble extends StatefulWidget {
  final Message message;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isThinkingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final isAssistant = widget.message.role == MessageRole.assistant;
    final isSystem = widget.message.role == MessageRole.system;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // AI助手和系统消息显示头像在左侧
          if (!isUser) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],

          // 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 消息气泡
                SelectionArea(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getBorderColor(context),
                        width: 1,
                      ),
                    ),
                    child: _buildMessageContent(context),
                  ),
                ),

                // 消息状态和时间
                const SizedBox(height: 4),
                _buildMessageMeta(context),
              ],
            ),
          ),

          // 用户消息显示头像在右侧
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getAvatarIcon(),
        size: 20,
        color: isUser
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }

  /// 获取头像图标
  IconData _getAvatarIcon() {
    switch (widget.message.role) {
      case MessageRole.user:
        return Icons.person;
      case MessageRole.assistant:
        return Icons.smart_toy;
      case MessageRole.system:
        return Icons.settings;
    }
  }

  /// 获取气泡背景色
  Color _getBubbleColor(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final isFailed = widget.message.status == MessageStatus.failed;

    if (isFailed) {
      return Theme.of(context).colorScheme.errorContainer;
    }

    if (isUser) {
      return Theme.of(context).colorScheme.primaryContainer;
    }

    return Theme.of(context).colorScheme.surface;
  }

  /// 获取边框颜色
  Color _getBorderColor(BuildContext context) {
    final isFailed = widget.message.status == MessageStatus.failed;

    if (isFailed) {
      return Theme.of(context).colorScheme.error;
    }

    return Theme.of(context).colorScheme.outline.withOpacity(0.2);
  }

  /// 解析消息内容，分离思维链和正文
  ({String? thinking, String content}) _parseMessageContent(String rawContent) {
    // 匹配 <thinking>...</thinking> 或 <think>...</think> 标签
    final thinkingRegex = RegExp(
      r'<think(?:ing)?>(.*?)</think(?:ing)?>',
      multiLine: true,
      dotAll: true,
    );

    final match = thinkingRegex.firstMatch(rawContent);

    if (match != null) {
      final thinking = match.group(1)?.trim();
      final content = rawContent.replaceAll(thinkingRegex, '').trim();
      return (thinking: thinking, content: content);
    }

    return (thinking: null, content: rawContent);
  }

  /// 构建消息内容
  Widget _buildMessageContent(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final isFailed = widget.message.status == MessageStatus.failed;
    final isStreaming = widget.message.status == MessageStatus.streaming;

    // 如果内容为空且正在流式传输，显示加载指示器
    if (widget.message.content.isEmpty && isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '正在思考...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      );
    }

    // 解析思维链和正文
    final parsed = _parseMessageContent(widget.message.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 思维链展示（如果有）
        if (parsed.thinking != null && parsed.thinking!.isNotEmpty) ...[
          _buildThinkingSection(context, parsed.thinking!),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ],

        // 用户消息使用纯文本，AI消息使用Markdown渲染
        if (isUser)
          Text(
            parsed.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          )
        else
          AppMarkdownBody(
            data: parsed.content,
            selectable: false, // SelectionArea 会处理选择
            softLineBreak: true,
          ),

        // 失败消息显示错误信息和重试按钮
        if (isFailed && widget.message.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.message.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ],

        // 流式传输中显示指示器
        if (isStreaming && widget.message.content.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建思维链展示区域
  Widget _buildThinkingSection(BuildContext context, String thinking) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          InkWell(
            onTap: () {
              setState(() {
                _isThinkingExpanded = !_isThinkingExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer
                        .withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '思维链',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer
                              .withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    _isThinkingExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer
                        .withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),

          // 思维链内容（可折叠）
          if (_isThinkingExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                thinking,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer
                          .withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建消息元数据（状态、时间等）
  Widget _buildMessageMeta(BuildContext context) {
    final formattedTime = _formatTime(widget.message.createdAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态指示器
        if (widget.message.status == MessageStatus.sending) ...[
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // 时间
        Text(
          formattedTime,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
        ),

        // Token数量（如果有）
        if (widget.message.tokenCount != null) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.data_usage,
            size: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.message.tokenCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],

        // 复制按钮
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _copyToClipboard(context),
          child: Icon(
            Icons.copy,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 复制消息内容到剪贴板
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
