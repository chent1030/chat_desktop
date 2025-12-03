# ChatDesktop - 待办事项与AI智能助手桌面应用

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

一个基于 Flutter 构建的跨平台桌面应用，集成待办事项管理和 AI 智能助手功能。

[快速开始](./docs/GETTING_STARTED.md) •
[macOS 配置](./docs/SETUP_MACOS.md) •
[Windows 配置](./docs/SETUP_WINDOWS.md) •
[架构文档](./docs/ARCHITECTURE.md)

</div>

---

## ✨ 功能特性

### 📝 待办事项管理
- ✅ 创建、编辑、删除待办任务
- 🏷️ 任务分类和标签
- ⏰ 截止日期提醒
- 📊 任务统计和进度跟踪

### 🤖 AI 智能助手
- 💬 多智能体支持（GPT-4、Claude 等）
- 📡 实时同步智能体列表（SSE）
- 💾 离线缓存，网络失败自动降级
- 🎯 智能体切换和使用统计

### 🪟 桌面体验
- 🖥️ 原生 macOS 和 Windows 支持
- 🔄 小窗口模式
- ⌨️ 快捷键支持
- 🎨 现代化 Material Design UI

## 🚀 快速开始

### 一键启动（macOS）

```bash
# 克隆并配置
git clone <repository-url> chat_desktop && cd chat_desktop

# 配置环境
cat > .env << 'EOF'
API_BASE_URL=http://localhost:3000
API_TOKEN=your_token_here
EOF

# 安装依赖
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 启动应用
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
flutter run -d macos
```

### 一键启动（Windows）

```powershell
# 克隆并配置
git clone <repository-url> chat_desktop; cd chat_desktop

# 配置环境
@"
API_BASE_URL=http://localhost:3000
API_TOKEN=your_token_here
"@ | Out-File -FilePath .env -Encoding UTF8

# 安装依赖
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 启动应用
flutter run -d windows
```

## 📚 完整文档

- 📖 [快速入门指南](./docs/GETTING_STARTED.md) - 新手必读
- 📱 [macOS 环境配置](./docs/SETUP_MACOS.md) - macOS 详细配置
- 🪟 [Windows 环境配置](./docs/SETUP_WINDOWS.md) - Windows 详细配置
- 🤖 [智能体 API 使用](./docs/AGENT_API_README.md) - API 集成指南
- 🏗️ [架构设计文档](./docs/ARCHITECTURE.md) - 技术架构详解

## 🛠️ 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Riverpod 2.5
- **本地存储**: Isar 3.1
- **网络请求**: Dio 5.4
- **实时同步**: Server-Sent Events

## 💻 开发命令

```bash
# 环境检查
flutter doctor

# 启动应用
flutter run -d macos      # macOS
flutter run -d windows    # Windows

# 运行测试
flutter test

# 构建发布版
flutter build macos --release
flutter build windows --release
```

## 🐛 问题反馈

遇到问题？
1. 查看 [常见问题](./docs/GETTING_STARTED.md#故障排查)
2. 提交 [Issue](https://github.com/your-repo/issues)

## 📄 许可证

MIT License - 详见 [LICENSE](./LICENSE)

---

**⭐ 如果这个项目对你有帮助，请给我们一个星标！**
