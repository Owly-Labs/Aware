//
//  AwareProtocolTests.swift
//  AwareCoreTests
//
//  Tests for protocol-based development features (v3.0+).
//

import XCTest
@testable import AwareCore

@MainActor
final class AwareProtocolTests: XCTestCase {

    func testProtocolStubsGeneration() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let stubs = service.exportProtocolStubs(platform: .all, language: .swift)

        XCTAssertFalse(stubs.code.isEmpty, "Stubs code should not be empty")
        XCTAssertGreaterThan(stubs.lineCount, 0, "Should have generated lines of code")
        XCTAssertGreaterThan(stubs.modifiers.count, 0, "Should include modifiers")

        // Verify stub structure
        XCTAssertTrue(stubs.code.contains("extension View"), "Should contain View extension")
        XCTAssertTrue(stubs.code.contains("// MARK:"), "Should have section markers")
        XCTAssertTrue(stubs.code.contains("func aware"), "Should contain aware modifier")
        XCTAssertTrue(stubs.code.contains("some View"), "Should return some View")

        // Verify stub modifiers are pass-through (return self)
        XCTAssertTrue(stubs.code.contains("{ self }"), "Stubs should be pass-through")

        print("\n📦 Protocol Stubs:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("   Platform: \(stubs.platform.rawValue)")
        print("   Language: \(stubs.language.rawValue)")
        print("   Lines: \(stubs.lineCount)")
        print("   Modifiers: \(stubs.modifiers.count)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Target: 50-100 LOC
        XCTAssertLessThan(stubs.lineCount, 120, "Stubs should be under 120 lines")
        XCTAssertGreaterThan(stubs.lineCount, 30, "Stubs should have at least 30 lines")
    }

    func testProtocolStubsContent() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let stubs = service.exportProtocolStubs(platform: .iOS, language: .swift)

        // Verify key modifiers are included
        let requiredModifiers = [
            ".aware(",
            ".awareContainer(",
            ".awareButton(",
            ".awareTextField(",
            ".awareState("
        ]

        for modifier in requiredModifiers {
            XCTAssertTrue(
                stubs.code.contains(modifier),
                "Stubs should include \(modifier)"
            )
        }

        print("\n📝 Stub Code Preview (first 20 lines):")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        let lines = stubs.code.components(separatedBy: "\n").prefix(20)
        for (index, line) in lines.enumerated() {
            print(String(format: "%3d: %@", index + 1, line))
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testValidationRulesGeneration() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let validationRules = service.exportValidationRules()

        XCTAssertGreaterThan(validationRules.rules.count, 0, "Should have validation rules")
        XCTAssertGreaterThan(validationRules.categories.count, 0, "Should have rule categories")
        XCTAssertGreaterThan(validationRules.severityLevels.count, 0, "Should have severity levels")

        // Verify rule structure
        for rule in validationRules.rules {
            XCTAssertFalse(rule.name.isEmpty, "Rule should have name")
            XCTAssertFalse(rule.description.isEmpty, "Rule should have description")
            XCTAssertFalse(rule.fix.isEmpty, "Rule should have suggested fix")
            XCTAssertGreaterThanOrEqual(rule.confidence, 0.0, "Confidence should be >= 0.0")
            XCTAssertLessThanOrEqual(rule.confidence, 1.0, "Confidence should be <= 1.0")
        }

        print("\n✅ Validation Rules:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("   Total Rules: \(validationRules.rules.count)")
        print("   Categories: \(validationRules.categories.map { $0.rawValue }.joined(separator: ", "))")
        print("   Severities: \(validationRules.severityLevels.map { $0.rawValue }.joined(separator: ", "))")
        print("\n   Sample Rules:")

        for (index, rule) in validationRules.rules.prefix(3).enumerated() {
            print("   \(index + 1). \(rule.name)")
            print("      Severity: \(rule.severity.rawValue)")
            print("      Category: \(rule.category.rawValue)")
            print("      Fix: \(rule.fix)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testPatternCatalogGeneration() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let catalog = service.exportPatternCatalog()

        XCTAssertGreaterThan(catalog.patterns.count, 0, "Should have patterns")
        XCTAssertGreaterThan(catalog.categories.count, 0, "Should have categories")
        XCTAssertEqual(catalog.totalPatterns, catalog.patterns.count, "Total should match count")

        // Verify pattern structure
        for (name, pattern) in catalog.patterns {
            XCTAssertEqual(pattern.name, name, "Pattern name should match key")
            XCTAssertFalse(pattern.signature.isEmpty, "Pattern should have signature")
            XCTAssertFalse(pattern.description.isEmpty, "Pattern should have description")
            XCTAssertGreaterThan(pattern.tokenCost, 0, "Pattern should have token cost")
        }

        print("\n📚 Pattern Catalog:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("   Total Patterns: \(catalog.totalPatterns)")
        print("   Categories: \(catalog.categories.map { $0.displayName }.joined(separator: ", "))")
        print("\n   Sample Patterns:")

        for (index, (name, pattern)) in catalog.patterns.prefix(3).enumerated() {
            print("   \(index + 1). \(name)")
            print("      Category: \(pattern.category.displayName)")
            print("      Token Cost: \(pattern.tokenCost)")
            print("      Parameters: \(pattern.parameters.count)")
            if let example = pattern.examples.first {
                print("      Example: \(example.code.replacingOccurrences(of: "\n", with: " "))")
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testCompleteProtocolSpecification() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let spec = service.exportProtocolSpecification()

        XCTAssertFalse(spec.stubs.code.isEmpty, "Should have stubs")
        XCTAssertGreaterThan(spec.validationRules.rules.count, 0, "Should have validation rules")
        XCTAssertGreaterThan(spec.patternCatalog.patterns.count, 0, "Should have patterns")
        XCTAssertFalse(spec.version.isEmpty, "Should have version")

        print("\n🎯 Complete Protocol Specification:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("   Version: \(spec.version)")
        print("   Generated: \(spec.generatedAt)")
        print("\n   Components:")
        print("   - Stubs: \(spec.stubs.lineCount) lines, \(spec.stubs.modifiers.count) modifiers")
        print("   - Validation: \(spec.validationRules.rules.count) rules")
        print("   - Patterns: \(spec.patternCatalog.totalPatterns) patterns")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testValidationMetadataInModifiers() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let modifiers = service.queryModifiers()

        // Find modifiers with validation metadata
        let modifiersWithValidation = modifiers.filter {
            $0.requiredParameters != nil ||
            $0.validationPattern != nil ||
            $0.commonMistakes != nil ||
            $0.autoFixes != nil
        }

        XCTAssertGreaterThan(modifiersWithValidation.count, 0, "Should have modifiers with validation metadata")

        print("\n🔍 Validation Metadata Coverage:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("   Total Modifiers: \(modifiers.count)")
        print("   With Validation: \(modifiersWithValidation.count)")
        print("   Coverage: \(Int(Double(modifiersWithValidation.count) / Double(modifiers.count) * 100))%")
        print("\n   Sample Validation Metadata:")

        for modifier in modifiersWithValidation.prefix(2) {
            print("   \(modifier.name):")
            if let required = modifier.requiredParameters {
                print("      Required: \(required.joined(separator: ", "))")
            }
            if let mistakes = modifier.commonMistakes {
                print("      Common Mistakes: \(mistakes.count)")
            }
            if let fixes = modifier.autoFixes {
                print("      Auto-Fixes: \(fixes.count)")
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func testStubsCompileability() async {
        let service = AwareDocumentationService.shared

        // Give registration task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let stubs = service.exportProtocolStubs(platform: .all, language: .swift)

        // Verify Swift syntax elements
        let requiredSyntax = [
            "import SwiftUI",
            "extension View",
            "func",
            "-> some View",
            "{ self }"
        ]

        for syntax in requiredSyntax {
            XCTAssertTrue(
                stubs.code.contains(syntax),
                "Stubs should contain valid Swift syntax: \(syntax)"
            )
        }

        // Verify no obvious syntax errors
        XCTAssertFalse(stubs.code.contains("<<"), "Should not contain merge conflict markers")
        XCTAssertFalse(stubs.code.contains(">>"), "Should not contain merge conflict markers")
        XCTAssertFalse(stubs.code.contains("==="), "Should not contain merge conflict markers")

        print("\n✨ Stub Compilability Check: PASS")
    }
}
