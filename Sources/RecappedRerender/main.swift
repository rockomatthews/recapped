import Foundation
import RecappedAI
import RecappedCore

@main
struct RecappedRerender {
    static func main() async throws {
        let sessionURL = try resolveSessionURL()
        let metadataURL = sessionURL.appending(path: "session.json")
        let outputURL = sessionURL.appending(path: "recap.mp4")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: metadataURL)
        let session = try decoder.decode(CapturedSession.self, from: data)

        print("Rerendering \(session.frames.count) frame(s) from:")
        print(sessionURL.path)

        let result = try await LocalAIRecapProvider().generateRecap(
            for: session,
            outputURL: outputURL
        )

        print("Wrote \(Int(result.durationSeconds))-second recap:")
        print(result.videoURL.path)
    }

    private static func resolveSessionURL() throws -> URL {
        let arguments = CommandLine.arguments.dropFirst()
        if let firstArgument = arguments.first {
            return URL(filePath: firstArgument, directoryHint: .isDirectory)
        }

        let sessionsRoot = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appending(path: "Recapped/Sessions", directoryHint: .isDirectory)

        let sessionDirectories = try FileManager.default.contentsOfDirectory(
            at: sessionsRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { url in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                && isDirectory.boolValue
                && FileManager.default.fileExists(atPath: url.appending(path: "session.json").path)
        }

        guard let latest = try sessionDirectories.max(by: { lhs, rhs in
            let lhsDate = try lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            let rhsDate = try rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            return lhsDate < rhsDate
        }) else {
            throw RerenderError.noSessionFound(sessionsRoot)
        }

        return latest
    }
}

enum RerenderError: LocalizedError {
    case noSessionFound(URL)

    var errorDescription: String? {
        switch self {
        case .noSessionFound(let url):
            "No Recapped session with session.json was found under \(url.path)."
        }
    }
}
