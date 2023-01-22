import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
      
      setupUtilsApi(binaryMessenger: flutterViewController.engine.binaryMessenger, api: UtilsApi())

    super.awakeFromNib()
  }
}

class UtilsApi: FlutterUtilsApi {
    func getBundlePath(resourceName: String) -> String? {
        return Bundle.main.url(forResource: resourceName, withExtension: nil)?.path
    }
}
