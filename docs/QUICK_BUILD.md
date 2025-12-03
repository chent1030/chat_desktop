# Windows 打包快速指南

## 🚀 快速开始（3步完成）

### 方式1：使用自动化脚本（推荐）

```bash
# 1. 双击运行构建脚本
build_windows.bat

# 2. 等待构建完成（约2-5分钟）

# 3. 在 release/ChatDesktop/ 找到可执行文件
```

### 方式2：手动命令行

```bash
# 1. 清理和构建
flutter clean
flutter pub get
flutter build windows --release

# 2. 查看输出
cd build/windows/x64/runner/Release
```

---

## 📦 三种打包方式对比

| 方式 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| **ZIP压缩** | 简单快速，即刻可用 | 需手动解压，看起来不专业 | 内部测试、快速分发 |
| **安装程序** | 专业、可创建快捷方式 | 需要Inno Setup | 正式发布、商业产品 |
| **MSIX包** | 可发布到商店 | 配置复杂 | Microsoft Store发布 |

---

## 📋 打包步骤详解

### 步骤1：准备环境
```bash
# 检查Flutter
flutter doctor

# 确保Windows支持已启用
flutter config --enable-windows-desktop
```

### 步骤2：配置文件
确保项目根目录有`.env`文件：
```env
AI_API_URL=https://your-api.com/v1/chat-messages
AI_API_KEY=your-api-key
```

### 步骤3：执行构建
```bash
# 方式A：使用脚本（推荐）
build_windows.bat

# 方式B：手动命令
flutter build windows --release
```

### 步骤4：测试
```bash
# 运行构建的程序
release\ChatDesktop\chat_desktop.exe
```

### 步骤5：分发

**选项A：ZIP压缩包**
```bash
# 压缩 release/ChatDesktop/ 文件夹
# 命名为: ChatDesktop-v1.0.0-Windows.zip
```

**选项B：安装程序（推荐）**
```bash
# 1. 安装 Inno Setup
# 下载: https://jrsoftware.org/isdl.php

# 2. 编译安装脚本
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss

# 3. 输出在 installer_output/ 目录
```

---

## 🎯 快速参考

### 文件位置
```
项目根目录/
├── build_windows.bat         # 自动构建脚本（双击运行）
├── installer.iss             # Inno Setup配置
├── .env                      # API配置（必需）
└── release/                  # 构建输出
    └── ChatDesktop/
        ├── chat_desktop.exe  # 主程序
        ├── *.dll            # 依赖库
        ├── data/            # 资源文件
        └── .env             # 配置文件
```

### 常用命令
```bash
# 构建
flutter build windows --release

# 优化构建（更小体积）
flutter build windows --release --tree-shake-icons --split-debug-info=./debug

# 运行
flutter run -d windows --release

# 清理
flutter clean
```

### 体积参考
- 未优化：~50MB
- 优化后：~30-40MB
- 压缩后：~15-20MB

---

## ⚠️ 常见问题

### Q: 构建失败，提示Visual Studio未安装
**A**: 安装 [Visual Studio 2022 Community](https://visualstudio.microsoft.com/) 并选择"使用C++的桌面开发"

### Q: 运行提示缺少MSVCP140.dll
**A**: 安装 [VC++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

### Q: .env文件在哪里？
**A**: 项目根目录，与pubspec.yaml同级。如果没有，复制`.env.example`并重命名

### Q: 如何更改应用图标？
**A**: 替换 `windows/runner/resources/app_icon.ico`，然后重新构建

### Q: 打包后无法连接API
**A**: 检查`release/ChatDesktop/.env`文件中的API配置是否正确

---

## 📊 完整流程图

```
准备代码
  ↓
配置.env文件
  ↓
运行 build_windows.bat
  ↓
┌─────────────┬─────────────┐
│             │             │
ZIP压缩      安装程序      MSIX包
  ↓             ↓             ↓
分发         分发          商店
```

---

## 🔗 相关文档

- **详细文档**: [WINDOWS_BUILD.md](./WINDOWS_BUILD.md) - 完整的打包指南
- **环境配置**: [SETUP_WINDOWS.md](./SETUP_WINDOWS.md) - Windows开发环境设置
- **AI集成**: [DIFY_INTEGRATION.md](./DIFY_INTEGRATION.md) - Dify API集成说明
- **Conversation ID**: [CONVERSATION_ID_USAGE.md](./CONVERSATION_ID_USAGE.md) - 对话管理

---

## ⏱️ 预计时间

| 步骤 | 时间 |
|------|------|
| 环境检查 | 1分钟 |
| 构建Release | 2-5分钟 |
| 创建安装程序 | 1分钟 |
| 测试 | 5分钟 |
| **总计** | **10-15分钟** |

---

## 📝 发布清单

打包前：
- [ ] 更新版本号（pubspec.yaml）
- [ ] 测试所有功能正常
- [ ] 配置生产环境.env
- [ ] 更新CHANGELOG

打包：
- [ ] 运行build_windows.bat
- [ ] 测试构建的exe
- [ ] 创建安装程序（可选）

发布：
- [ ] 压缩或创建安装包
- [ ] 在干净系统测试
- [ ] 上传到发布平台
- [ ] 编写Release Notes

---

**需要帮助？** 查看 [WINDOWS_BUILD.md](./WINDOWS_BUILD.md) 获取详细说明
