import Foundation
import Flutter

class ICloudHandler {
    private let methodChannel: FlutterMethodChannel

    init(binaryMessenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "com.draexl.project_manager/icloud",
            binaryMessenger: binaryMessenger
        )

        setupMethodChannel()
    }

    private func setupMethodChannel() {
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "getICloudDocumentsPath":
                self.getICloudDocumentsPath(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func getICloudDocumentsPath(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .background).async {
            // Get the iCloud container URL for our app
            if let iCloudContainerURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.draexl.project-manager") {
                // Create a documents directory if it doesn't exist
                let documentsURL = iCloudContainerURL.appendingPathComponent("Documents")

                do {
                    if !FileManager.default.fileExists(atPath: documentsURL.path) {
                        try FileManager.default.createDirectory(
                            at: documentsURL,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )
                    }

                    // Return the path on the main thread
                    DispatchQueue.main.async {
                        result(documentsURL.path)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "DIRECTORY_CREATION_FAILED",
                            message: "Failed to create iCloud Documents directory: \(error.localizedDescription)",
                            details: nil
                        ))
                    }
                }
            } else {
                // iCloud is not available
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "ICLOUD_UNAVAILABLE",
                        message: "iCloud is not available. Make sure the user is signed in to iCloud and the app has the necessary entitlements.",
                        details: nil
                    ))
                }
            }
        }
    }
}
