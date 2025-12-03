# macOS上构建Windows应用指南

## ⚠️ 重要说明

**Flutter无法在macOS上直接构建Windows应用**，因为需要Windows特定的编译工具（Visual Studio等）。

但您有以下几种解决方案：

---

## 方案1：GitHub Actions（推荐，免费）⭐

使用GitHub Actions在云端自动构建Windows版本。

### 步骤1：创建GitHub Actions工作流

创建文件 `.github/workflows/build-windows.yml`：

```yaml
name: Build Windows

on:
  push:
    tags:
      - 'v*'  # 当推送标签时触发，如 v1.0.0
  workflow_dispatch:  # 允许手动触发

jobs:
  build-windows:
    runs-on: windows-latest

    steps:
    - name: 检出代码
      uses: actions/checkout@v3

    - name: 设置Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'  # 使用您的Flutter版本
        channel: 'stable'

    - name: 启用Windows桌面支持
      run: flutter config --enable-windows-desktop

    - name: 获取依赖
      run: flutter pub get

    - name: 运行代码生成器
      run: flutter pub run build_runner build --delete-conflicting-outputs

    - name: 创建.env文件
      run: |
        echo "AI_API_URL=${{ secrets.AI_API_URL }}" > .env
        echo "AI_API_KEY=${{ secrets.AI_API_KEY }}" >> .env
      shell: bash

    - name: 构建Windows Release
      run: flutter build windows --release

    - name: 打包文件
      run: |
        Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath ChatDesktop-Windows.zip
      shell: pwsh

    - name: 上传构建产物
      uses: actions/upload-artifact@v3
      with:
        name: ChatDesktop-Windows
        path: ChatDesktop-Windows.zip

    - name: 创建Release（如果是标签推送）
      if: startsWith(github.ref, 'refs/tags/')
      uses: softprops/action-gh-release@v1
      with:
        files: ChatDesktop-Windows.zip
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 步骤2：配置GitHub Secrets

在GitHub仓库设置中添加Secrets：
1. 进入仓库 → Settings → Secrets and variables → Actions
2. 点击 "New repository secret"
3. 添加以下secrets：
   - `AI_API_URL`: 您的API地址
   - `AI_API_KEY`: 您的API密钥

### 步骤3：触发构建

**方式A：推送标签（推荐）**
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

**方式B：手动触发**
1. 进入GitHub仓库
2. 点击 Actions 标签
3. 选择 "Build Windows"
4. 点击 "Run workflow"

### 步骤4：下载构建产物

构建完成后（约10-15分钟）：
1. 进入 Actions 页面
2. 点击对应的workflow运行
3. 下载 "ChatDesktop-Windows" artifact
4. 解压即可使用

---

## 方案2：使用虚拟机

在macOS上运行Windows虚拟机。

### 选项A：Parallels Desktop（推荐）
- **优点**: 性能好，集成度高
- **缺点**: 收费（约$99/年）
- **下载**: https://www.parallels.com/

### 选项B：VMware Fusion
- **优点**: 功能强大
- **缺点**: 收费（约$199/永久）
- **下载**: https://www.vmware.com/products/fusion.html

### 选项C：VirtualBox（免费）
- **优点**: 完全免费
- **缺点**: 性能较差
- **下载**: https://www.virtualbox.org/

### 设置步骤
1. 安装虚拟机软件
2. 创建Windows 10/11虚拟机
3. 在虚拟机中安装Flutter和Visual Studio
4. 共享项目文件夹
5. 在虚拟机中构建

**最低配置建议**：
- CPU: 4核心
- 内存: 8GB（分配给虚拟机4GB）
- 磁盘: 50GB
- Windows 10/11 专业版

---

## 方案3：远程Windows机器

使用远程Windows机器或云服务器。

### 选项A：自己的Windows PC
```bash
# 在macOS上通过SSH连接Windows
ssh username@windows-pc-ip

