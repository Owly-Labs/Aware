//
//  AwareDocumentationTests.swift
//  AwareCoreTests
//
//  Tests for self-documentation system.
//

import XCTest
@testable import AwareCore

@MainActor
final class AwareDocumentationTests: XCTestCase {

    func testDocumentationServiceInitialization() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let stats = service.getStatistics()

        XCTAssertGreaterThan(stats.modifierCount, 0, "Should have registered modifiers")
        XCTAssertGreaterThan(stats.typeCount, 0, "Should have registered types")
        XCTAssertGreaterThan(stats.methodCount, 0, "Should have registered methods")
        XCTAssertGreaterThan(stats.totalAPIs, 0, "Should have total APIs")

        print("📊 Registered \(stats.totalAPIs) APIs:")
        print("   - Modifiers: \(stats.modifierCount)")
        print("   - Types: \(stats.typeCount)")
        print("   - Methods: \(stats.methodCount)")
    }

    func testCompactFormatGeneration() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let compact = service.exportCompact(maxTokens: 1500)

        XCTAssertFalse(compact.isEmpty, "Compact format should not be empty")
        XCTAssertTrue(compact.contains("AWARE API"), "Should contain header")
        XCTAssertTrue(compact.contains("MODIFIERS"), "Should contain modifiers section")

        // Estimate token count (rough: 1 token ≈ 4 characters)
        let estimatedTokens = compact.count / 4

        print("\n📄 Compact Format:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(compact)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("\n📊 Token Analysis:")
        print("   Characters: \(compact.count)")
        print("   Estimated Tokens: ~\(estimatedTokens)")
        print("   Target: <1500 tokens")
        print("   Status: \(estimatedTokens < 1500 ? "✅ PASS" : "❌ FAIL")")

        XCTAssertLessThan(estimatedTokens, 1500, "Token count should be under 1500")
    }

    func testQueryModifiers() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let allModifiers = service.queryModifiers()
        let registrationModifiers = service.queryModifiers(category: .registration)
        let actionModifiers = service.queryModifiers(category: .action)

        XCTAssertGreaterThan(allModifiers.count, 0, "Should have modifiers")
        XCTAssertGreaterThan(registrationModifiers.count, 0, "Should have registration modifiers")
        XCTAssertGreaterThan(actionModifiers.count, 0, "Should have action modifiers")

        print("\n🔍 Modifier Query Results:")
        print("   All: \(allModifiers.count)")
        print("   Registration: \(registrationModifiers.count)")
        print("   Action: \(actionModifiers.count)")

        for modifier in allModifiers.prefix(3) {
            print("\n   \(modifier.category.emoji) \(modifier.name)")
            print("      \(modifier.description)")
            print("      Token cost: \(modifier.tokenCost ?? 0)")
        }
    }

    func testSearchAPI() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let tapResults = service.search("tap")
        let stateResults = service.search("state")

        XCTAssertGreaterThan(tapResults.totalResults, 0, "Should find tap-related APIs")
        XCTAssertGreaterThan(stateResults.totalResults, 0, "Should find state-related APIs")

        print("\n🔍 Search Results:")
        print("   'tap': \(tapResults.totalResults) results")
        print("      Modifiers: \(tapResults.modifiers.count)")
        print("      Types: \(tapResults.types.count)")
        print("      Methods: \(tapResults.methods.count)")

        print("\n   'state': \(stateResults.totalResults) results")
        print("      Modifiers: \(stateResults.modifiers.count)")
        print("      Types: \(stateResults.types.count)")
        print("      Methods: \(stateResults.methods.count)")
    }

    func testMarkdownGeneration() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let markdown = service.exportMarkdown(format: .summary)

        XCTAssertFalse(markdown.isEmpty, "Markdown should not be empty")
        XCTAssertTrue(markdown.contains("# Aware Framework API Reference"), "Should have title")

        print("\n📝 Markdown Summary:")
        print(markdown.prefix(500))
        print("...")
    }

    func testMermaidGeneration() async {
        let service = AwareDocumentationService.shared

        let diagram = service.exportMermaid(diagramType: .architecture)

        XCTAssertFalse(diagram.isEmpty, "Mermaid diagram should not be empty")
        XCTAssertTrue(diagram.contains("graph"), "Should contain graph directive")

        print("\n🎨 Mermaid Diagram:")
        print(diagram)
    }
}
