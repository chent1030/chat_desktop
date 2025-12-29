import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/config_service.dart';
import '../utils/app_fonts.dart';

/// 字体选择（Key），持久化到 SharedPreferences
final appFontKeyProvider =
    StateNotifierProvider<AppFontKeyNotifier, String>((ref) {
  return AppFontKeyNotifier();
});

final appFontFamilyProvider = Provider<String?>((ref) {
  final key = ref.watch(appFontKeyProvider);
  return AppFonts.familyForKey(key);
});

class AppFontKeyNotifier extends StateNotifier<String> {
  AppFontKeyNotifier() : super(_initialKey());

  static String _initialKey() {
    try {
      return ConfigService.instance.fontKey;
    } catch (_) {
      return AppFonts.keyDefault;
    }
  }

  Future<void> setFontKey(String key) async {
    if (key == state) return;
    state = key;
    try {
      await ConfigService.instance.setFontKey(key);
    } catch (_) {}
  }
}
