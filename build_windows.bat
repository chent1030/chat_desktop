@echo off
chcp 65001 >nul
echo ================================
echo ChatDesktop Windows 构建脚本
echo ================================
echo.

REM 检查Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到Flutter，请先安装Flutter
    pause
    exit /b 1
)

echo [1/6] 清理旧构建...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ 清理失败
    pause
    exit /b 1
)

echo [2/6] 获取依赖...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ 获取依赖失败
    pause
    exit /b 1
)

echo [3/6] 运行代码生成器...
flutter pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo ⚠️  代码生成失败（可能没有需要生成的代码）
)

echo [4/6] 检查.env文件...
if not exist ".env" (
    echo ⚠️  警告: 未找到.env文件，将使用.env.example
    if exist ".env.example" (
        copy .env.example .env
    ) else (
        echo ❌ 错误: 未找到.env.example文件
        echo 请创建.env文件并配置API信息
        pause
        exit /b 1
    )
)

echo [5/6] 构建Windows Release版本...
flutter build windows --release --tree-shake-icons
if %errorlevel% neq 0 (
    echo ❌ 构建失败
    pause
    exit /b 1
)

echo [6/6] 复制文件到发布目录...
if exist "release\ChatDesktop" (
    rmdir /s /q "release\ChatDesktop"
)
mkdir release 2>nul
mkdir release\ChatDesktop

xcopy /E /I /Y build\windows\x64\runner\Release\* release\ChatDesktop\
if %errorlevel% neq 0 (
    echo ❌ 复制文件失败
    pause
    exit /b 1
)

REM 复制.env文件
copy .env release\ChatDesktop\.env

REM 创建README
echo ChatDesktop > release\ChatDesktop\README.txt
echo. >> release\ChatDesktop\README.txt
echo 使用说明： >> release\ChatDesktop\README.txt
echo 1. 双击 chat_desktop.exe 启动应用 >> release\ChatDesktop\README.txt
echo 2. 修改 .env 文件可以更改API配置 >> release\ChatDesktop\README.txt
echo. >> release\ChatDesktop\README.txt
echo 最后构建时间: %date% %time% >> release\ChatDesktop\README.txt

echo.
echo ================================
echo ✅ 构建完成！
echo ================================
echo.
echo 输出目录: release\ChatDesktop\
echo 主程序: release\ChatDesktop\chat_desktop.exe
echo.
echo 接下来可以：
echo 1. 直接运行测试: cd release\ChatDesktop ^&^& chat_desktop.exe
echo 2. 压缩为ZIP: 使用7-Zip或WinRAR压缩ChatDesktop文件夹
echo 3. 创建安装程序: 使用Inno Setup编译installer.iss
echo.

REM 询问是否打开输出目录
set /p OPEN="是否打开输出目录？(Y/N): "
if /i "%OPEN%"=="Y" (
    explorer release\ChatDesktop
)

pause
