import CoreGraphics
import Foundation

public enum ScreenRecordingPermission: Sendable {
    public static func isGranted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    public static func request() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}
