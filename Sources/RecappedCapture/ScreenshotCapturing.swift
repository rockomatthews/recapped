import Foundation

public protocol ScreenshotCapturing: Sendable {
    func captureScreenshot(to fileURL: URL) throws -> URL
}
