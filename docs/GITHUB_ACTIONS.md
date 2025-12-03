# GitHub Actions使用指南

## 📦 自动化构建Windows版本

本项目配置了GitHub Actions，可以自动在云端构建Windows版本，无需本地Windows环境。

---

## 🚀 快速开始

### 方式1：推送标签触发（推荐）

```bash
# 1. 提交并推送代码
git add .
git commit -m "准备发布 v1.0.0"
git push

# 2. 创建并推送标签
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 3. 等待构建（10-15分钟）
# 访问 GitHub Actions 查看进度
```

### 方式2：手动触发

1. 访问GitHub仓库
2. 点击 **Actions** 标签
3. 选择 **Build Windows Application**
4. 点击 **Run workflow** 按钮
5. 选择分支并点击 **Run workflow**

---

## ⚙️ 配置GitHub Secrets

**必须在使用前配置以下Secrets，否则构建会失败！**

### 步骤：

1. 访问GitHub仓库
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 添加以下3个secrets：

| Secret名称 | 值 | 说明 |
|-----------|-----|------|
| `AI_API_URL` | `https://your-api.com/v1/chat-messages` | Dify API地址 |
| `AI_API_KEY` | `your-api-key` | API密钥 |
| `AI_SSE_URL` | `https://your-api.com/v1/chat-messages` | SSE地址（可选） |

### 示例截图：

```
Name: AI_API_URL
Secret: https://ipaas.catl.com/gateway/outside/xxx/v1/chat-messages

Name: AI_API_KEY
Secret: app-xxxxxxxxxxxxxxxxxx

Name: AI_SSE_URL
Secret: https://ipaas.catl.com/gateway/outside/xxx/v1/chat-messages
```

---

## 📥 下载构建产物

### 方式1：从Artifacts下载（临时文件，保留90天）

1. 访问 **Actions** 页面
2. 点击对应的workflow运行记录
3. 在 **Artifacts** 区域找到 `ChatDesktop-Windows-v1.0.0`
4. 点击下载ZIP文件

### 方式2：从Releases下载（推荐，永久保存）

如果是通过标签触发的构建：

1. 访问仓库的 **Releases** 页面
2. 找到对应的版本（如 v1.0.0）
3. 下载 `ChatDesktop-v1.0.0-Windows.zip`

---

## 🔍 查看构建状态

### 实时监控

1. 访问 **Actions** 页面
2. 点击最新的workflow运行
3. 查看每个步骤的执行情况

### 常见状态

- 🟡 **黄色**：正在运行
- ✅ **绿色**：成功完成
- ❌ **红色**：构建失败（查看日志）

---

## 🐛 故障排除

### ❌ 构建失败：找不到.env配置

**原因**：未配置GitHub Secrets

**解决**：
```bash
# 检查Secrets是否配置
Settings → Secrets and variables → Actions
# 确保AI_API_URL和AI_API_KEY已添加
```

### ❌ 构建失败：pub get失败

**原因**：依赖下载超时或网络问题

**解决**：
- 点击 **Re-run failed jobs** 重试
- 或等待GitHub恢复网络

### ❌ 构建失败：build_runner错误

**原因**：代码生成失败

**解决**：
- 检查模型定义是否正确
- 在本地运行 `flutter pub run build_runner build` 测试

### ⚠️ 构建成功但下载的文件无法运行

**原因**：.env配置错误或缺少DLL

**解决**：
- 检查.env文件内容
- 安装 [VC++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

---

## 📊 构建时间

| 步骤 | 预计时间 |
|------|---------|
| 检出代码 | 10秒 |
| 设置Flutter | 2分钟 |
| 获取依赖 | 2-3分钟 |
| 代码生成 | 1分钟 |
| 构建Release | 5-8分钟 |
| 打包上传 | 1分钟 |
| **总计** | **10-15分钟** |

---

## 🎯 版本管理

### 版本号规则

使用语义化版本：`v{major}.{minor}.{patch}`

- `v1.0.0` - 首次正式发布
- `v1.1.0` - 新增功能
- `v1.1.1` - 修复bug
- `v2.0.0` - 重大更新

### 推荐工作流

```bash
# 开发新功能
git checkout -b feature/new-feature
# ... 开发提交 ...
git push origin feature/new-feature

# 合并到main
git checkout main
git merge feature/new-feature

# 创建版本标签
git tag -a v1.1.0 -m "添加xxx功能"
git push origin v1.1.0
# 自动触发构建并创建Release
```

---

## 📝 Release Notes模板

创建标签时使用详细的描述：

```bash
git tag -a v1.0.0 -m "Release version 1.0.0

新增功能:
- AI对话功能
- 语音输入支持
- 任务管理

修复问题:
- 修复窗口闪烁问题
- 优化内存占用

已知问题:
- 暂无
"
```

---

## 🔄 自动化流程图

```
开发代码（macOS）
    ↓
推送到GitHub
    ↓
创建标签（v1.0.0）
    ↓
GitHub Actions自动触发
    ↓
在Windows环境构建
    ↓
创建Release + 上传ZIP
    ↓
用户下载Windows版本
```

---

## 💡 高级用法

### 同时构建Windows和macOS

创建 `.github/workflows/build-all.yml`：

```yaml
name: Build All Platforms

on:
  push:
    tags:
      - 'v*'

jobs:
  build-windows:
    # ... Windows构建配置

  build-macos:
    runs-on: macos-latest
    steps:
      # ... macOS构建配置
```

### 定时构建（每周构建一次）

```yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # 每周日午夜构建
  push:
    tags:
      - 'v*'
```

### 构建通知（发送到邮箱）

添加通知步骤：

```yaml
- name: 发送构建通知
  if: always()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: 构建${{ job.status }} - ${{ github.ref_name }}
    body: 查看详情：${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    to: your-email@example.com
```

---

## 📚 相关文档

- [BUILD_ON_MACOS.md](./BUILD_ON_MACOS.md) - macOS构建Windows应用完整指南
- [WINDOWS_BUILD.md](./WINDOWS_BUILD.md) - Windows本地构建文档
- [GitHub Actions文档](https://docs.github.com/en/actions)

---

## ✅ 检查清单

构建前：
- [ ] 代码已提交并推送
- [ ] GitHub Secrets已配置（AI_API_URL, AI_API_KEY）
- [ ] pubspec.yaml版本号已更新
- [ ] CHANGELOG.md已更新

构建后：
- [ ] 构建成功（绿色✅）
- [ ] 下载并测试ZIP文件
- [ ] Release页面描述完整
- [ ] 通知用户更新

---

**🎉 现在您可以在macOS上开发，自动构建Windows版本了！**
