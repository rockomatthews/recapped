import AppKit
import CoreGraphics
import Foundation

public enum ScreenshotCaptureError: Error, Equatable {
    case couldNotCreateDisplayImage
    case couldNotEncodePNG
}

public final class CoreGraphicsScreenshotCapturer: ScreenshotCapturing, @unchecked Sendable {
    public init() {}

    public func captureScreenshot(to fileURL: URL) throws -> URL {
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            throw ScreenshotCaptureError.couldNotCreateDisplayImage
        }

        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotCaptureError.couldNotEncodePNG
        }

        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }
}
