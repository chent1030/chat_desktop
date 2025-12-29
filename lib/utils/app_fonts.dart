/// 应用内可选字体（仅包含可分发的开源字体 + 默认）
class AppFonts {
  static const String keyDefault = 'default';
  static const String keyNotoSansSC = 'NotoSansSC';
  static const String keyLXGWWenKai = 'LXGWWenKai';

  static const List<AppFontOption> options = [
    AppFontOption(
      key: keyDefault,
      label: '默认',
      family: null,
    ),
    AppFontOption(
      key: keyNotoSansSC,
      label: 'Noto Sans SC',
      family: 'NotoSansSC',
    ),
    AppFontOption(
      key: keyLXGWWenKai,
      label: '霞鹜文楷',
      family: 'LXGWWenKai',
    ),
  ];

  static AppFontOption optionForKey(String key) {
    for (final o in options) {
      if (o.key == key) return o;
    }
    return options.first;
  }

  static String? familyForKey(String key) => optionForKey(key).family;
}

class AppFontOption {
  final String key;
  final String label;
  final String? family;

  const AppFontOption({
    required this.key,
    required this.label,
    required this.family,
  });
}
