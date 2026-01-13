//
//  AwareServiceTests.swift
//  Aware
//
//  Basic tests for the Aware framework.
//

import XCTest
@testable import Aware

final class AwareServiceTests: XCTestCase {

    @MainActor
    func testRegisterView() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        let uniqueLabel = "Test View \(viewId)"

        // When
        Aware.shared.registerView(viewId, label: uniqueLabel)

        // Then
        let node = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(node)
        XCTAssertEqual(node?.label, uniqueLabel)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testRegisterState() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")

        // When
        Aware.shared.registerState(viewId, key: "count", value: "42")

        // Then - query by state filter should find the view
        let matchingViews = Aware.shared.query()
            .state("count", equals: "42")
            .where { $0.id == viewId }
            .all()
        XCTAssertFalse(matchingViews.isEmpty)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testSnapshotCapture() async throws {
        // Given
        let viewId = "test-view-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Snapshot Test")

        // When
        let snapshot = Aware.shared.captureSnapshot(format: .json)

        // Then
        XCTAssertFalse(snapshot.content.isEmpty)
        XCTAssertEqual(snapshot.format, AwareSnapshotFormat.json.rawValue)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testQueryBuilder() async throws {
        // Given
        let viewId1 = "button-test-\(UUID().uuidString)"
        let viewId2 = "text-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId1, label: "Save Button")
        Aware.shared.registerView(viewId2, label: "Title Text")

        // When
        let buttonResults = Aware.shared.query().labelContains("Button").all()
        let textResults = Aware.shared.query().labelContains("Text").all()

        // Then
        XCTAssertTrue(buttonResults.contains(where: { $0.id == viewId1 }))
        XCTAssertTrue(textResults.contains(where: { $0.id == viewId2 }))

        // Cleanup
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }

    // MARK: - Staleness Detection Tests

    @MainActor
    func testStalenessDetection() async throws {
        // Given
        let viewId = "staleness-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Stale View")

        // Register prop-state binding with initial values
        Aware.shared.registerPropStateBinding(
            viewId,
            propKey: "selectedIndex",
            stateKey: "currentSelection",
            propValue: "0",
            stateValue: "0"
        )

        // When: Update prop without updating state (simulates staleness)
        Aware.shared.updatePropValue(viewId, propKey: "selectedIndex", newPropValue: "5")

        // Wait for staleness threshold (300ms + buffer)
        try await Task.sleep(nanoseconds: 400_000_000)

        // Then: Should detect staleness
        let warnings = Aware.shared.getStalenessWarnings(for: viewId)
        XCTAssertFalse(warnings.isEmpty, "Should detect staleness when prop changes but state doesn't")

        // Cleanup
        Aware.shared.clearPropStateBindings(viewId)
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testStalenessClearing() async throws {
        // Given
        let viewId = "staleness-clear-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Clear Stale View")

        Aware.shared.registerPropStateBinding(
            viewId,
            propKey: "index",
            stateKey: "selection",
            propValue: "0",
            stateValue: "0"
        )

        // When: Update prop then update state (simulates proper sync)
        Aware.shared.updatePropValue(viewId, propKey: "index", newPropValue: "10")
        Aware.shared.updateStateValue(viewId, stateKey: "selection", newStateValue: "10")

        // Then: No staleness should be detected
        let result = Aware.shared.assertNoPropStateStaleness(viewId: viewId)
        XCTAssertTrue(result.passed, "Should have no staleness when state follows prop")

        // Cleanup
        Aware.shared.clearPropStateBindings(viewId)
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Direct Action Callback Tests

