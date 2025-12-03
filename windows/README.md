# Windows平台配置说明

## 系统要求
- Windows 10 1809 或更高版本
- Visual Studio 2022 或更高版本
- "使用C++的桌面开发"工作负载

## 权限说明
Windows桌面应用默认具有以下权限：
- ✓ 网络访问（HTTP/HTTPS/WebSocket）
- ✓ 文件系统访问（用户目录）
- ✓ 系统通知
- ✓ 窗口管理（Always on Top等）

## 防火墙
首次运行时，Windows防火墙可能会提示允许网络访问。
用户需要点击"允许访问"以启用网络功能。

## 已配置
- runner.exe.manifest: 已配置DPI感知和Windows 10/11兼容性
- CMakeLists.txt: Flutter标准桌面配置
- main.cpp: 应用入口点配置

## 注意事项
如需管理员权限，需要在main.cpp中配置requestedExecutionLevel。
当前应用不需要管理员权限。
