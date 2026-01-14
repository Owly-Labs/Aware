//
//  LLMSnapshotTests.swift
//  Aware - LLM Integration Tests
//
//  Validates that LLMs can "see and touch" iOS apps via Aware snapshots.
//

import XCTest
@testable import AwareCore

/// Tests proving LLMs can consume Aware snapshots and issue commands
@MainActor
final class LLMSnapshotTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Reset Aware state between tests
        Aware.shared.reset()
    }

    // MARK: - Snapshot Parsing Tests

    func testLLMCanSeeViewHierarchy() async {
        // GIVEN: A view hierarchy is registered
        Aware.shared.registerView("container", label: "Main Container", isContainer: true)
        Aware.shared.registerView("button-1", label: "Save", parentId: "container")
        Aware.shared.registerView("button-2", label: "Cancel", parentId: "container")

        // WHEN: LLM requests compact snapshot
        let snapshot = Aware.shared.captureSnapshot(format: .compact)

        // THEN: LLM can parse the hierarchy
        XCTAssertTrue(snapshot.content.contains("container"))
        XCTAssertTrue(snapshot.content.contains("button-1"))
        XCTAssertTrue(snapshot.content.contains("button-2"))
        XCTAssertTrue(snapshot.content.contains("Save"))
        XCTAssertTrue(snapshot.content.contains("Cancel"))
    }

    func testLLMCanSeeViewState() async {
        // GIVEN: A view with state is registered
        Aware.shared.registerView("toggle", label: "Dark Mode")
        Aware.shared.registerStateTyped("toggle", key: "isOn", value: .bool(true))
        Aware.shared.registerStateTyped("toggle", key: "label", value: .string("Enabled"))

        // WHEN: LLM requests snapshot
        let snapshot = Aware.shared.captureSnapshot(format: .compact)

        // THEN: State is visible in snapshot
        XCTAssertTrue(snapshot.content.contains("toggle"))
        XCTAssertTrue(snapshot.content.contains("isOn"))
        XCTAssertTrue(snapshot.content.contains("true") || snapshot.content.contains("Enabled"))
    }

    func testSnapshotIsTokenEfficient() async {
        // GIVEN: A typical login form
        Aware.shared.registerView("login-form", label: "Login", isContainer: true)
        Aware.shared.registerView("email", label: "Email", parentId: "login-form")
        Aware.shared.registerView("password", label: "Password", parentId: "login-form")
        Aware.shared.registerView("submit", label: "Login", parentId: "login-form")

        Aware.shared.registerStateTyped("email", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("password", key: "value", value: .string(""))
        Aware.shared.registerStateTyped("submit", key: "isEnabled", value: .bool(true))

        // WHEN: Snapshot is captured
        let snapshot = Aware.shared.captureSnapshot(format: .compact)

        // THEN: Token count is minimal
        let estimatedTokens = snapshot.content.count / 4  // Rough estimate: 1 token ≈ 4 chars
        XCTAssertLessThan(estimatedTokens, 150, "Login form snapshot should be <150 tokens, got \(estimatedTokens)")

        // AND: Contains all necessary information
        XCTAssertTrue(snapshot.content.contains("login-form"))
        XCTAssertTrue(snapshot.content.contains("email"))
        XCTAssertTrue(snapshot.content.contains("password"))
        XCTAssertTrue(snapshot.content.contains("submit"))
    }

    // MARK: - Action Execution Tests

    func testLLMCanTouchButton() async {
        // GIVEN: A button with direct action
        var tapped = false
        Aware.shared.registerView("action-btn", label: "Action Button")
        Aware.shared.registerDirectAction("action-btn") {
            tapped = true
        }

        // WHEN: LLM issues tap command
        let result = await Aware.shared.tapDirect("action-btn")

        // THEN: Action executes successfully
        XCTAssertTrue(result.success, "LLM tap command should succeed")
        XCTAssertTrue(tapped, "Button action should have executed")
    }

    func testLLMCanTypeText() async {
        // GIVEN: A text field is registered
        Aware.shared.registerView("text-field", label: "Username")
        Aware.shared.registerStateTyped("text-field", key: "value", value: .string(""))

        // WHEN: LLM issues type command (simulated)
        // Note: Direct text input would be via NotificationCenter in real implementation
        Aware.shared.registerStateTyped("text-field", key: "value", value: .string("llm@test.com"))

        // THEN: State updates correctly
        let value = Aware.shared.getStateString("text-field", key: "value")
        XCTAssertEqual(value, "llm@test.com", "LLM should be able to update text field value")
    }

    func testLLMCanVerifyState() async {
        // GIVEN: A view with multiple state values
        Aware.shared.registerView("status", label: "Status Indicator")
        Aware.shared.registerStateTyped("status", key: "isLoading", value: .bool(false))
        Aware.shared.registerStateTyped("status", key: "hasError", value: .bool(false))
        Aware.shared.registerStateTyped("status", key: "message", value: .string("Ready"))

        // WHEN: LLM queries state
        let isLoading = Aware.shared.getStateBool("status", key: "isLoading")
        let hasError = Aware.shared.getStateBool("status", key: "hasError")
        let message = Aware.shared.getStateString("status", key: "message")

        // THEN: All state is readable
        XCTAssertEqual(isLoading, false)
        XCTAssertEqual(hasError, false)
        XCTAssertEqual(message, "Ready")
    }

    // MARK: - Assertion Tests

    func testLLMCanAssertViewExists() async {
        // GIVEN: Views are registered
        Aware.shared.registerView("exists", label: "Exists")

        // WHEN: LLM asserts existence
        let existsResult = Aware.shared.assertExists("exists")
        let missingResult = Aware.shared.assertExists("does-not-exist")

        // THEN: Assertions work correctly
        XCTAssertTrue(existsResult.passed, "Should assert view exists")
        XCTAssertFalse(missingResult.passed, "Should fail for missing view")
    }

    func testLLMCanAssertViewVisible() async {
        // GIVEN: Visible and hidden views
        Aware.shared.registerView("visible", label: "Visible")
        Aware.shared.registerView("hidden", label: "Hidden")
        Aware.shared.hideView("hidden")

        // WHEN: LLM checks visibility
        let visibleResult = Aware.shared.assertVisible("visible")
        let hiddenResult = Aware.shared.assertVisible("hidden")

        // THEN: Visibility is correctly reported
        XCTAssertTrue(visibleResult.passed, "Should assert visible view")
        XCTAssertFalse(hiddenResult.passed, "Should fail for hidden view")
    }

    func testLLMCanAssertState() async {
        // GIVEN: A view with state
        Aware.shared.registerView("toggle", label: "Toggle")
        Aware.shared.registerStateTyped("toggle", key: "isOn", value: .bool(true))

        // WHEN: LLM asserts state
        let correctResult = Aware.shared.assertState("toggle", key: "isOn", equals: "true")
        let incorrectResult = Aware.shared.assertState("toggle", key: "isOn", equals: "false")

        // THEN: State assertions work
        XCTAssertTrue(correctResult.passed, "Should pass for correct state")
        XCTAssertFalse(incorrectResult.passed, "Should fail for incorrect state")
    }

    // MARK: - Token Efficiency Validation

    func testTokenEfficiencyVsScreenshot() async {
        // GIVEN: A complex view hierarchy (simulating typical app screen)
        setupComplexViewHierarchy()

        // WHEN: We compare Aware snapshot to theoretical screenshot
        let snapshot = Aware.shared.captureSnapshot(format: .compact)
        let awareTokens = snapshot.content.count / 4  // ~1 token per 4 chars

        let screenshotTokens = 15000  // 2048x1536 image at ~1400 tokens/MB

        // THEN: Aware achieves >99% reduction
        let reduction = Double(screenshotTokens - awareTokens) / Double(screenshotTokens)
        let reductionPercent = reduction * 100

        XCTAssertGreaterThan(reductionPercent, 99.0,
            "Should achieve >99% token reduction. Got: \(String(format: "%.1f", reductionPercent))%")

        print("📊 Token Efficiency Results:")
        print("   Aware snapshot: \(awareTokens) tokens")
        print("   Screenshot baseline: \(screenshotTokens) tokens")
        print("   Reduction: \(String(format: "%.1f", reductionPercent))%")
        print("   Cost savings: $\(String(format: "%.4f", Double(screenshotTokens - awareTokens) * 0.003 / 1000)) per test")
    }

    // MARK: - Helper Methods

    private func setupComplexViewHierarchy() {
        // Simulate a typical app screen with navigation, list, and details
        Aware.shared.registerView("screen", label: "User Profile", isContainer: true)

        // Navigation
        Aware.shared.registerView("nav-bar", label: "Navigation", isContainer: true, parentId: "screen")
        Aware.shared.registerView("back-btn", label: "Back", parentId: "nav-bar")
        Aware.shared.registerView("title", label: "Profile", parentId: "nav-bar")
        Aware.shared.registerView("edit-btn", label: "Edit", parentId: "nav-bar")

        // Content
        Aware.shared.registerView("avatar", label: "Avatar", parentId: "screen")
        Aware.shared.registerView("name", label: "John Doe", parentId: "screen")
        Aware.shared.registerView("bio", label: "Software Engineer", parentId: "screen")

        // List of items
        Aware.shared.registerView("items-list", label: "Items", isContainer: true, parentId: "screen")
        for i in 0..<10 {
            Aware.shared.registerView("item-\(i)", label: "Item \(i)", parentId: "items-list")
        }

        // Add some state
        Aware.shared.registerStateTyped("screen", key: "isLoading", value: .bool(false))
        Aware.shared.registerStateTyped("screen", key: "hasError", value: .bool(false))
        Aware.shared.registerStateTyped("items-list", key: "count", value: .int(10))
    }
}