    @MainActor
    func testTapDirectCallback() async throws {
        // Given
        let viewId = "tap-test-\(UUID().uuidString)"
        var callbackExecuted = false

        Aware.shared.registerView(viewId, label: "Tap Button")
        Aware.shared.updateFrame(viewId, frame: CGRect(x: 0, y: 0, width: 100, height: 50))

        // Register direct action callback
        Aware.shared.registerAction(viewId) {
            callbackExecuted = true
        }

        // When: Execute tap via direct callback
        let result = await Aware.shared.tapDirect(viewId)

        // Then
        XCTAssertTrue(result.success, "Tap should succeed")
        XCTAssertTrue(callbackExecuted, "Callback should have been executed")

        // Cleanup
        Aware.shared.unregisterAction(viewId)
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testHasDirectAction() async throws {
        // Given
        let viewId = "action-check-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Action View")

        // Initially no action
        XCTAssertFalse(Aware.shared.hasDirectAction(viewId))

        // When: Register action
        Aware.shared.registerAction(viewId) { }

        // Then
        XCTAssertTrue(Aware.shared.hasDirectAction(viewId))

        // Cleanup
        Aware.shared.unregisterAction(viewId)
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Snapshot Format Tests

    @MainActor
    func testCompactSnapshotFormat() async throws {
        // Given
        let viewId = "format-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Compact Test View")
        Aware.shared.registerState(viewId, key: "value", value: "42")

        // When
        let compact = Aware.shared.captureSnapshot(format: .compact)
        let json = Aware.shared.captureSnapshot(format: .json)

        // Then: Compact should be shorter than JSON
        XCTAssertLessThan(compact.content.count, json.content.count, "Compact format should be shorter")
        XCTAssertEqual(compact.format, "compact")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testTextSnapshotFormat() async throws {
        // Given
        let viewId = "text-format-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Text Format Test")

        // When
        let text = Aware.shared.captureSnapshot(format: .text)

        // Then
        XCTAssertFalse(text.content.isEmpty)
        XCTAssertEqual(text.format, "text")
        XCTAssertTrue(text.content.contains("Text Format Test"), "Should contain the label")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testMarkdownSnapshotFormat() async throws {
        // Given
        let viewId = "md-format-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Markdown Test")

        // When
        let markdown = Aware.shared.captureSnapshot(format: .markdown)

        // Then
        XCTAssertFalse(markdown.content.isEmpty)
        XCTAssertEqual(markdown.format, "markdown")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - Assertion Tests

    @MainActor
    func testAssertNoPropStateStaleness() async throws {
        // Given: Clean view with no bindings
        let viewId = "assert-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Assert Test")

        // When: Check for staleness on view with no bindings
        let result = Aware.shared.assertNoPropStateStaleness(viewId: viewId)

        // Then: Should pass (no staleness possible without bindings)
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.message, "No prop-state staleness detected")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    // MARK: - State Registry Tests

    @MainActor
    func testGetAllStates() async throws {
        // Given
        let viewId = "states-test-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "States Test")
        Aware.shared.registerState(viewId, key: "count", value: "5")
        Aware.shared.registerState(viewId, key: "name", value: "Test")

        // When
        let allStates = Aware.shared.getAllStates()

        // Then
        XCTAssertNotNil(allStates[viewId])
        XCTAssertEqual(allStates[viewId]?["count"], "5")
        XCTAssertEqual(allStates[viewId]?["name"], "Test")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testListRegisteredActions() async throws {
        // Given
        let viewId1 = "test-action-1-\(UUID().uuidString)"
        let viewId2 = "test-action-2-\(UUID().uuidString)"

        // When
        Aware.shared.registerAction(viewId1) { print("Action 1") }
        Aware.shared.registerAction(viewId2) { print("Action 2") }

        // Then
        let actions = Aware.shared.listRegisteredActions()
        XCTAssertTrue(actions.contains(viewId1))
        XCTAssertTrue(actions.contains(viewId2))
        XCTAssertEqual(actions.count, 2)

        // Cleanup
        Aware.shared.unregisterAction(viewId1)
        Aware.shared.unregisterAction(viewId2)
    }

    // MARK: - Additional Comprehensive Tests

    @MainActor
    func testUnregisterView() async throws {
        // Given
        let viewId = "test-unregister-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")

        // Verify view exists and is visible
        let view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(view)
        XCTAssertTrue(view?.isVisible ?? false)

        // When
        Aware.shared.unregisterView(viewId)

        // Then - view still exists but is marked as not visible
        let unregisteredView = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(unregisteredView)
        XCTAssertFalse(unregisteredView?.isVisible ?? true)

        // Cleanup - actually remove from registry
        Aware.shared.reset()
    }

    @MainActor
    func testReset() async throws {
        // Given
        let viewId1 = "test-reset-1-\(UUID().uuidString)"
        let viewId2 = "test-reset-2-\(UUID().uuidString)"
        Aware.shared.registerView(viewId1, label: "View 1")
        Aware.shared.registerView(viewId2, label: "View 2")
        Aware.shared.registerState(viewId1, key: "test", value: "value")

        // Verify views exist
        XCTAssertEqual(Aware.shared.visibleViewCount, 2)

        // When
        Aware.shared.reset()

        // Then
        XCTAssertEqual(Aware.shared.visibleViewCount, 0)
        XCTAssertTrue(Aware.shared.registeredViewIds.isEmpty)
        XCTAssertTrue(Aware.shared.getAllStates().isEmpty)
    }

