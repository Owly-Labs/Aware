//  AwareIntegrationTests.swift
//  Aware
//
//  End-to-end integration tests for complex UI interaction scenarios.
//  Tests realistic usage patterns and multi-step workflows.
//

import XCTest
@testable import Aware

@MainActor
final class AwareIntegrationTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        Aware.shared.reset()
    }

    override func tearDown() async throws {
        Aware.shared.reset()
        try await super.tearDown()
    }

    // MARK: - Login Flow Integration

    func testLoginFlowIntegration() async throws {
        // Given: A login form with email/password fields and login button
        let emailFieldId = "email-field"
        let passwordFieldId = "password-field"
        let loginButtonId = "login-button"

        // Register UI components
        Aware.shared.registerView(emailFieldId, label: "Email Input")
        Aware.shared.registerView(passwordFieldId, label: "Password Input")
        Aware.shared.registerView(loginButtonId, label: "Login Button")

        // Add state and actions
        Aware.shared.registerState(emailFieldId, key: "value", value: "")
        Aware.shared.registerState(passwordFieldId, key: "value", value: "")
        Aware.shared.registerAction(loginButtonId) { /* login logic */ }

        // When: User fills out form and logs in (simulate by updating state directly)
        Aware.shared.registerState(emailFieldId, key: "value", value: "user@example.com")
        Aware.shared.registerState(passwordFieldId, key: "value", value: "password123")
        let loginResult = await Aware.shared.tapDirect(loginButtonId)

        // Then: All interactions succeed
        XCTAssertTrue(loginResult.success)

        // And: State is updated correctly
        XCTAssertEqual(Aware.shared.getStateValue(emailFieldId, key: "value"), "user@example.com")
        XCTAssertEqual(Aware.shared.getStateValue(passwordFieldId, key: "value"), "password123")

        // And: Button action was registered
        XCTAssertTrue(Aware.shared.hasDirectAction(loginButtonId))
    }

    // MARK: - Navigation Flow Integration

    func testTabNavigationIntegration() async throws {
        // Given: A tabbed interface with multiple screens
        let tabBarId = "tab-bar"
        let homeTabId = "home-tab"
        let profileTabId = "profile-tab"
        let settingsTabId = "settings-tab"

        // Register navigation components
        Aware.shared.registerView(tabBarId, label: "Main Tab Bar")
        Aware.shared.registerView(homeTabId, label: "Home Tab", parentId: tabBarId)
        Aware.shared.registerView(profileTabId, label: "Profile Tab", parentId: tabBarId)
        Aware.shared.registerView(settingsTabId, label: "Settings Tab", parentId: tabBarId)

        // Add navigation actions
        Aware.shared.registerAction(homeTabId) { /* navigate to home */ }
        Aware.shared.registerAction(profileTabId) { /* navigate to profile */ }
        Aware.shared.registerAction(settingsTabId) { /* navigate to settings */ }

        // When: User navigates between tabs
        let homeResult = await Aware.shared.tapDirect(homeTabId)
        let profileResult = await Aware.shared.tapDirect(profileTabId)
        let settingsResult = await Aware.shared.tapDirect(settingsTabId)

        // Then: All navigation actions succeed
        XCTAssertTrue(homeResult.success)
        XCTAssertTrue(profileResult.success)
        XCTAssertTrue(settingsResult.success)

        // And: All tabs are properly registered
        XCTAssertEqual(Aware.shared.visibleViewCount, 4)
    }

    // MARK: - Form Validation Integration

    func testFormValidationIntegration() async throws {
        // Given: A registration form with validation
        let nameFieldId = "name-field"
        let emailFieldId = "email-field"
        let submitButtonId = "submit-button"
        let errorLabelId = "error-label"

        // Register form components
        Aware.shared.registerView(nameFieldId, label: "Name Field")
        Aware.shared.registerView(emailFieldId, label: "Email Field")
        Aware.shared.registerView(submitButtonId, label: "Submit Button")
        Aware.shared.registerView(errorLabelId, label: "Error Message")

        // Add validation state
        Aware.shared.registerState(nameFieldId, key: "isValid", value: "false")
        Aware.shared.registerState(emailFieldId, key: "isValid", value: "false")
        Aware.shared.registerState(errorLabelId, key: "text", value: "")

        // When: User enters invalid data (simulate by setting state)
        Aware.shared.registerState(nameFieldId, key: "isValid", value: "false")
        Aware.shared.registerState(emailFieldId, key: "isValid", value: "false")

        // Then: Validation fails appropriately
        let nameValid = Aware.shared.getStateValue(nameFieldId, key: "isValid")
        let emailValid = Aware.shared.getStateValue(emailFieldId, key: "isValid")
        XCTAssertEqual(nameValid, "false")
        XCTAssertEqual(emailValid, "false")

        // When: User corrects the form
        Aware.shared.registerState(nameFieldId, key: "isValid", value: "true")
        Aware.shared.registerState(emailFieldId, key: "isValid", value: "true")
        Aware.shared.registerAction(submitButtonId) { /* submit logic */ }

        // Then: Form becomes valid
        let correctedNameValid = Aware.shared.getStateValue(nameFieldId, key: "isValid")
        let correctedEmailValid = Aware.shared.getStateValue(emailFieldId, key: "isValid")
        XCTAssertEqual(correctedNameValid, "true")
        XCTAssertEqual(correctedEmailValid, "true")
        XCTAssertTrue(Aware.shared.hasDirectAction(submitButtonId))
    }

    // MARK: - Search and Filter Integration

    func testSearchAndFilterIntegration() async throws {
        // Given: A list with items
        let listContainerId = "item-list"

        // Register list container
        Aware.shared.registerView(listContainerId, label: "Item List", isContainer: true)

        // Add list items with categories
        for i in 1...10 {
            let itemId = "item-\(i)"
            Aware.shared.registerView(itemId, label: "Item \(i)", parentId: listContainerId)
            Aware.shared.registerState(itemId, key: "category", value: i % 2 == 0 ? "even" : "odd")
        }

        // When: User filters by category
        let evenItems = Aware.shared.findByState(key: "category", value: "even")
        let oddItems = Aware.shared.findByState(key: "category", value: "odd")

        // Then: Filtering works correctly
        XCTAssertEqual(evenItems.count, 5)  // Items 2, 4, 6, 8, 10
        XCTAssertEqual(oddItems.count, 5)   // Items 1, 3, 5, 7, 9

        // And: All items are children of the list container
        let allItems = Aware.shared.findElements { $0.parentId == listContainerId }
        XCTAssertEqual(allItems.count, 10)
    }

    // MARK: - Error Handling Integration

    func testErrorHandlingIntegration() async throws {
        // Given: A form that can encounter errors
        let inputFieldId = "input-field"
        let submitButtonId = "submit-button"
        let errorMessageId = "error-message"

        // Register components
        Aware.shared.registerView(inputFieldId, label: "Input Field")
        Aware.shared.registerView(submitButtonId, label: "Submit Button")
        Aware.shared.registerView(errorMessageId, label: "Error Message")

        // Add error state
        Aware.shared.registerState(errorMessageId, key: "text", value: "")
        Aware.shared.registerState(errorMessageId, key: "isVisible", value: "false")

        // When: User submits invalid data
        await Aware.shared.setText(inputFieldId, text: "invalid-data")
        Aware.shared.registerAction(submitButtonId) {
            // Simulate server error
            Aware.shared.registerState("error-message", key: "text", value: "Invalid input format")
            Aware.shared.registerState("error-message", key: "isVisible", value: "true")
        }

        let submitResult = await Aware.shared.tapDirect(submitButtonId)

        // Then: Error is displayed appropriately
        XCTAssertTrue(submitResult.success)
        let errorText = Aware.shared.getStateValue(errorMessageId, key: "text")
        let errorVisible = Aware.shared.getStateValue(errorMessageId, key: "isVisible")
        XCTAssertEqual(errorText, "Invalid input format")
        XCTAssertEqual(errorVisible, "true")

        // And: Error can be dismissed
        let clearErrorAction = {
            Aware.shared.registerState("error-message", key: "text", value: "")
            Aware.shared.registerState("error-message", key: "isVisible", value: "false")
        }

        // Simulate clearing error
        clearErrorAction()

        let clearedErrorText = Aware.shared.getStateValue(errorMessageId, key: "text")
        let clearedErrorVisible = Aware.shared.getStateValue(errorMessageId, key: "isVisible")
        XCTAssertEqual(clearedErrorText, "")
        XCTAssertEqual(clearedErrorVisible, "false")
    }

    // MARK: - Snapshot and State Persistence

    func testSnapshotStatePersistenceIntegration() async throws {
        // Given: A complex UI state
        setupComplexUI()

        // When: We capture a snapshot
        let snapshot = Aware.shared.captureSnapshot(format: .compact)

        // Then: Snapshot contains all expected data
        XCTAssertGreaterThan(snapshot.viewCount, 5)
        XCTAssertFalse(snapshot.content.isEmpty)

        // And: Content includes our test views
        XCTAssertTrue(snapshot.content.contains("test-form") || snapshot.content.contains("Test Form"))
        XCTAssertTrue(snapshot.content.contains("submit-button") || snapshot.content.contains("Submit Button"))

        // When: We reset and restore state
        let viewCountBefore = Aware.shared.visibleViewCount
        Aware.shared.reset()
        XCTAssertEqual(Aware.shared.visibleViewCount, 0)

        // Then: Reset works completely
        XCTAssertEqual(Aware.shared.registeredViewIds.count, 0)
        XCTAssertTrue(Aware.shared.getAllStates().isEmpty)
    }

    // MARK: - Helper Methods

    private func setupComplexUI() {
        // Form container
        Aware.shared.registerView("test-form", label: "Test Form", isContainer: true)

        // Input fields
        Aware.shared.registerView("name-input", label: "Name Input", parentId: "test-form")
        Aware.shared.registerView("email-input", label: "Email Input", parentId: "test-form")

        // Buttons
        Aware.shared.registerView("submit-button", label: "Submit Button", parentId: "test-form")
        Aware.shared.registerView("cancel-button", label: "Cancel Button", parentId: "test-form")

        // Status messages
        Aware.shared.registerView("success-message", label: "Success Message", parentId: "test-form")
        Aware.shared.registerView("error-message", label: "Error Message", parentId: "test-form")

        // Add state to inputs
        Aware.shared.registerState("name-input", key: "value", value: "John Doe")
        Aware.shared.registerState("email-input", key: "value", value: "john@example.com")

        // Add actions to buttons
        Aware.shared.registerAction("submit-button") { /* submit */ }
        Aware.shared.registerAction("cancel-button") { /* cancel */ }

        // Add visibility state
        Aware.shared.registerState("success-message", key: "isVisible", value: "false")
        Aware.shared.registerState("error-message", key: "isVisible", value: "false")
    }
}