// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwareBridge",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AwareBridge",
            targets: ["AwareBridge"]
        ),
    ],
    dependencies: [
        .package(path: "../AwareCore"),
        // WebSocket support via SwiftNIO
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.25.0")
    ],
    targets: [
        .target(
            name: "AwareBridge",
            dependencies: [
                .product(name: "AwareCore", package: "AwareCore"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl")
            ],
            path: "Sources/AwareBridge",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AwareBridgeTests",
            dependencies: ["AwareBridge"],
            path: "Tests/AwareBridgeTests"
        ),
    ]
)
