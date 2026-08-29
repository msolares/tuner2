import Flutter
import UIKit
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "afinador/audio_session",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "setMeasurementMode":
          do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setMode(.measurement)
            result(nil)
          } catch {
            result(
              FlutterError(
                code: "audio_session_mode_failed",
                message: "Failed to set AVAudioSession measurement mode.",
                details: error.localizedDescription
              )
            )
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
