// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "GhostUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "GhostUI",
            targets: ["GhostUI"]
        ),
    ],
    dependencies: [
        // Required for Swift macros (600+ for BodyMacro support - Swift 6.0)
        .package(url: "https://github.com/apple/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        // Main library - depends on macro declarations
        .target(
            name: "GhostUI",
            dependencies: ["GhostUIMacros"],
            path: "Sources/GhostUI"
        ),

        // Macro declarations (public API)
        .target(
            name: "GhostUIMacros",
            dependencies: ["GhostUIMacrosPlugin"],
            path: "Sources/GhostUIMacros"
        ),

        // Macro implementation (compiler plugin)
        .macro(
            name: "GhostUIMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/GhostUIMacrosPlugin"
        ),

        // Tests
        .testTarget(
            name: "GhostUITests",
            dependencies: ["GhostUI"],
            path: "Tests/GhostUITests"
        ),
        .testTarget(
            name: "GhostUIMacrosTests",
            dependencies: [
                "GhostUIMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            path: "Tests/GhostUIMacrosTests"
        ),
    ]
)
