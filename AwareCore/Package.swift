// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AwareCore",
            targets: ["AwareCore"]
        ),
        .executable(
            name: "export-protocol",
            targets: ["ExportProtocol"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AwareCore",
            dependencies: [],
            path: "Sources/AwareCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareCoreTests",
            dependencies: ["AwareCore"],
            path: "Tests/AwareCoreTests"
        ),
        .executableTarget(
            name: "ExportProtocol",
            dependencies: ["AwareCore"],
            path: "Sources/ExportProtocol"
        ),
    ]
)
