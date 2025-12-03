# Windows 环境配置与启动指南

## 📋 系统要求

- Windows 10 (64-bit) 或更高版本
- 至少 8GB RAM
- 至少 10GB 可用磁盘空间
- 管理员权限

## 🛠️ 环境安装

### 1. 安装 Git

#### 下载并安装

1. 访问 https://git-scm.com/download/win
2. 下载最新版本的 Git for Windows
3. 运行安装程序，推荐设置：
   - 勾选 "Git Bash Here"
   - 勾选 "Git GUI Here"
   - 选择 "Use Git from Git Bash only" 或 "Use Git from the Windows Command Prompt"

#### 验证安装

打开 PowerShell 或 Command Prompt：

```powershell
git --version
```

### 2. 安装 Flutter SDK

#### 方法一：使用 Chocolatey（推荐）

```powershell
# 以管理员身份打开 PowerShell

# 安装 Chocolatey（如果尚未安装）
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 使用 Chocolatey 安装 Flutter
choco install flutter -y
```

#### 方法二：手动安装

1. 下载 Flutter SDK:
   - 访问 https://flutter.dev/docs/get-started/install/windows
   - 下载最新的稳定版 ZIP 文件

2. 解压到合适的位置（避免包含空格的路径）：
   ```
   C:\src\flutter
   ```

3. 添加到系统环境变量 PATH：
   - 右键点击"此电脑" → "属性"
   - 点击"高级系统设置"
   - 点击"环境变量"
   - 在"系统变量"中找到 `Path`，点击"编辑"
   - 点击"新建"，添加：`C:\src\flutter\bin`
   - 点击"确定"保存

#### 验证安装

```powershell
flutter --version
flutter doctor
```

### 3. 安装 Visual Studio（用于 Windows 桌面开发）

#### 下载并安装

1. 访问 https://visualstudio.microsoft.com/downloads/
2. 下载 **Visual Studio 2022 Community**（免费版）
3. 运行安装程序

#### 选择工作负载

在安装程序中，勾选以下工作负载：

```
✓ 使用 C++ 的桌面开发 (Desktop development with C++)
  ├─ MSVC v143 - VS 2022 C++ x64/x86 生成工具
  ├─ Windows 10 SDK 或 Windows 11 SDK
  └─ C++ CMake tools for Windows
```

**重要**: 安装大小约 7-10GB，需要较长时间。

#### 验证安装

```powershell
# 检查 Flutter 是否识别到 Visual Studio
flutter doctor -v
```

期望输出中包含：
```
[✓] Visual Studio - develop for Windows (Visual Studio Community 2022 17.x.x)
```

### 4. 运行 Flutter Doctor

检查所有环境配置：

```powershell
flutter doctor
```

期望输出：
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, on Microsoft Windows 11 ...)
[✓] Windows Version (Installed version of Windows is 10 or higher)
[✓] Visual Studio - develop for Windows (Visual Studio Community 2022 17.x.x)
[✓] VS Code (version 1.x.x)
[✓] Connected device (2 available)
[✓] Network resources

• No issues found!
```

**说明**: Android Studio 和 Android toolchain 不是必需的（本项目是桌面应用）。

## 🔧 项目配置

### 1. 克隆项目

```powershell
# 进入工作目录
cd C:\Users\YourName\projects

# 克隆项目（替换为你的仓库地址）
git clone <your-repository-url> chat_desktop
cd chat_desktop
```

### 2. 配置环境变量

在项目根目录创建 `.env` 文件：

```powershell
# 使用记事本创建文件
notepad .env
```

在打开的记事本中，添加以下内容：

```bash
# API基础URL（必需）
API_BASE_URL=http://localhost:3000

# API认证Token（可选）
API_TOKEN=your_token_here
```

保存并关闭。

**重要**: 不要将 `.env` 文件提交到版本控制！

### 3. 安装依赖

```powershell
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

### 4. 配置 Windows 桌面权限

编辑 `windows/runner/main.cpp`，确保包含必要的权限设置（通常已配置好）。

## 🚀 启动应用

### 开发模式启动

