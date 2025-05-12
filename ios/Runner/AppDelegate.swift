import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var iCloudHandler: ICloudHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // Setup iCloud handler
    iCloudHandler = ICloudHandler(binaryMessenger: controller.binaryMessenger)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
