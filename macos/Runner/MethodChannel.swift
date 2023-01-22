import Cocoa
import FlutterMacOS

protocol FlutterUtilsApi {
    func getBundlePath(resourceName: String) -> String?
}

func setupUtilsApi(binaryMessenger: FlutterBinaryMessenger, api: FlutterUtilsApi) -> Void {
    FlutterMethodChannel(name: "net.chikach.dqmInstallerFlt.UtilsApi.getBundlePath", binaryMessenger: binaryMessenger).setMethodCallHandler({ call, result in
        if call.arguments == nil {
            return result(nil)
        }

        result(api.getBundlePath(resourceName: call.arguments as! String))
    })
}
