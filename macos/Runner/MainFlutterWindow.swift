import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 检查是否是子窗口（悬浮窗）
    // desktop_multi_window 会通过环境变量或其他方式传递窗口 ID
    // 如果是子窗口，应用无边框样式
    if isSubWindow() {
      configureAsFloatingWindow()
    }

    super.awakeFromNib()
  }

  /// 检查是否是子窗口
  private func isSubWindow() -> Bool {
    // desktop_multi_window 创建的子窗口会有特定的启动参数
    // 检查命令行参数中是否包含 'multi_window' 或窗口 ID
    let arguments = CommandLine.arguments

    // 如果参数中包含 'multi_window'，说明这是一个子窗口
    return arguments.contains("multi_window")
  }

  /// 配置为悬浮窗模式
  private func configureAsFloatingWindow() {
    print("🪟 [macOS Native] 配置悬浮窗模式")

    // 1. 移除标题栏和边框
    self.styleMask = [
      .borderless           // 无边框（不显示最小化/最大化/关闭）
    ]

    // 2. 设置窗口置顶
    self.level = .floating  // 始终在普通窗口之上

    // 3. 设置透明背景
    self.isOpaque = false
    self.backgroundColor = NSColor.clear

    // 4. 允许通过背景拖拽窗口
    self.isMovableByWindowBackground = true

    // 5. 隐藏标题栏
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true

    // 6. 移除阴影（可选，让窗口更"轻量"）
    self.hasShadow = false

    // 7. 设置窗口始终可见（不受"隐藏所有窗口"影响）
    self.collectionBehavior = [
      .canJoinAllSpaces,     // 在所有空间中显示
      .stationary,           // 不参与 Exposé
      .ignoresCycle          // 不在窗口循环中
    ]

    // 8. 固定悬浮窗尺寸（与 Flutter 端 120x120 一致）
    self.setContentSize(NSSize(width: 120, height: 120))

    print("✓ [macOS Native] 悬浮窗配置完成")
  }
}
