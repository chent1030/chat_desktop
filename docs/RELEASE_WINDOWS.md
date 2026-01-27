# Windows 打包发布（便携式）

以下步骤用于生成免安装的便携式发布包，并给出配置与分发建议。

## 1. 前置条件

1. 已安装 .NET SDK（与项目 `TargetFramework` 匹配）
2. 已还原依赖

```bash
flutter pub get
```

## 2. 打包命令

在仓库根目录执行：

```bash
dotnet publish src/ChatDesktop.App/ChatDesktop.App.csproj -c Release -r win-x64 \
  -p:PublishSingleFile=true -p:SelfContained=true -p:IncludeNativeLibrariesForSelfExtract=true
```

## 3. 发布产物路径

产物默认输出到：

```
src/ChatDesktop.App/bin/Release/net8.0-windows/win-x64/publish/
```

将该目录整体拷贝/压缩后即可分发（无需安装）。

## 4. 配置文件位置

便携式运行目录内包含 `settings.json`，运行时会从该文件读取配置。

- 建议在**运行前**修改该文件
- 运行中修改可能被应用保存逻辑覆盖

## 5. 分发与更新建议

1. **公司强管控环境**：建议通过 IT 的软件分发平台（如 SCCM/Intune/软件中心）推送完整包
2. **MQTT**：可用于“更新通知”，但不建议直接承担下载与替换
3. **更新策略**：推荐内网 HTTP/共享目录提供新版本包，客户端收到通知后引导用户下载并重启
