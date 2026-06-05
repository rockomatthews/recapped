import AppKit
import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation
import ImageIO
import RecappedCore

public enum SlideshowVideoRendererError: Error, Equatable {
    case noFrames
    case couldNotCreateWriter
    case couldNotStartWriting
    case couldNotCreatePixelBuffer
    case couldNotLoadImage(URL)
    case appendFailed
}

public final class SlideshowVideoRenderer: @unchecked Sendable {
    private let size: CGSize

    public init(size: CGSize = CGSize(width: 1280, height: 720)) {
        self.size = size
    }

    public func render(
        frames: [CaptureFrame],
        outputURL: URL,
        durationSeconds: TimeInterval = 60
    ) async throws {
        guard !frames.isEmpty else { throw SlideshowVideoRendererError.noFrames }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw SlideshowVideoRendererError.couldNotCreateWriter
        }

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        guard writer.canAdd(input) else {
            throw SlideshowVideoRendererError.couldNotCreateWriter
        }
        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error ?? SlideshowVideoRendererError.couldNotStartWriting
        }
        writer.startSession(atSourceTime: .zero)

        let seconds = max(1, Int(durationSeconds.rounded()))
        for second in 0..<seconds {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            let frameIndex = min(
                frames.count - 1,
                Int((Double(second) / Double(seconds)) * Double(frames.count))
            )
            let frame = frames[frameIndex]
            let pixelBuffer = try makePixelBuffer(
                from: frame.fileURL,
                caption: caption(for: frame)
            )
            let presentationTime = CMTime(value: CMTimeValue(second), timescale: 1)

            guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                throw writer.error ?? SlideshowVideoRendererError.appendFailed
            }
        }

        input.markAsFinished()

        let finishBox = AssetWriterFinishBox(writer: writer)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            finishBox.writer.finishWriting {
                if let error = finishBox.writer.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func makePixelBuffer(from imageURL: URL, caption: String) throws -> CVPixelBuffer {
        guard
            let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw SlideshowVideoRendererError.couldNotLoadImage(imageURL)
        }

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            nil,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else {
            throw SlideshowVideoRendererError.couldNotCreatePixelBuffer
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            throw SlideshowVideoRendererError.couldNotCreatePixelBuffer
        }

        let canvas = CGRect(origin: .zero, size: size)
        context.setFillColor(NSColor.black.cgColor)
        context.fill(canvas)
        context.interpolationQuality = .high
        context.draw(image, in: fittedRect(for: image, in: canvas))
        drawCaption(caption, in: context, canvas: canvas)

        return pixelBuffer
    }

    private func caption(for frame: CaptureFrame) -> String {
        let appName = frame.foregroundAppName ?? "Desktop"
        return "\(appName) - \(displayName(for: frame.reason))"
    }

    private func displayName(for reason: CaptureReason) -> String {
        switch reason {
        case .appChanged:
            "App changed"
        case .fallbackInterval:
            "Progress checkpoint"
        case .manual:
            "Session started"
        case .sessionStarted:
            "Session started"
        case .userActivity:
            "Active work"
        }
    }

    private func drawCaption(_ caption: String, in context: CGContext, canvas: CGRect) {
        let inset: CGFloat = 32
        let barHeight: CGFloat = 72
        let barRect = CGRect(
            x: inset,
            y: inset,
            width: canvas.width - inset * 2,
            height: barHeight
        )

        context.setFillColor(NSColor.black.withAlphaComponent(0.72).cgColor)
        context.fill(barRect)

        let textRect = barRect.insetBy(dx: 22, dy: 18)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph
        ]

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        NSString(string: caption).draw(in: textRect, withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func fittedRect(for image: CGImage, in canvas: CGRect) -> CGRect {
        let imageSize = CGSize(width: image.width, height: image.height)
        let scale = min(canvas.width / imageSize.width, canvas.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: canvas.midX - fittedSize.width / 2,
            y: canvas.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}

private final class AssetWriterFinishBox: @unchecked Sendable {
    let writer: AVAssetWriter

    init(writer: AVAssetWriter) {
        self.writer = writer
    }
}
