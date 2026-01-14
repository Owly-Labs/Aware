import Foundation
import AwareCore

/// Command-line tool to export Aware Protocol Specification to JSON
@main
struct ExportProtocolTool {
    static func main() async throws {
        print("Exporting Aware Protocol Specification...")

        // Get the documentation service
        let docService = AwareDocumentationService.shared

        // Wait a moment for async initialization to complete
        // (The service auto-registers APIs in a Task on init)
        try await Task.sleep(for: .milliseconds(500))

        // Verify registry is populated
        let stats = docService.getStatistics()
        print("📚 Registry loaded:")
        print("   - Modifiers: \(stats.modifierCount)")
        print("   - Types: \(stats.typeCount)")
        print("   - Methods: \(stats.methodCount)")

        if stats.totalAPIs == 0 {
            print("⚠️  Warning: Registry is empty. APIs may not have been registered yet.")
        }

        // Export protocol specification
        let spec = docService.exportProtocolSpecification()

        // Create output JSON
        let output: [String: Any] = [
            "version": spec.version,
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "platform": "iOS",
            "language": "Swift",
            "stubs": [
                "code": spec.stubs.code,
                "lineCount": spec.stubs.lineCount,
                "modifiersIncluded": spec.stubs.modifiers,
                "instructions": spec.stubs.instructions
            ],
            "validationRules": spec.validationRules.rules.map { rule in
                [
                    "name": rule.name,
                    "category": rule.category.rawValue,
                    "severity": rule.severity.rawValue,
                    "description": rule.description,
                    "pattern": rule.pattern ?? "",
                    "fix": rule.fix,
                    "confidence": rule.confidence
                ]
            },
            "patternCatalog": spec.patternCatalog.patterns.map { (key, pattern) in
                [
                    "name": key,
                    "signature": pattern.signature,
                    "category": pattern.category.rawValue,
                    "description": pattern.description,
                    "parameters": pattern.parameters.map { param in
                        [
                            "name": param.name,
                            "type": param.type,
                            "description": param.description,
                            "required": param.required,
                            "defaultValue": param.defaultValue ?? ""
                        ]
                    },
                    "examples": pattern.examples.map { example in
                        var exampleDict: [String: Any] = [
                            "code": example.code,
                            "description": example.description
                        ]
                        if let platform = example.platform {
                            exampleDict["platform"] = platform.rawValue
                        }
                        return exampleDict
                    },
                    "relatedModifiers": pattern.relatedModifiers,
                    "commonMistakes": pattern.commonMistakes,
                    "tokenCost": pattern.tokenCost,
                    "platform": pattern.platform.rawValue
                ]
            }
        ]

        // Convert to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys])

        // Determine output path
        let outputPath: String
        if CommandLine.arguments.count > 1 {
            outputPath = CommandLine.arguments[1]
        } else {
            // Default to AetherMCP data directory
            let currentDir = FileManager.default.currentDirectoryPath
            outputPath = "\(currentDir)/../../../AetherMCP/src/features/aware-protocol/data/aware-stubs.json"
        }

        // Write to file
        try jsonData.write(to: URL(fileURLWithPath: outputPath))

        print("✅ Protocol specification exported to: \(outputPath)")
        print("📊 Stats:")
        print("   - Stubs: \(spec.stubs.lineCount) LOC")
        print("   - Modifiers: \(spec.stubs.modifiers.count)")
        print("   - Validation Rules: \(spec.validationRules.rules.count)")
        print("   - Pattern Catalog: \(spec.patternCatalog.patterns.count) patterns")
        print("   - File Size: \(jsonData.count / 1024) KB")
    }
}
