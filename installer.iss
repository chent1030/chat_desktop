# 安装脚本配置文件
# 使用Inno Setup 6创建Windows安装程序

#define MyAppName "ChatDesktop"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Company"
#define MyAppURL "https://your-website.com"
#define MyAppExeName "chat_desktop.exe"

[Setup]
; 应用程序基本信息
AppId={{8F3D9B1C-6A2E-4D5F-9C8B-1E7A4F2D6C9B}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; 安装路径
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; 输出配置
OutputDir=installer_output
OutputBaseFilename=ChatDesktop-Setup-{#MyAppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; 压缩
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; 外观
WizardStyle=modern
WizardImageFile=compiler:WizModernImage-IS.bmp
WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp

; 权限（不需要管理员权限）
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; 其他
DisableWelcomePage=no
AllowNoIcons=yes
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} 安装程序

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"; Flags: unchecked
Name: "quicklaunchicon"; Description: "创建快速启动栏快捷方式"; GroupDescription: "附加图标:"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; 主程序
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; 所有DLL和资源文件
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; 配置文件
Source: ".env"; DestDir: "{app}"; Flags: ignoreversion confirmoverwrite

; 文档（可选）
; Source: "README.md"; DestDir: "{app}"; DestName: "README.txt"; Flags: ignoreversion isreadme
; Source: "LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion

[Icons]
; 开始菜单
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"

; 桌面快捷方式
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

; 快速启动栏
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; 安装完成后运行
Filename: "{app}\{#MyAppExeName}"; Description: "立即运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 卸载时删除用户数据（可选）
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}"

[Code]
// 检查是否已经运行
function InitializeSetup(): Boolean;
var
  ErrorCode: Integer;
begin
  // 这里可以添加额外的检查逻辑
  Result := True;
end;

// 卸载前确认
function InitializeUninstall(): Boolean;
begin
  Result := True;
  if MsgBox('确定要卸载 ChatDesktop 吗？', mbConfirmation, MB_YESNO) = IDNO then
    Result := False;
end;
