import Foundation
import Flutter

class ICloudHandler {
    private let methodChannel: FlutterMethodChannel

    init(binaryMessenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "com.draexl.project-manager/iCloud",
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
            let containerUrl: URL? = FileManager.default.url(
                forUbiquityContainerIdentifier: nil
            )?.appendingPathComponent("Documents")
            
            // Check for container existence and create if needed
            if let url = containerUrl {
                var isDirectory: ObjCBool = false
                if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    do {
                        try FileManager.default.createDirectory(
                            at: url,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )
                    } catch {
                        print("Error creating iCloud directory: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            result(FlutterError(
                                code: "DIRECTORY_CREATION_FAILED",
                                message: "Failed to create iCloud directory",
                                details: error.localizedDescription
                            ))
                        }
                        return
                    }
                }
            }

            // Return the path on the main thread
            DispatchQueue.main.async {
                if let path = containerUrl?.path {
                    result(path)
                } else {
                    result(FlutterError(
                        code: "ICLOUD_UNAVAILABLE",
                        message: "iCloud container is not available",
                        details: "Make sure iCloud is enabled and the app has proper entitlements"
                    ))
                }
            }
        }
    }
}
