// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftAware",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftAware",
            targets: ["SwiftAware"]
        ),
    ],
    dependencies: [
        // Required for Swift macros (600+ for BodyMacro support - Swift 6.0)
        .package(url: "https://github.com/apple/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        // Main library - depends on macro declarations
        .target(
            name: "SwiftAware",
            dependencies: ["SwiftAwareMacros"],
            path: "Sources/SwiftAware"
        ),

        // Macro declarations (public API)
        .target(
            name: "SwiftAwareMacros",
            dependencies: ["SwiftAwareMacrosPlugin"],
            path: "Sources/SwiftAwareMacros"
        ),

        // Macro implementation (compiler plugin)
        .macro(
            name: "SwiftAwareMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/SwiftAwareMacrosPlugin"
        ),

        // Tests
        .testTarget(
            name: "SwiftAwareTests",
            dependencies: ["SwiftAware"],
            path: "Tests/SwiftAwareTests"
        ),
        .testTarget(
            name: "SwiftAwareMacrosTests",
            dependencies: [
                "SwiftAwareMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            path: "Tests/SwiftAwareMacrosTests"
        ),
    ]
)
