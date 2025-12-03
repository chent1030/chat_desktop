# Windows 打包指南

## 前置条件

### 1. 开发环境要求
- ✅ Windows 10/11 (64位)
- ✅ Flutter SDK (已安装并配置)
- ✅ Visual Studio 2022 或 Visual Studio Build Tools
- ✅ Git for Windows

### 2. 检查Flutter环境

```bash
# 检查Flutter版本
flutter --version

# 检查Windows支持
flutter doctor -v

# 确保Windows平台已启用
flutter config --enable-windows-desktop
```

确保输出中包含：
```
✓ Flutter (Channel stable, 3.x.x)
✓ Windows Version (Installed)
✓ Visual Studio - develop Windows apps
```

---

## 一、准备工作

### 1. 清理和更新依赖

```bash
# 进入项目目录
cd /path/to/chat_desktop

# 清理缓存
flutter clean

# 获取依赖
flutter pub get

# 构建项目生成必要的文件
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. 配置.env文件

确保项目根目录有正确的`.env`文件（不要打包.env.example）：

```env
AI_API_URL=https://your-api-server.com/api/chat
AI_API_KEY=your-api-key-here
AI_SSE_URL=https://your-api-server.com/api/chat/stream
```

### 3. 检查应用图标

确保Windows图标已配置：
- 位置：`windows/runner/resources/app_icon.ico`
- 如果没有，需要准备一个`.ico`文件

---

## 二、开发测试

### 1. 本地运行测试

```bash
# 以release模式运行（测试性能）
flutter run -d windows --release
```

### 2. 验证功能
- ✅ 应用启动正常
- ✅ AI对话功能正常
- ✅ 语音输入功能正常
- ✅ 任务管理功能正常
- ✅ 窗口大小调整正常

---

## 三、构建Release版本

### 方法1：标准构建（推荐）

```bash
# 构建Windows release版本
flutter build windows --release
```

构建完成后，可执行文件位置：
```
build/windows/x64/runner/Release/
├── chat_desktop.exe          # 主程序
├── data/                      # 资源文件夹
│   ├── icudtl.dat
│   ├── flutter_assets/
│   └── ...
├── flutter_windows.dll        # Flutter运行时
└── 其他DLL文件
```

### 方法2：优化构建

```bash
# 使用优化参数
flutter build windows --release --tree-shake-icons --split-debug-info=./debug-info --obfuscate
```

参数说明：
- `--tree-shake-icons`: 移除未使用的图标
- `--split-debug-info`: 分离调试信息（减小体积）
- `--obfuscate`: 代码混淆（增加安全性）

---

## 四、打包分发

### 方法1：ZIP压缩包（简单快速）

#### 步骤1：复制构建产物

```bash
# 创建发布目录
mkdir -p release/ChatDesktop

