import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Reserve the physical shake gesture for PreviewPort's preview controls
    // instead of letting UIKit present its "Shake to Undo" prompt.
    application.applicationSupportsShakeToEdit = false
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // ── Device Info Channel ──────────────────────────────────────────
    let channel = FlutterMethodChannel(
      name: "com.previewport/device_info",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler { (call, result) in
      if call.method == "getDeviceInfo" {
        let model = Self.mapIdentifierToName(UIDevice.modelIdentifier)
        let systemVersion = UIDevice.current.systemVersion

        result([
          "model": model,
          "identifier": UIDevice.modelIdentifier,
          "osVersion": systemVersion,
          "platform": "ios",
        ])
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Maps Apple's internal identifier (e.g. "iPhone15,2") to a marketing
  // name. Falls back to the raw identifier for unknown future devices.
  private static func mapIdentifierToName(_ id: String) -> String {
    let map: [String: String] = [
      // iPhone SE
      "iPhone8,4": "iPhone SE",
      "iPhone12,8": "iPhone SE (2nd gen)",
      "iPhone14,6": "iPhone SE (3rd gen)",
      // iPhone X series
      "iPhone10,3": "iPhone X",
      "iPhone10,6": "iPhone X",
      "iPhone11,2": "iPhone XS",
      "iPhone11,4": "iPhone XS Max",
      "iPhone11,6": "iPhone XS Max",
      "iPhone11,8": "iPhone XR",
      // iPhone 11
      "iPhone12,1": "iPhone 11",
      "iPhone12,3": "iPhone 11 Pro",
      "iPhone12,5": "iPhone 11 Pro Max",
      // iPhone 12
      "iPhone13,1": "iPhone 12 mini",
      "iPhone13,2": "iPhone 12",
      "iPhone13,3": "iPhone 12 Pro",
      "iPhone13,4": "iPhone 12 Pro Max",
      // iPhone 13
      "iPhone14,4": "iPhone 13 mini",
      "iPhone14,5": "iPhone 13",
      "iPhone14,2": "iPhone 13 Pro",
      "iPhone14,3": "iPhone 13 Pro Max",
      // iPhone 14
      "iPhone14,7": "iPhone 14",
      "iPhone14,8": "iPhone 14 Plus",
      "iPhone15,2": "iPhone 14 Pro",
      "iPhone15,3": "iPhone 14 Pro Max",
      // iPhone 15
      "iPhone15,4": "iPhone 15",
      "iPhone15,5": "iPhone 15 Plus",
      "iPhone16,1": "iPhone 15 Pro",
      "iPhone16,2": "iPhone 15 Pro Max",
      // iPhone 16
      "iPhone17,1": "iPhone 16",
      "iPhone17,2": "iPhone 16 Plus",
      "iPhone17,3": "iPhone 16 Pro",
      "iPhone17,4": "iPhone 16 Pro Max",
      // iPad Mini
      "iPad11,1": "iPad Mini (5th gen)",
      "iPad11,2": "iPad Mini (5th gen)",
      "iPad14,1": "iPad Mini (6th gen)",
      "iPad14,2": "iPad Mini (6th gen)",
      // iPad Air
      "iPad13,16": "iPad Air (5th gen)",
      "iPad13,17": "iPad Air (5th gen)",
      "iPad14,8": "iPad Air 11″ (M2)",
      "iPad14,9": "iPad Air 11″ (M2)",
      "iPad14,10": "iPad Air 13″ (M2)",
      "iPad14,11": "iPad Air 13″ (M2)",
      // iPad Pro
      "iPad14,3": "iPad Pro 11″ (M2)",
      "iPad14,4": "iPad Pro 11″ (M2)",
      "iPad14,5": "iPad Pro 12.9″ (M2)",
      "iPad14,6": "iPad Pro 12.9″ (M2)",
      "iPad16,3": "iPad Pro 11″ (M4)",
      "iPad16,4": "iPad Pro 11″ (M4)",
      "iPad16,5": "iPad Pro 13″ (M4)",
      "iPad16,6": "iPad Pro 13″ (M4)",
    ]
    return map[id] ?? id
  }
}

// ─── UIDevice Extension ──────────────────────────────────────────────

extension UIDevice {
  /// Returns the machine identifier (e.g. "iPhone15,2").
  /// In the simulator, reads the SIMULATOR_MODEL_IDENTIFIER env var.
  static var modelIdentifier: String {
    #if targetEnvironment(simulator)
    return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
    #else
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        String(validatingUTF8: $0)
      }
    } ?? "Unknown"
    #endif
  }
}
