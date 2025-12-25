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
    final isMailAction = emailMatch != null || hasMailKeyword || idMatch != null;
    final Color priorityColor = Color(task.priority.colorValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modern Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [priorityColor.withOpacity(0.16), theme.colorScheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.08)),
            ),
          ),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _pill(theme, task.isRead ? '已读' : '未读', task.isRead ? theme.colorScheme.secondary : theme.colorScheme.primary),
                        if (task.dueDate != null) _meta(theme, Icons.event, '${task.dueDate}') else _meta(theme, Icons.event_busy, '无截止'),
                        _meta(theme, Icons.source, task.source.displayName),
                      ],
                    ),
                  ],
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
                  // Tags row (if any)
                  if ((task.tags ?? '').isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          label: Text(task.tags!),
                          avatar: const Icon(Icons.label, size: 16),
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
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
                        h1: theme.textTheme.headlineSmall,
                        h2: theme.textTheme.titleLarge,
                        h3: theme.textTheme.titleMedium,
                        p: theme.textTheme.bodyMedium,
                        blockquoteDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(left: BorderSide(color: priorityColor.withOpacity(0.65), width: 4)),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else
                    Text(
                      '无描述',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
        // Footer actions
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.08))),
          ),
          child: Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('关闭'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              if (canHandle)
                FilledButton.icon(
                  icon: Icon(isMailAction ? Icons.mail : Icons.task),
                  label: const Text('处理'),
                  onPressed: () async {
                    await TaskService.instance.markTaskAsRead(task.id);
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
            ],
          ),
        ),
      ],
    );
  }
}

Widget _pill(ThemeData theme, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
  );
}

Widget _meta(ThemeData theme, IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 14), const SizedBox(width: 6), Text(text, style: theme.textTheme.labelMedium)],
    ),
  );
}
