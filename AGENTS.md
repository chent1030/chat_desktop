# Repository Guidelines（仓库指南）

## 项目结构与模块组织
- Flutter 应用：`lib/`（Dart 源码）、`assets/`、`test/`、平台目录（`windows/`、`macos/`、`linux/`）。
- Windows Runner：`windows/runner/`（Flutter 宿主程序）。
- 原生悬浮窗（Win10+）：`windows/native_floating_ball/`（C++ WIC/D2D、毛玻璃气泡、IPC）。
- 图标/媒体：如 `assets/static_logo.ico`、`dynamic_logo.gif`、`unread_logo.gif`。

## 构建、测试与开发命令
- 安装依赖：`flutter pub get`
- 运行（macOS）：`flutter run -d macos`
- 运行（Windows）：`flutter run -d windows`
- 构建（Windows）：`flutter build windows`
- 测试：`flutter test`
- 原生悬浮窗（可选独立调试）：
  - `cmake -S windows/native_floating_ball -B build -G Ninja`
  - `cmake --build build --config Debug`

## 代码风格与命名约定
- Dart：2 空格缩进；类型 `UpperCamelCase`，成员 `lowerCamelCase`，文件 `snake_case.dart`。
- 避免使用数据库保留名（如裸 `uuid`），优先领域名：`taskId`/`taskUuid`。
- 格式化：`dart format .`；保持 import 有序；避免单字母变量。
- C++：延续现有风格；类名 `PascalCase`，方法 `lowerCamelCase`，文件 `snake_case.cpp/h`。

## 测试规范
- 单元/组件测试在 `test/`，目录结构与 `lib/` 对应。
- 测试文件命名 `*_test.dart`；保证快速、可重复。
- 本地运行：`flutter test`；UI 截图放到 PR 说明，不入库。

## Commit 与 Pull Request 规范
- 遵循 Conventional Commits：`feat:`、`fix:`、`refactor:`、`build(windows):`、`chore:`。
- PR 必须包含：变更目的、关联 issue、影响平台、复现步骤、UI 前/后对比（图或短视频）。
- Windows 相关问题请附 `error.log` 关键片段与失败的 MSBuild/CMake 行。

## 安全与配置提示
- MQTT 凭据通过环境变量提供（禁止提交）：`MQTT_USERNAME`、`MQTT_PASSWORD`。
- 启动辅助读取运行时环境，避免硬编码密钥。
- 原生端要求媒体与可执行文件同目录（如 `dynamic_logo.gif`、`unread_logo.gif`）。

## 平台注意事项
- Windows 悬浮窗：无边框、透明、可拖拽、置顶；通过 IPC 与主程序通讯。
- macOS/Windows UI 尽量保持一致；如用到平台特性需有降级策略。
- Windows 应用图标：使用 `assets/static_logo.ico`。

## 语言
- 始终以**中文**回复用户
- 注释除cpp中，一律使用**中文**