# 或使用Remote Desktop
# 下载Microsoft Remote Desktop from Mac App Store
```

### 选项B：云服务器

**Azure Windows VM**
- 按小时计费
- 快速启动
- 链接: https://azure.microsoft.com/free/

**AWS EC2 Windows**
- 免费套餐可用
- 链接: https://aws.amazon.com/free/

**使用步骤**:
1. 创建Windows VM
2. 使用Remote Desktop连接
3. 安装Flutter开发环境
4. 克隆代码并构建

---

## 方案4：Docker + Wine（不推荐）

理论上可以使用Wine在Linux容器中运行Windows工具，但：
- ❌ 配置复杂
- ❌ 兼容性差
- ❌ 构建可能失败
- ⚠️ 不推荐用于生产环境

---

## 🎯 方案对比

| 方案 | 成本 | 难度 | 速度 | 推荐指数 |
|------|------|------|------|----------|
| **GitHub Actions** | 免费 | ⭐ | 10-15分钟 | ⭐⭐⭐⭐⭐ |
| Parallels虚拟机 | $99/年 | ⭐⭐ | 快 | ⭐⭐⭐⭐ |
| VirtualBox | 免费 | ⭐⭐⭐ | 慢 | ⭐⭐⭐ |
| 云服务器 | 按小时 | ⭐⭐⭐ | 快 | ⭐⭐⭐ |
| 远程PC | 免费 | ⭐⭐ | 快 | ⭐⭐⭐⭐ |

---

## 🚀 推荐方案

### 个人开发者
**GitHub Actions**（免费、自动化、无需维护）

### 团队/公司
**Parallels Desktop**或**云服务器**（开发体验好）

### 偶尔构建
**GitHub Actions**或**借用Windows PC**

---

## 📋 GitHub Actions详细说明

### 优点
✅ 完全免费（公开仓库无限制）
✅ 自动化构建
✅ 可以同时构建多个平台
✅ 构建产物自动保存
✅ 支持定时构建
✅ 无需本地Windows环境

### 缺点
❌ 每次构建需要10-15分钟
❌ 需要推送到GitHub
❌ 私有仓库有时长限制（2000分钟/月免费）

### 高级配置

**同时构建Windows和macOS**：

```yaml
name: Build Multi-Platform

on:
  push:
    tags:
      - 'v*'

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      # ... Windows构建步骤

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build macos --release
      # ... macOS构建步骤
```

---

## 🛠️ 本地测试（在macOS上）

虽然不能构建Windows版本，但可以在macOS上开发和测试：

```bash
# 构建和运行macOS版本
flutter run -d macos

# 确保代码在macOS上正常工作
# 大部分逻辑在两个平台上是通用的
```

### 跨平台兼容性检查

```dart
import 'dart:io';

if (Platform.isWindows) {
  // Windows特定代码
} else if (Platform.isMacOS) {
  // macOS特定代码
}
```

---

## 📝 完整工作流程（推荐）

### 日常开发（在macOS上）
```bash
# 1. 开发功能
flutter run -d macos

# 2. 测试功能
flutter test

# 3. 提交代码
git add .
git commit -m "新功能"
git push
```

### 发布版本（使用GitHub Actions）
```bash
# 1. 创建版本标签
git tag -a v1.0.0 -m "Release 1.0.0"

# 2. 推送标签（自动触发构建）
git push origin v1.0.0

# 3. 等待10-15分钟

# 4. 从GitHub Releases下载Windows版本
# https://github.com/your-repo/releases
```

---

## 🔧 故障排除

### GitHub Actions构建失败

**问题1**: 找不到.env文件
```yaml
# 解决：在workflow中创建.env
- name: 创建.env文件
  run: echo "AI_API_URL=..." > .env
```

**问题2**: 构建超时
```yaml
# 解决：增加超时时间
jobs:
  build:
    timeout-minutes: 60  # 默认是60分钟
```

**问题3**: 依赖下载失败
```yaml
# 解决：添加重试逻辑
- name: 获取依赖
  run: flutter pub get
  continue-on-error: true
- name: 重试获取依赖
  if: failure()
  run: flutter pub get
```

---

## 📚 相关资源

- **GitHub Actions文档**: https://docs.github.com/en/actions
- **Flutter构建文档**: https://docs.flutter.dev/deployment/windows
- **Parallels Desktop**: https://www.parallels.com/
- **VirtualBox**: https://www.virtualbox.org/

---

## 💡 最佳实践

1. **使用GitHub Actions自动化**
   - 每次发布自动构建
   - 多平台并行构建
   - 自动上传到Releases

2. **保持代码跨平台兼容**
   - 避免平台特定的硬编码路径
   - 使用`Platform.isWindows`检查平台
   - 在macOS上测试核心逻辑

3. **版本管理**
   - 使用语义化版本（v1.0.0）
   - 每个版本创建Git标签
   - 自动触发构建

4. **安全**
   - 使用GitHub Secrets保存API密钥
   - 不要在代码中硬编码敏感信息
   - .env文件添加到.gitignore

---

## 🎉 总结

**最简单的方案**：
1. 将代码推送到GitHub
2. 创建`.github/workflows/build-windows.yml`
3. 添加GitHub Secrets
4. 推送标签 `git push origin v1.0.0`
5. 等待构建完成
6. 从Releases下载Windows版本

**无需Windows机器，完全在macOS上开发，自动构建Windows版本！**
