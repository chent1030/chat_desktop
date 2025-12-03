# macOS 环境配置与启动指南

## 📋 系统要求

- macOS 10.14 (Mojave) 或更高版本
- 至少 8GB RAM
- 至少 10GB 可用磁盘空间

## 🛠️ 环境安装

### 1. 安装 Homebrew（包管理器）

打开终端，运行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安装完成后，验证：

```bash
brew --version
```

### 2. 安装 Git

```bash
brew install git
```

验证安装：

```bash
git --version
```

### 3. 安装 Flutter SDK

#### 方法一：使用 Homebrew（推荐）

```bash
# 添加 Flutter tap
brew tap flutter/flutter

# 安装 Flutter
brew install flutter
```

#### 方法二：手动安装

```bash
# 下载 Flutter SDK
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# 添加到 PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

验证安装：

```bash
flutter --version
flutter doctor
```

### 4. 安装 Xcode

#### 从 App Store 安装

1. 打开 App Store
2. 搜索 "Xcode"
3. 点击"获取"并安装（约 12GB，需要时间）

#### 配置 Xcode

```bash
# 安装 Xcode Command Line Tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 接受许可协议
sudo xcodebuild -license accept
```

### 5. 安装 CocoaPods（iOS依赖管理）

```bash
# 使用 Homebrew 安装 Ruby（如果尚未安装）
brew install ruby

# 添加 Ruby 到 PATH
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"

# 将上述路径永久添加到 shell 配置
echo 'export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 安装 CocoaPods
gem install cocoapods

# 验证安装
pod --version
```

### 6. 运行 Flutter Doctor

检查环境配置：

```bash
flutter doctor
```

期望输出：
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, on macOS 14.x ...)
[✓] Xcode - develop for iOS and macOS (Xcode 15.x)
[✓] Chrome - develop for the web
[✓] VS Code (version 1.x.x)
[✓] Connected device (1 available)
[✓] Network resources

• No issues found!
```

如果有问题，根据提示修复。

## 🔧 项目配置

### 1. 克隆项目

```bash
# 进入工作目录
cd ~/projects

# 克隆项目（替换为你的仓库地址）
git clone <your-repository-url> chat_desktop
cd chat_desktop
```

### 2. 配置环境变量

创建 `.env` 文件：

```bash
# 在项目根目录创建 .env 文件
touch .env
```

编辑 `.env` 文件，添加以下内容：

```bash
# API基础URL（必需）
API_BASE_URL=http://localhost:3000

# API认证Token（可选）
API_TOKEN=your_token_here
```

**重要**: 不要将 `.env` 文件提交到版本控制！

### 3. 安装依赖

```bash
# 安装 Flutter 依赖
flutter pub get

# 生成 Isar 数据库模型
flutter pub run build_runner build --delete-conflicting-outputs
```

期望输出：
```
Running "flutter pub get" in chat_desktop...
Resolving dependencies... (1.2s)
+ async 2.x.x
+ flutter 0.0.0 from sdk flutter
...
Got dependencies!

[INFO] Generating build script completed, took 412ms
[INFO] Reading cached asset graph completed, took 156ms
[INFO] Checking for updates since last build completed, took 689ms
[INFO] Running build completed, took 12.3s
[INFO] Caching finalized dependency graph completed, took 89ms
[INFO] Succeeded after 12.4s with 42 outputs
```

### 4. 配置 macOS 桌面权限

编辑 `macos/Runner/DebugProfile.entitlements` 和 `macos/Runner/Release.entitlements`，确保包含：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

## 🚀 启动应用

### 开发模式启动

```bash
# 方法一：使用 Flutter 命令（推荐）
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
flutter run -d macos

# 方法二：使用 flutter run（自动检测设备）
flutter run

# 方法三：使用 VS Code
# 在 VS Code 中按 F5 或点击"Run" > "Start Debugging"
```

### 查看可用设备

```bash
flutter devices
```

输出示例：
```
3 connected devices:

macOS (desktop) • macos • darwin-arm64 • macOS 14.3.1 Darwin Kernel...
Chrome (web)    • chrome • web-javascript • Google Chrome 120.0.6099.109
Edge (web)      • edge • web-javascript • Microsoft Edge 120.0.2210.77
```

