import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/voice_input_button.dart';
import '../../services/speech_to_text_service.dart';

/// 聊天输入框 Widget
/// 提供消息输入和发送功能,支持多行输入和快捷键
class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isEnabled;
  final String hintText;

  const ChatInput({
    super.key,
    required this.onSend,
    this.isEnabled = true,
    this.hintText = '输入消息...',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
    setState(() {
      _isComposing = false;
    });

    // 重新聚焦输入框
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 输入框
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 40,
                maxHeight: 200,
              ),
              decoration: BoxDecoration(
                color: widget.isEnabled
                    ? Theme.of(context).colorScheme.surfaceVariant
                    : Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: _focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.isEnabled,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                onSubmitted: (_) {
                  if (_isComposing) {
                    _handleSubmit();
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 语音输入按钮
          VoiceInputButton(
            enabled: widget.isEnabled,
            onRecordComplete: (audioPath) async {
              try {

                final text = await SpeechToTextService.instance.uploadAndTranscribe(
                  audioPath,
                  'https://ipaas.catl.com/gateway/outside/ipaas/LY_BASIC/outer_LY_BASIC_voiceToText'
                );
                _controller.text = text;
                setState(() {
                  _isComposing = true;
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('语音转文字失败: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
            },
            onRecordCancel: () {
              print('✓ 用户取消了录音');
            },
          ),

          const SizedBox(width: 4),

          // 发送按钮
          IconButton(
            onPressed: _isComposing && widget.isEnabled ? _handleSubmit : null,
            icon: Icon(
              Icons.send,
              color: _isComposing && widget.isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            tooltip: '发送消息 (Cmd/Ctrl + Enter)',
            style: IconButton.styleFrom(
              backgroundColor: _isComposing && widget.isEnabled
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// 带快捷键支持的聊天输入框
class ChatInputWithShortcuts extends StatefulWidget {
  final Function(String) onSend;
  final bool isEnabled;
  final String hintText;
  final VoidCallback? onCancel;

  const ChatInputWithShortcuts({
    super.key,
    required this.onSend,
    this.isEnabled = true,
    this.hintText = '输入消息 (Cmd/Ctrl+Enter 发送)...',
    this.onCancel,
  });

  @override
  State<ChatInputWithShortcuts> createState() =>
      _ChatInputWithShortcutsState();
}

class _ChatInputWithShortcutsState extends State<ChatInputWithShortcuts> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
    setState(() {
      _isComposing = false;
    });

    // 重新聚焦输入框
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Cmd/Ctrl + Enter 发送消息
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            const ActivateIntent(),
        // Escape 取消
        if (widget.onCancel != null)
          const SingleActivator(LogicalKeyboardKey.escape):
              const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (_isComposing && widget.isEnabled) {
                _handleSubmit();
              }
              return null;
            },
          ),
          if (widget.onCancel != null)
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                widget.onCancel!();
                return null;
              },
            ),
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 输入框
              Container(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 200,
                ),
                decoration: BoxDecoration(
                  color: widget.isEnabled
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                    width: _focusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.trim().isNotEmpty;
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 底部操作栏
              Row(
                children: [
                  // 语音输入按钮
                  VoiceInputButton(
                    enabled: widget.isEnabled,
                    size: 36,
                    onRecordComplete: (audioPath) {
                      _controller.text = '[语音消息: $audioPath]';
                      setState(() {
                        _isComposing = true;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('语音录制完成'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onRecordCancel: () {
                      print('✓ 用户取消了录音');
                    },
                  ),

                  const SizedBox(width: 8),

                  // 快捷键提示
                  Expanded(
                    child: Text(
                      'Cmd/Ctrl+Enter 发送',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                    ),
                  ),

                  // 取消按钮
                  if (widget.onCancel != null) ...[
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // 发送按钮
                  ElevatedButton.icon(
                    onPressed:
                        _isComposing && widget.isEnabled ? _handleSubmit : null,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('发送'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
