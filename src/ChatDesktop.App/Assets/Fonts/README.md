本目录用于放置**可分发的开源字体文件**（请勿放置微软雅黑等商业字体，避免版权风险）。

## 推荐字体（开源）

### 1) Noto Sans SC（Google 开源字体）
- 下载页（Google Fonts）：https://fonts.google.com/noto/specimen/Noto+Sans+SC
- 建议放置文件：`assets/fonts/NotoSansSC-Regular.ttf`

### 2) 思源黑体（Source Han Sans SC，开源）
- Releases：https://github.com/adobe-fonts/source-han-sans/releases
- 建议放置文件：`assets/fonts/SourceHanSansSC-Regular.otf`

### 3) 霞鹜文楷（LXGW WenKai，开源）
- Releases：https://github.com/lxgw/LxgwWenKai/releases
- 建议放置文件：`assets/fonts/LXGWWenKai-Regular.ttf`

## 放置完成后
1. 确认 `pubspec.yaml` 已配置对应 fonts（项目已预置配置，文件名需匹配）。
2. 执行 `flutter pub get`
3. 重新 `flutter run -d windows` 或 `flutter build windows`
