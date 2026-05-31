import Foundation

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

public enum CaptureBackend: String, Sendable {
    case screenCaptureKitPreferred
    case coreGraphicsFallback

    public static var defaultBackend: CaptureBackend {
        #if canImport(ScreenCaptureKit)
        return .screenCaptureKitPreferred
        #else
        return .coreGraphicsFallback
        #endif
    }
}
