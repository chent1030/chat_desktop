# ChatDesktop.App（WPF）

此目录用于 WPF 主应用。由于 WPF 只能在 Windows 上创建/构建，请在 Windows 环境执行以下命令：

```powershell
dotnet new wpf -n ChatDesktop.App -o src/ChatDesktop.App

dotnet sln ChatDesktop.Wpf.sln add src/ChatDesktop.App/ChatDesktop.App.csproj
```

说明：
- 创建完成后，WPF 项目应引用 `ChatDesktop.Core` 与 `ChatDesktop.Infrastructure`。
- 后续所有 UI/ViewModel/资源文件都放在此目录。
