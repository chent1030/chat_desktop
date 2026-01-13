import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// 应用内统一的 Markdown 渲染封装
class AppMarkdown {
  static MarkdownStyleSheet styleSheet(ThemeData theme, {Color? accentColor}) {
    final accent = accentColor ?? theme.colorScheme.primary;
    final dividerColor = theme.colorScheme.outline.withOpacity(0.25);

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor),
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent.withOpacity(0.65), width: 4)),
      ),
      // `---`/`***` 等水平分割线：默认样式在桌面端会显得过粗，这里统一变细
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor, width: 1)),
      ),
    );
  }

  static Future<void> launchLink(String href) async {
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class AppMarkdownBody extends StatelessWidget {
  final String data;
  final bool selectable;
  final bool softLineBreak;
  final Color? accentColor;

  const AppMarkdownBody({
    super.key,
    required this.data,
    this.selectable = true,
    this.softLineBreak = true,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: data,
      selectable: selectable,
      softLineBreak: softLineBreak,
      onTapLink: (text, href, title) async {
        if (href == null) return;
        await AppMarkdown.launchLink(href);
      },
      styleSheet: AppMarkdown.styleSheet(theme, accentColor: accentColor),
    );
  }
}