```powershell
# 方法一：使用 Flutter 命令（推荐）
flutter run -d windows

# 方法二：使用 flutter run（自动检测设备）
flutter run

# 方法三：使用 VS Code
# 在 VS Code 中按 F5 或点击"运行" > "启动调试"
```

### 查看可用设备

```powershell
flutter devices
```

输出示例：
```
3 connected devices:

Windows (desktop) • windows • windows-x64 • Microsoft Windows 11 Home...
Chrome (web)      • chrome • web-javascript • Google Chrome 120.0.6099.109
Edge (web)        • edge • web-javascript • Microsoft Edge 120.0.2210.77
```

### 指定设备启动

```powershell
# 启动 Windows 桌面版
flutter run -d windows

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

```powershell
# 构建 Windows 应用（Release 模式）
flutter build windows --release

# 输出路径
# build\windows\runner\Release\chat_desktop.exe
```

## 📱 运行应用

构建完成后，可以通过以下方式运行：

```powershell
# 方法一：使用命令行
start build\windows\runner\Release\chat_desktop.exe

# 方法二：双击 EXE 文件
# 在文件资源管理器中导航到 build\windows\runner\Release\
# 双击 chat_desktop.exe
```

## 🐛 常见问题

### 问题 1: Visual Studio 未正确配置

**错误**:
```
Visual Studio not found; this is necessary for Windows development.
```

**解决方案**:
1. 确保安装了 Visual Studio 2022（不是 VS Code）
2. 确保安装了 "使用 C++ 的桌面开发" 工作负载
3. 重新运行 `flutter doctor`

### 问题 2: Windows SDK 缺失

**错误**:
```
Windows 10 SDK is not installed.
```

**解决方案**:
1. 打开 Visual Studio Installer
2. 点击"修改"
3. 勾选 "Windows 10 SDK" 或 "Windows 11 SDK"
4. 点击"修改"并等待安装完成

### 问题 3: 编译错误 - 找不到 MSBuild

**错误**:
```
Error: Unable to find suitable Visual Studio toolchain.
```

**解决方案**:
```powershell
# 确保 Visual Studio 路径在 PATH 环境变量中
# 添加以下路径（根据你的安装路径调整）:
C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin
```

### 问题 4: 防火墙阻止

**错误**: 应用无法连接到后端 API

**解决方案**:
1. 打开 Windows 防火墙设置
2. 允许应用通过防火墙
3. 或者临时禁用防火墙进行测试

### 问题 5: PowerShell 执行策略限制

**错误**:
```
无法加载文件 *.ps1，因为在此系统上禁止运行脚本
```

**解决方案**:
```powershell
# 以管理员身份运行 PowerShell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题 6: 路径包含中文或空格

**错误**: 各种编译错误

**解决方案**:
- 将项目移动到不包含中文和空格的路径
- 推荐路径：`C:\projects\chat_desktop`

### 问题 7: Isar 数据库错误

**错误**:
```
Error: Could not find Isar library...
```

**解决方案**:
```powershell
# 清理并重新生成
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 问题 8: 端口被占用

**错误**:
```
Error: Port 8080 already in use
```

**解决方案**:
```powershell
# 查找占用端口的进程
netstat -ano | findstr :8080

# 杀死进程（替换 <PID> 为实际的进程ID）
taskkill /PID <PID> /F
```

## 🔍 调试技巧

### 1. 启用详细日志

```powershell
flutter run -d windows --verbose
```

### 2. 查看应用日志

```powershell
# 实时查看日志
flutter logs

# 或者在应用运行时查看控制台输出
```

### 3. 使用 Flutter DevTools

```powershell
# 启动 DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 在应用运行时，访问提示的 URL
```

### 4. 检查依赖

```powershell
# 查看依赖树
flutter pub deps

# 检查过期的依赖
flutter pub outdated
```

## 📚 开发工具推荐

### VS Code 插件

```
必需插件:
- Flutter
- Dart

推荐插件:
- Error Lens
- GitLens
- Better Comments
- Bracket Pair Colorizer
- C/C++ (用于调试 Windows 原生代码)
```

### Android Studio / IntelliJ IDEA 插件

```
- Flutter
- Dart
```

## 🔄 更新 Flutter

```powershell
# 更新 Flutter SDK
flutter upgrade

