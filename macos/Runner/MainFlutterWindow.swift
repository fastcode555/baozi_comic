import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 设置无标题栏窗口，但保留系统窗口控制按钮
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
    
    // 设置窗口可以拖拽
    self.isMovableByWindowBackground = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
