# 快速开始指南

欢迎使用 ChatDesktop！本指南将帮助你快速配置开发环境并启动应用。

## 📚 目录

- [系统要求](#系统要求)
- [快速启动](#快速启动)
- [详细配置](#详细配置)
- [常用命令](#常用命令)
- [故障排查](#故障排查)

## 🖥️ 系统要求

### macOS
- macOS 10.14 (Mojave) 或更高版本
- 8GB+ RAM
- 10GB+ 可用磁盘空间

### Windows
- Windows 10 (64-bit) 或更高版本
- 8GB+ RAM
- 10GB+ 可用磁盘空间
- 管理员权限

## 🚀 快速启动

### 选择你的平台

<details>
<summary><b>📱 macOS 用户点击展开</b></summary>

### 1. 安装必需软件

```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Flutter
brew install flutter

# 安装 Ruby（用于 CocoaPods）
brew install ruby
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"

# 安装 CocoaPods
gem install cocoapods
```

### 2. 安装 Xcode

从 App Store 安装 Xcode，然后运行：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### 3. 克隆并配置项目

```bash
# 克隆项目
git clone <your-repository-url> chat_desktop
cd chat_desktop

# 创建环境配置
cat > .env << 'EOF'
API_BASE_URL=http://localhost:3000
API_TOKEN=your_token_here
EOF

# 安装依赖
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. 启动应用

```bash
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
flutter run -d macos
```

📖 **详细文档**: [macOS 完整配置指南](./SETUP_MACOS.md)

</details>

<details>
<summary><b>🪟 Windows 用户点击展开</b></summary>

### 1. 安装必需软件

#### 使用 Chocolatey（推荐）

以管理员身份打开 PowerShell：

```powershell
# 安装 Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 安装 Git 和 Flutter
choco install git flutter -y
```

### 2. 安装 Visual Studio 2022

1. 下载：https://visualstudio.microsoft.com/downloads/
2. 安装 "Visual Studio 2022 Community"
3. 勾选工作负载：**使用 C++ 的桌面开发**

### 3. 克隆并配置项目

```powershell
# 克隆项目
git clone <your-repository-url> chat_desktop
cd chat_desktop

# 创建环境配置
@"
API_BASE_URL=http://localhost:3000
API_TOKEN=your_token_here
"@ | Out-File -FilePath .env -Encoding UTF8

# 安装依赖
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. 启动应用

```powershell
flutter run -d windows
```

📖 **详细文档**: [Windows 完整配置指南](./SETUP_WINDOWS.md)

</details>

## 🔧 详细配置

根据你的操作系统，查阅相应的详细配置文档：

- 📱 [macOS 完整配置指南](./SETUP_MACOS.md)
- 🪟 [Windows 完整配置指南](./SETUP_WINDOWS.md)

## 📦 项目结构

```
chat_desktop/
├── lib/
│   ├── models/          # 数据模型
│   ├── services/        # 业务逻辑服务
│   │   ├── http_client.dart      # HTTP 客户端
│   │   ├── sse_client.dart       # SSE 客户端
│   │   ├── agent_api_service.dart # 智能体 API 服务
│   │   └── ai_agent_service.dart  # 智能体缓存层
│   ├── providers/       # 状态管理（Riverpod）
│   ├── widgets/         # UI 组件
│   ├── screens/         # 页面
│   └── main.dart        # 应用入口
├── docs/                # 文档
│   ├── SETUP_MACOS.md           # macOS 配置指南
│   ├── SETUP_WINDOWS.md         # Windows 配置指南
│   ├── ARCHITECTURE.md          # 架构文档
│   └── AGENT_API_README.md      # API 使用指南
├── .env                 # 环境配置（需自己创建）
└── pubspec.yaml         # 依赖配置
```

## 💻 常用命令

### 环境检查

```bash
# 检查 Flutter 环境
flutter doctor

# 详细检查
flutter doctor -v

# 查看可用设备
flutter devices
```

### 依赖管理

```bash
# 安装依赖
flutter pub get

# 更新依赖
flutter pub upgrade

# 查看依赖树
flutter pub deps

# 检查过期依赖
flutter pub outdated
```

### 代码生成

```bash
# 生成 Isar 数据库模型
flutter pub run build_runner build

# 清理后重新生成
flutter pub run build_runner build --delete-conflicting-outputs

# 监听文件变化自动生成
flutter pub run build_runner watch
```

### 开发运行

```bash
# 启动应用（自动检测设备）
flutter run

# 指定设备启动（macOS）
flutter run -d macos

# 指定设备启动（Windows）
flutter run -d windows

# 启用详细日志
flutter run -d macos --verbose

# 热重载: 按 r
# 热重启: 按 R
# 退出: 按 q
```

### 构建发布

```bash
# macOS 构建
flutter build macos --release

# Windows 构建
flutter build windows --release

# 分析应用大小
flutter build macos --analyze-size
```

### 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/services/ai_agent_service_test.dart

# 生成覆盖率报告
flutter test --coverage
```

### 清理

```bash
# 清理构建缓存
flutter clean

# 清理并重新安装依赖
flutter clean && flutter pub get
```

## 🔍 环境变量配置

在项目根目录创建 `.env` 文件：

```bash
# API 基础 URL（必需）
API_BASE_URL=http://localhost:3000

# API 认证 Token（可选）
API_TOKEN=your_token_here
```

**重要提示**:
- ⚠️ 不要将 `.env` 文件提交到版本控制
- ⚠️ `.env` 文件已在 `.gitignore` 中排除
- ⚠️ 团队成员需要自己创建 `.env` 文件

## 🐛 故障排查

### 常见问题

<details>
<summary><b>Q: flutter doctor 提示 Android toolchain 缺失</b></summary>

**A**: 本项目是桌面应用，不需要 Android 开发环境，可以忽略此警告。

</details>

<details>
<summary><b>Q: 网络连接失败</b></summary>

**A**: 检查以下几点：
1. `.env` 文件中的 `API_BASE_URL` 是否正确
2. 后端服务是否正在运行
3. 防火墙是否允许应用访问网络

</details>

<details>
<summary><b>Q: Isar 数据库错误</b></summary>

**A**: 运行以下命令清理并重新生成：

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

</details>

<details>
<summary><b>Q: 首次启动耗时很长</b></summary>

**A**: 这是正常现象。首次编译原生代码需要 5-10 分钟，后续启动会快很多。

</details>

### 平台特定问题

- macOS 问题：查看 [macOS 故障排查](./SETUP_MACOS.md#常见问题)
- Windows 问题：查看 [Windows 故障排查](./SETUP_WINDOWS.md#常见问题)

## 📖 后续步骤

1. ✅ 配置开发环境
2. ✅ 启动应用
3. 📚 阅读 [智能体 API 使用指南](./AGENT_API_README.md)
4. 🏗️ 阅读 [架构文档](./ARCHITECTURE.md)
5. 🔧 配置后端 API 服务
6. 🚀 开始开发！

## 🎯 快速验证清单

运行以下命令验证环境配置：

```bash
# 1. 检查 Flutter 版本
flutter --version

# 2. 检查环境配置
flutter doctor

# 3. 验证项目依赖
flutter pub get

# 4. 验证代码生成
flutter pub run build_runner build

# 5. 启动应用
flutter run
```

如果所有步骤都成功，恭喜你！开发环境已配置完成。

## 🆘 获取帮助

遇到问题？尝试以下方式：

1. 📖 查阅详细配置文档：
   - [macOS 配置指南](./SETUP_MACOS.md)
   - [Windows 配置指南](./SETUP_WINDOWS.md)

2. 🔍 查看官方文档：
   - [Flutter 官方文档](https://flutter.dev/docs)
   - [Flutter 中文文档](https://flutter.cn/docs)

3. 💬 联系支持：
   - 项目 Issues: <your-repository-issues-url>
   - 技术支持: <your-support-email>

## 📝 下一步学习

- 📖 [智能体 API 集成指南](./AGENT_API_README.md) - 了解如何使用智能体 API
- 🏗️ [架构设计文档](./ARCHITECTURE.md) - 深入理解项目架构
- 🎨 [UI 组件指南](./UI_COMPONENTS.md) - 学习自定义组件（待创建）
- 🔐 [安全最佳实践](./SECURITY.md) - 安全开发指南（待创建）

---

**祝你开发愉快！** 🎉

如有任何问题，欢迎提交 Issue 或联系技术支持。
