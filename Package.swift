// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Recapped",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Recapped", targets: ["RecappedApp"]),
        .executable(name: "RecappedRerender", targets: ["RecappedRerender"]),
        .library(name: "RecappedCore", targets: ["RecappedCore"]),
        .library(name: "RecappedCapture", targets: ["RecappedCapture"]),
        .library(name: "RecappedAI", targets: ["RecappedAI"]),
        .library(name: "RecappedUpload", targets: ["RecappedUpload"])
    ],
    targets: [
        .target(name: "RecappedCore"),
        .target(
            name: "RecappedCapture",
            dependencies: ["RecappedCore"]
        ),
        .target(
            name: "RecappedAI",
            dependencies: ["RecappedCore"]
        ),
        .target(
            name: "RecappedUpload",
            dependencies: ["RecappedCore"]
        ),
        .executableTarget(
            name: "RecappedApp",
            dependencies: [
                "RecappedCore",
                "RecappedCapture",
                "RecappedAI",
                "RecappedUpload"
            ]
        ),
        .executableTarget(
            name: "RecappedRerender",
            dependencies: [
                "RecappedCore",
                "RecappedCapture",
                "RecappedAI"
            ]
        ),
        .testTarget(
            name: "RecappedCoreTests",
            dependencies: ["RecappedCore"]
        ),
        .testTarget(
            name: "RecappedAITests",
            dependencies: ["RecappedAI", "RecappedCore"]
        )
    ]
)