# 更新项目依赖
flutter pub upgrade
```

## 📦 构建分发包

### 创建安装程序（使用 Inno Setup）

#### 1. 安装 Inno Setup

1. 下载：https://jrsoftware.org/isdl.php
2. 安装 Inno Setup Compiler

#### 2. 创建安装脚本

在项目根目录创建 `installer.iss`：

```ini
[Setup]
AppName=ChatDesktop
AppVersion=1.0.0
DefaultDirName={pf}\ChatDesktop
DefaultGroupName=ChatDesktop
OutputDir=installer
OutputBaseFilename=ChatDesktop-Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\ChatDesktop"; Filename: "{app}\chat_desktop.exe"
Name: "{group}\Uninstall ChatDesktop"; Filename: "{uninstallexe}"
Name: "{commondesktop}\ChatDesktop"; Filename: "{app}\chat_desktop.exe"

[Run]
Filename: "{app}\chat_desktop.exe"; Description: "Launch ChatDesktop"; Flags: postinstall nowait skipifsilent
```

#### 3. 构建安装程序

```powershell
# 先构建 Release 版本
flutter build windows --release

# 使用 Inno Setup 编译
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

输出文件：`installer\ChatDesktop-Setup.exe`

### 创建免安装版（绿色版）

```powershell
# 构建应用
flutter build windows --release

# 压缩整个 Release 文件夹
Compress-Archive -Path build\windows\runner\Release\* -DestinationPath ChatDesktop-Portable.zip
```

## 🧪 运行测试

```powershell
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test\services\ai_agent_service_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

## 🎯 性能优化

### 减小应用体积

```powershell
# 使用 tree-shaking
flutter build windows --release --split-debug-info=debug_symbols --obfuscate

# 分析应用大小
flutter build windows --analyze-size
```

### 启用优化编译

在 `windows/runner/CMakeLists.txt` 中添加：

```cmake
# 添加优化标志
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2")
```

## 📖 下一步

- 阅读 [AGENT_API_README.md](./AGENT_API_README.md) 了解智能体 API 使用
- 阅读 [ARCHITECTURE.md](./ARCHITECTURE.md) 了解项目架构
- 配置后端 API 服务

## 💡 提示

1. **首次启动** 可能需要较长时间（编译原生代码，约 5-10 分钟）
2. **杀毒软件** 可能会误报，需要添加白名单
3. **管理员权限** 某些操作可能需要管理员权限
4. **路径问题** 避免使用包含中文或空格的路径
5. **防火墙** 需要允许应用访问网络

## 🔐 安全提示

1. 不要在代码中硬编码 API_TOKEN
2. 使用 `.gitignore` 排除 `.env` 文件
3. 发布版本前移除调试信息
4. 考虑使用代码签名证书（避免 SmartScreen 警告）

## 🆘 获取帮助

- Flutter 官方文档: https://flutter.dev/docs
- Flutter 中文文档: https://flutter.cn/docs
- Visual Studio 文档: https://docs.microsoft.com/visualstudio
- 项目 Issues: <your-repository-issues-url>

## 📌 快速命令参考

```powershell
# 环境检查
flutter doctor -v

# 安装依赖
flutter pub get

# 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 启动开发模式
flutter run -d windows

# 构建发布版本
flutter build windows --release

# 运行测试
flutter test

# 清理构建缓存
flutter clean
```

## 🚀 快速启动清单

- [ ] 安装 Git
- [ ] 安装 Flutter SDK
- [ ] 安装 Visual Studio 2022（包含 C++ 桌面开发）
- [ ] 运行 `flutter doctor` 检查环境
- [ ] 克隆项目代码
- [ ] 创建 `.env` 配置文件
- [ ] 运行 `flutter pub get`
- [ ] 运行 `flutter pub run build_runner build`
- [ ] 启动应用 `flutter run -d windows`
- [ ] 测试后端连接

完成以上步骤后，你的开发环境就配置完成了！