### 指定设备启动

```bash
# 启动 macOS 桌面版
flutter run -d macos

# 启动 Web 版（Chrome）
flutter run -d chrome

# 启动 Web 版（Edge）
flutter run -d edge
```

### 热重载

应用运行时，在终端中按：
- `r` - 热重载（Hot Reload）
- `R` - 热重启（Hot Restart）
- `q` - 退出应用
- `h` - 显示帮助

### 构建发布版本

```bash
# 构建 macOS 应用（Release 模式）
flutter build macos --release

# 输出路径
# build/macos/Build/Products/Release/chat_desktop.app
```

## 📱 运行应用

构建完成后，可以通过以下方式运行：

```bash
# 直接运行
open build/macos/Build/Products/Release/chat_desktop.app

# 或者双击应用图标
```

## 🐛 常见问题

### 问题 1: CocoaPods 安装失败

**错误**:
```
ERROR:  While executing gem ... (Gem::FilePermissionError)
    You don't have write permissions for the /Library/Ruby/Gems/2.6.0 directory.
```

**解决方案**:
```bash
# 使用 Homebrew 安装的 Ruby
brew install ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
gem install cocoapods
```

### 问题 2: Xcode 许可未接受

**错误**:
```
Xcode requires additional components to be installed...
```

**解决方案**:
```bash
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
```

### 问题 3: Flutter doctor 提示 Android 相关错误

**说明**: 本项目是桌面应用，不需要 Android 开发环境。可以忽略 Android 相关警告。

### 问题 4: 网络连接失败

**错误**: 应用无法连接到后端 API

**解决方案**:
1. 检查 `.env` 文件中的 `API_BASE_URL` 是否正确
2. 确保后端服务正在运行
3. 检查防火墙设置

### 问题 5: Isar 数据库错误

**错误**:
```
Error: Could not find Isar library...
```

**解决方案**:
```bash
# 清理并重新生成
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 问题 6: 端口被占用

**错误**:
```
Error: Port 8080 already in use
```

**解决方案**:
```bash
# 查找占用端口的进程
lsof -i :8080

# 杀死进程
kill -9 <PID>
```

## 🔍 调试技巧

### 1. 启用详细日志

```bash
flutter run -d macos --verbose
```

### 2. 查看应用日志

```bash
# 实时查看日志
flutter logs

# 或者在应用运行时查看控制台输出
```

### 3. 使用 Flutter DevTools

```bash
# 启动 DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 在应用运行时，访问提示的 URL
```

### 4. 检查依赖

```bash
# 查看依赖树
flutter pub deps

# 检查过期的依赖
flutter pub outdated
```

## 📚 开发工具推荐

### VS Code 插件

```bash
# 必需插件
- Flutter
- Dart

# 推荐插件
- Error Lens
- GitLens
- Better Comments
- Bracket Pair Colorizer
```

### Android Studio / IntelliJ IDEA 插件

```
- Flutter
- Dart
```

## 🔄 更新 Flutter

```bash
# 更新 Flutter SDK
flutter upgrade

# 更新项目依赖
flutter pub upgrade
```

## 📦 构建分发包

### 创建 DMG 安装包（需要额外工具）

```bash
# 安装 create-dmg
brew install create-dmg

# 构建应用
flutter build macos --release

# 创建 DMG
create-dmg \
  --volname "ChatDesktop" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 185 \
  "ChatDesktop.dmg" \
  "build/macos/Build/Products/Release/chat_desktop.app"
```

## 🧪 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/services/ai_agent_service_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

## 📖 下一步

- 阅读 [AGENT_API_README.md](./AGENT_API_README.md) 了解智能体 API 使用
- 阅读 [ARCHITECTURE.md](./ARCHITECTURE.md) 了解项目架构
- 配置后端 API 服务

## 💡 提示

1. 首次启动可能需要较长时间（编译原生代码）
2. 开发时建议使用热重载功能，提高效率
3. 定期运行 `flutter doctor` 检查环境状态
4. 使用 Git 管理代码，不要提交 `.env` 文件

## 🆘 获取帮助

- Flutter 官方文档: https://flutter.dev/docs
- Flutter 中文文档: https://flutter.cn/docs
- 项目 Issues: <your-repository-issues-url>