# 复制所有必要文件
cp -r build/windows/x64/runner/Release/* release/ChatDesktop/
```

#### 步骤2：添加配置文件

在`release/ChatDesktop/`目录下创建`.env`文件：
```env
AI_API_URL=https://your-production-api.com/api/chat
AI_API_KEY=production-api-key
```

#### 步骤3：创建启动脚本（可选）

创建`release/ChatDesktop/start.bat`：
```batch
@echo off
start "" "chat_desktop.exe"
```

#### 步骤4：压缩打包

```bash
# 使用7-Zip或WinRAR压缩
# 或使用PowerShell
Compress-Archive -Path release/ChatDesktop -DestinationPath ChatDesktop-v1.0.0-Windows.zip
```

### 方法2：安装程序（专业推荐）

使用**Inno Setup**创建安装程序。

#### 步骤1：安装Inno Setup

下载并安装：https://jrsoftware.org/isdl.php

#### 步骤2：创建安装脚本

创建`installer.iss`文件：

```ini
#define MyAppName "ChatDesktop"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Company"
#define MyAppURL "https://your-website.com"
#define MyAppExeName "chat_desktop.exe"

[Setup]
AppId={{YOUR-APP-GUID-HERE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=installer_output
OutputBaseFilename=ChatDesktop-Setup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"

[Files]
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".env.production"; DestDir: "{app}"; DestName: ".env"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent
```

#### 步骤3：编译安装程序

```bash
# 使用Inno Setup编译器
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

生成的安装程序位于`installer_output/ChatDesktop-Setup-1.0.0.exe`

### 方法3：MSIX包（Microsoft Store）

如果要发布到Microsoft Store：

```bash
# 添加MSIX支持
flutter pub add msix

# 配置pubspec.yaml
# msix_config:
#   display_name: ChatDesktop
#   publisher_display_name: Your Company
#   identity_name: com.yourcompany.chatdesktop
#   publisher: CN=YourPublisher
#   logo_path: assets/app_icon.png

# 构建MSIX包
flutter pub run msix:create
```

---

## 五、测试发布版本

### 1. 全新环境测试

在没有安装Flutter的Windows电脑上测试：

```bash
# 解压或安装后运行
ChatDesktop\chat_desktop.exe
```

### 2. 功能测试清单

- [ ] 应用能正常启动
- [ ] 没有缺少DLL错误
- [ ] AI对话功能正常
- [ ] 语音功能正常（需要麦克风权限）
- [ ] 数据保存和读取正常
- [ ] 窗口操作正常（最小化、最大化、关闭）
- [ ] 小窗口模式正常
- [ ] 卸载后数据清理干净

### 3. 性能测试

- [ ] 启动速度 < 3秒
- [ ] 内存占用 < 200MB
- [ ] CPU占用正常
- [ ] 无内存泄漏

---

## 六、文件结构说明

### 必需文件

```
ChatDesktop/
├── chat_desktop.exe           # 主程序（必需）
├── flutter_windows.dll        # Flutter运行时（必需）
├── data/                      # 资源文件夹（必需）
│   ├── icudtl.dat            # ICU数据文件
│   └── flutter_assets/       # Flutter资源
│       ├── fonts/
│       ├── packages/
│       └── ...
├── .env                       # 配置文件（必需）
└── msvcp140.dll等             # VC++ 运行时（可能需要）
```

### 可选文件

```
├── README.txt                 # 使用说明
├── LICENSE.txt                # 许可证
└── start.bat                  # 启动脚本
```

---

## 七、常见问题

### Q1: 运行时提示"找不到MSVCP140.dll"

**解决方案**：安装Visual C++ Redistributable

下载链接：
- [VC++ 2015-2022 x64](https://aka.ms/vs/17/release/vc_redist.x64.exe)

或在打包时包含这些DLL文件。

### Q2: 应用启动很慢

**解决方案**：
1. 使用`--release`模式构建
2. 关闭调试日志
3. 优化资源加载

### Q3: 打包后体积很大

**优化方法**：
```bash
# 使用优化参数
flutter build windows --release --tree-shake-icons --split-debug-info=./debug-info

# 压缩分发包
# 使用7-Zip ULTRA压缩
```

典型体积：
- 未优化：~50MB
- 优化后：~30-40MB
- 压缩后：~15-20MB

### Q4: .env文件在哪里？

**位置**：
- 开发模式：项目根目录
- 打包后：与exe同目录

### Q5: 如何更新应用配置？

**方法1**：修改.env文件
```env
AI_API_URL=new-url
AI_API_KEY=new-key
```

**方法2**：重新打包

### Q6: 如何自定义应用图标？

**步骤**：
1. 准备`.ico`文件（256x256或更大）
2. 放到`windows/runner/resources/app_icon.ico`
3. 修改`windows/runner/Runner.rc`
4. 重新构建

### Q7: 打包后无法连接到API

**检查**：
1. `.env`文件是否存在
2. API_URL是否正确
3. 网络防火墙设置
4. 查看日志文件

### Q8: 如何生成APP GUID？

使用PowerShell：
```powershell
[guid]::NewGuid()
```

---

## 八、发布检查清单

### 打包前
- [ ] 更新版本号（pubspec.yaml）
- [ ] 测试所有功能
- [ ] 更新CHANGELOG.md
- [ ] 准备.env.production文件
- [ ] 更新README和文档

### 打包后
- [ ] 在干净系统测试
- [ ] 检查文件完整性
- [ ] 验证配置文件
- [ ] 测试安装/卸载
- [ ] 扫描病毒（可选）

### 发布
- [ ] 上传到发布平台
- [ ] 创建Release Notes
- [ ] 通知用户更新
- [ ] 监控反馈

---

## 九、自动化脚本

### build.bat（一键构建）

创建`build.bat`脚本：

```batch
@echo off
echo ================================
echo ChatDesktop Windows Build Script
echo ================================
echo.

echo [1/5] Cleaning...
flutter clean

echo [2/5] Getting dependencies...
flutter pub get

echo [3/5] Running code generator...
flutter pub run build_runner build --delete-conflicting-outputs

echo [4/5] Building Windows release...
flutter build windows --release --tree-shake-icons

echo [5/5] Copying files...
mkdir release 2>nul
xcopy /E /I /Y build\windows\x64\runner\Release release\ChatDesktop
copy .env.production release\ChatDesktop\.env

echo.
echo ================================
echo Build completed!
echo Output: release\ChatDesktop\
echo ================================
pause
```

运行：
```bash
build.bat
```

---

## 十、版本管理

### 版本号规则

使用语义化版本：`MAJOR.MINOR.PATCH`

- **MAJOR**: 不兼容的API修改
- **MINOR**: 向下兼容的功能性新增
- **PATCH**: 向下兼容的问题修正

### 更新版本

修改`pubspec.yaml`：
```yaml
version: 1.0.0+1  # version+build_number
```

修改`windows/runner/Runner.rc`（可选）：
```c
#define VERSION_AS_NUMBER 1,0,0
#define VERSION_AS_STRING "1.0.0"
```

---

## 十一、发布平台

### 1. GitHub Releases
- 上传ZIP或安装程序
- 编写Release Notes
- 标记版本Tag

### 2. 自建服务器
- 提供下载链接
- 实现自动更新检查

### 3. Microsoft Store（可选）
- 需要开发者账号
- 使用MSIX打包
- 经过审核流程

---

## 附录：快速参考

### 常用命令

```bash
# 检查环境
flutter doctor

# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 运行（release）
flutter run -d windows --release

# 构建release
flutter build windows --release

# 查看日志
flutter logs
```

### 目录结构

```
chat_desktop/
├── lib/                    # 源代码
├── windows/                # Windows平台代码
├── build/                  # 构建输出
│   └── windows/
│       └── x64/
│           └── runner/
│               └── Release/
├── pubspec.yaml           # 项目配置
├── .env                   # 环境配置
└── build.bat             # 构建脚本
```

---

## 支持

如有问题，请查看：
- Flutter官方文档：https://docs.flutter.dev/
- Windows桌面支持：https://docs.flutter.dev/platform-integration/windows/building
- 项目Issue：（您的项目链接）

---

**最后更新**: 2025-12-03
**文档版本**: 1.0.0
