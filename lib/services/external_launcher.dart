import 'dart:io';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../utils/constants.dart';

class ExternalLauncher {
  static Future<void> openOutlook({String? email, String? emailId}) async {
    // Prefer opening a specific mail by searching the id if provided
    if (emailId != null && emailId.isNotEmpty) {
      final uri = Uri.parse('outlook:search?text=$emailId');
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri);
        return;
      }
    }

    // Try mailto scheme (default client is usually Outlook on Windows)
    if (email != null && email.isNotEmpty) {
      final uri = Uri(scheme: 'mailto', path: email);
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri);
        return;
      }
    } else {
      final uri = Uri(scheme: 'mailto');
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri);
        return;
      }
    }

    // Windows fallback: configured Outlook path or outlook: protocol
    if (Platform.isWindows) {
      try {
        final path = AppConstants.outlookPathWindows;
        if (path != null && path.isNotEmpty) {
          await Process.start(path, [], runInShell: true);
          return;
        }
        final uri = Uri.parse('outlook:');
        if (await launcher.canLaunchUrl(uri)) {
          await launcher.launchUrl(uri);
          return;
        }
      } catch (_) {}
    }

    // macOS fallback
    if (Platform.isMacOS) {
      try {
        await Process.run('open', ['-a', 'Microsoft Outlook']);
      } catch (_) {}
    }
  }

  static Future<void> openDingTalk() async {
    // Prefer scheme
    try {
      final uri = Uri.parse('dingtalk://dingtalkclient/action/open');
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri);
        return;
      }
    } catch (_) {}

    if (Platform.isWindows) {
      try {
        final path = AppConstants.dingTalkPathWindows;
        if (path != null && path.isNotEmpty) {
          await Process.start(path, [], runInShell: true);
          return;
        }
        await Process.run('cmd', ['/c', 'start', 'DingTalk'], runInShell: true);
        return;
      } catch (_) {}
    }

    if (Platform.isMacOS) {
      try {
        await Process.run('open', ['-a', 'DingTalk']);
        return;
      } catch (_) {}
    }
  }
}

