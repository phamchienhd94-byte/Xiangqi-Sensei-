import Flutter
import UIKit

public class PikafishEnginePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pikafish_engine", binaryMessenger: registrar.messenger())
    let instance = PikafishEnginePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Chúng ta chủ yếu dùng FFI để gọi Engine cho nhanh
    // Hàm này giữ lại để đảm bảo cấu trúc Plugin chuẩn của Flutter
    result(FlutterMethodNotImplemented)
  }
}