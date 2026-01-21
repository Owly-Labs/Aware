// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Aware",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Umbrella library - re-exports platform-specific modules
        .library(
            name: "Aware",
            targets: ["Aware"]
        ),
        // Individual module libraries
        .library(
            name: "AwareCore",
            targets: ["AwareCore"]
        ),
        .library(
            name: "AwareiOS",
            targets: ["AwareiOS"]
        ),
        .library(
            name: "AwareMacOS",
            targets: ["AwareMacOS"]
        ),
        .library(
            name: "AwareBackendClient",
            targets: ["AwareBackendClient"]
        ),
    ],
    dependencies: [
        // Test dependencies
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
        .package(url: "https://github.com/birdrides/mockingbird", from: "0.20.0")
    ],
    targets: [
        // MARK: - Core Package

        .target(
            name: "AwareCore",
            dependencies: [],
            path: "AwareCore/Sources/AwareCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - iOS Package

        .target(
            name: "AwareiOS",
            dependencies: ["AwareCore"],
            path: "AwareiOS/Sources/AwareiOS",
            swiftSettings: [
                .define("AWARE_IOS"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - macOS Package

        .target(
            name: "AwareMacOS",
            dependencies: ["AwareCore"],
            path: "AwareMacOS/Sources/AwareMacOS",
            swiftSettings: [
                .define("AWARE_MACOS"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Backend Client Package

        .target(
            name: "AwareBackendClient",
            dependencies: ["AwareCore"],
            path: "AwareBackendClient/swift/Sources/AwareBackendClient",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Umbrella Target (Backward Compatibility)

        .target(
            name: "Aware",
            dependencies: [
                "AwareCore",
                .target(name: "AwareiOS", condition: .when(platforms: [.iOS])),
                .target(name: "AwareMacOS", condition: .when(platforms: [.macOS])),
            ],
            path: "Aware/Sources/Aware",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Tests

        .testTarget(
            name: "AwareTests",
            dependencies: [
                "Aware",
                "AwareCore",
                "ViewInspector",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "Mockingbird", package: "mockingbird")
            ],
            path: "Tests/AwareTests"
        ),
        .testTarget(
            name: "AwareCoreTests",
            dependencies: [
                "AwareCore"
            ],
            path: "AwareCore/Tests/AwareCoreTests"
        ),
    ]
)