    @MainActor
    func testAssertVisible() async throws {
        // Given
        let viewId = "test-assert-visible-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")

        // When & Then
        let result = Aware.shared.assertVisible(viewId)
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.message, "View '\(viewId)' is visible")

        // Test non-existent view
        let nonexistentResult = Aware.shared.assertVisible("nonexistent")
        XCTAssertFalse(nonexistentResult.passed)
        XCTAssertTrue(nonexistentResult.message.contains("not found"))

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testAssertState() async throws {
        // Given
        let viewId = "test-assert-state-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        Aware.shared.registerState(viewId, key: "status", value: "active")

        // When & Then
        let result = Aware.shared.assertState(viewId, key: "status", equals: "active")
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.message, "View '\(viewId)'.status == 'active'")

        // Test incorrect value
        let wrongResult = Aware.shared.assertState(viewId, key: "status", equals: "inactive")
        XCTAssertFalse(wrongResult.passed)
        XCTAssertTrue(wrongResult.message.contains("is 'active', expected 'inactive'"))

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testAssertExists() async throws {
        // Given
        let viewId = "test-assert-exists-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")

        // When & Then
        let result = Aware.shared.assertExists(viewId)
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.message, "View '\(viewId)' exists")

        // Test non-existent view
        let nonexistentResult = Aware.shared.assertExists("nonexistent")
        XCTAssertFalse(nonexistentResult.passed)
        XCTAssertTrue(nonexistentResult.message.contains("does not exist"))

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testAssertViewCount() async throws {
        // Given
        let initialCount = Aware.shared.visibleViewCount
        let viewId1 = "test-count-1-\(UUID().uuidString)"
        let viewId2 = "test-count-2-\(UUID().uuidString)"
        Aware.shared.registerView(viewId1, label: "View 1")
        Aware.shared.registerView(viewId2, label: "View 2")

        // When & Then
        let result = Aware.shared.assertViewCount(initialCount + 2)
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.message, "View count is \(initialCount + 2)")

        // Test incorrect count
        let wrongResult = Aware.shared.assertViewCount(999)
        XCTAssertFalse(wrongResult.passed)
        XCTAssertTrue(wrongResult.message.contains("expected 999"))

        // Cleanup
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }

    @MainActor
    func testRegisterAction() async throws {
        // Given
        let viewId = "test-register-action-\(UUID().uuidString)"
        var actionCalled = false

        // When
        Aware.shared.registerAction(viewId) {
            actionCalled = true
        }

        // Then
        XCTAssertTrue(Aware.shared.hasDirectAction(viewId))

        // Test unregister
        Aware.shared.unregisterAction(viewId)
        XCTAssertFalse(Aware.shared.hasDirectAction(viewId))
    }

    @MainActor
    func testFindElements() async throws {
        // Given
        let viewId1 = "test-find-1-\(UUID().uuidString)"
        let viewId2 = "test-find-2-\(UUID().uuidString)"
        Aware.shared.registerView(viewId1, label: "Button View")
        Aware.shared.registerView(viewId2, label: "Text View")

        // When
        let allViews = Aware.shared.findElements { $0.isVisible }

        // Then
        XCTAssertTrue(allViews.count >= 2)
        XCTAssertTrue(allViews.contains { $0.id == viewId1 })
        XCTAssertTrue(allViews.contains { $0.id == viewId2 })

        // Cleanup
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }

    @MainActor
    func testFindByLabel() async throws {
        // Given
        let viewId = "test-find-label-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Login Button")

        // When
        let results = Aware.shared.findByLabel("Login")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, viewId)

        // Test case-insensitive
        let caseResults = Aware.shared.findByLabel("login")
        XCTAssertEqual(caseResults.count, 1)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testFindByState() async throws {
        // Given
        let viewId = "test-find-state-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        Aware.shared.registerState(viewId, key: "enabled", value: "true")

        // When
        let results = Aware.shared.findByState(key: "enabled", value: "true")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, viewId)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testUpdateFrame() async throws {
        // Given
        let viewId = "test-frame-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        let newFrame = CGRect(x: 10, y: 20, width: 100, height: 200)

        // When
        Aware.shared.updateFrame(viewId, frame: newFrame)

        // Then
        let view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(view?.frame, newFrame)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testClearState() async throws {
        // Given
        let viewId = "test-clear-state-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        Aware.shared.registerState(viewId, key: "testKey", value: "testValue")

        // Verify state exists
        XCTAssertEqual(Aware.shared.getStateValue(viewId, key: "testKey"), "testValue")

        // When
        Aware.shared.clearState(viewId)

        // Then
        XCTAssertNil(Aware.shared.getStateValue(viewId, key: "testKey"))

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testStateMatches() async throws {
        // Given
        let viewId = "test-state-match-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        Aware.shared.registerState(viewId, key: "status", value: "active")

        // When & Then
        XCTAssertTrue(Aware.shared.stateMatches(viewId, key: "status", value: "active"))
        XCTAssertFalse(Aware.shared.stateMatches(viewId, key: "status", value: "inactive"))
        XCTAssertFalse(Aware.shared.stateMatches(viewId, key: "nonexistent", value: "active"))

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testRegisterAnimation() async throws {
        // Given
        let viewId = "test-animation-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        let animationState = AwareAnimationState(isAnimating: true, animationType: "spring", duration: 0.3)

        // When
        Aware.shared.registerAnimation(viewId, animation: animationState)

        // Then
        let view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertEqual(view?.animation?.animationType, "spring")
        XCTAssertEqual(view?.animation?.duration, 0.3)
        XCTAssertEqual(view?.animation?.isAnimating, true)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testClearAnimation() async throws {
        // Given
        let viewId = "test-clear-animation-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View")
        let animationState = AwareAnimationState(isAnimating: true, animationType: "spring", duration: 0.3)
        Aware.shared.registerAnimation(viewId, animation: animationState)

        // Verify animation exists
        var view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNotNil(view?.animation)

        // When
        Aware.shared.clearAnimation(viewId)

        // Then
        view = Aware.shared.query().where { $0.id == viewId }.first()
        XCTAssertNil(view?.animation)

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testDescribeView() async throws {
        // Given
        let viewId = "test-describe-\(UUID().uuidString)"
        Aware.shared.registerView(viewId, label: "Test View", isContainer: true)
        Aware.shared.registerState(viewId, key: "count", value: "5")

        // When
        let description = Aware.shared.describeView(viewId)

        // Then
        XCTAssertNotNil(description)
        XCTAssertEqual(description?.id, viewId)
        XCTAssertEqual(description?.label, "Test View")
        XCTAssertEqual(description?.isVisible, true)
        XCTAssertEqual(description?.state?["count"], "5")

        // Cleanup
        Aware.shared.unregisterView(viewId)
    }

    @MainActor
    func testRegisteredViewIds() async throws {
        // Given
        let viewId1 = "test-ids-1-\(UUID().uuidString)"
        let viewId2 = "test-ids-2-\(UUID().uuidString)"

        // Initially should be empty or have existing views
        let initialCount = Aware.shared.registeredViewIds.count

        // When
        Aware.shared.registerView(viewId1, label: "View 1")
        Aware.shared.registerView(viewId2, label: "View 2")

        // Then
        let viewIds = Aware.shared.registeredViewIds
        XCTAssertTrue(viewIds.contains(viewId1))
        XCTAssertTrue(viewIds.contains(viewId2))
        XCTAssertEqual(viewIds.count, initialCount + 2)

        // Cleanup
        Aware.shared.unregisterView(viewId1)
        Aware.shared.unregisterView(viewId2)
    }

    @MainActor
    func testVisibleViewCount() async throws {
        // Given
        let viewId1 = "test-visible-1-\(UUID().uuidString)"
        let viewId2 = "test-visible-2-\(UUID().uuidString)"

        let initialCount = Aware.shared.visibleViewCount

        // When
        Aware.shared.registerView(viewId1, label: "Visible View")
        Aware.shared.registerView(viewId2, label: "Hidden View")

        // Then
        XCTAssertEqual(Aware.shared.visibleViewCount, initialCount + 2)

        // When making one invisible
        Aware.shared.unregisterView(viewId1)

        // Then
        XCTAssertEqual(Aware.shared.visibleViewCount, initialCount + 1)

        // Cleanup
        Aware.shared.unregisterView(viewId2)
    }
}
