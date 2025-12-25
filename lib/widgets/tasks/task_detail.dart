import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/task_service.dart';
import '../../services/external_launcher.dart';
import '../../models/task.dart';

class TaskDetailDialog extends StatelessWidget {
  final Task task;
  const TaskDetailDialog({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          child: TaskDetailDialog(task: task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagsLower = (task.tags ?? '').toLowerCase();
    final desc = task.description ?? '';
    final descLower = desc.toLowerCase();
    // 匹配邮箱/关键字/邮件ID
    final emailRegex = RegExp(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}");
    final emailMatch = emailRegex.firstMatch(task.tags ?? '') ?? emailRegex.firstMatch(desc);
    final hasMailKeyword = tagsLower.contains('邮件') || tagsLower.contains('邮箱') || descLower.contains('邮件') || descLower.contains('邮箱');
    final idRegex = RegExp(r"(?:邮件ID|郵件ID)[:：]\s*(\S+)");
    final idMatch = idRegex.firstMatch(desc);
    final canHandle = tagsLower.contains('补删卡') || emailMatch != null || hasMailKeyword || idMatch != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(task.priority.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (task.dueDate != null)
                        Chip(
                          avatar: const Icon(Icons.event, size: 16),
                          label: Text('${task.dueDate}'),
                       ),
                      if ((task.tags ?? '').isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.label, size: 16),
                          label: Text(task.tags!),
                        ),
                      Chip(
                        avatar: const Icon(Icons.source, size: 16),
                        label: Text(task.source.displayName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Markdown description
                  if ((task.description ?? '').isNotEmpty)
                    MarkdownBody(
                      data: task.description!,
                      selectable: true,
                      softLineBreak: true,
                      onTapLink: (text, href, title) async {
                        if (href == null) return;
                        final uri = Uri.parse(href);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        blockquoteDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    Text(
                      '无描述',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                  if (canHandle) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('处理'),
                        onPressed: () async {
                          // 标记为已读
                          await TaskService.instance.markTaskAsRead(task.id);

                          // 提取邮件地址与邮件ID
                          final email = emailMatch?.group(0);
                          final emailId = idMatch != null ? idMatch.group(1) : null;

                          try {
                            if (tagsLower.contains('补删卡')) {
                              await ExternalLauncher.openDingTalk();
                            } else {
                              await ExternalLauncher.openOutlook(email: email, emailId: emailId);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('处理失败: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
