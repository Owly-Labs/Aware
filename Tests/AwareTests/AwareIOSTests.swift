//
//  AwareIOSTests.swift
//  Aware
//
//  Created by AetherSing Team
//  Tests for iOS-specific UIAware features integrated into Aware
//

import XCTest
@testable import Aware

#if os(iOS)
final class AwareIOSTests: XCTestCase {
    var aware: Aware!

    override func setUp() {
        super.setUp()
        aware = Aware.shared
        aware.reset()
    }

    override func tearDown() {
        aware.reset()
        super.tearDown()
    }

    // MARK: - iOS Platform Configuration Tests

    func testIOSPlatformConfiguration() {
        // Configure for iOS
        Aware.configureForIOS(ipcPath: "/tmp/aware-test")

        // Verify IPC service is initialized
        // Note: This would require internal access, so we test via behavior
    }

    // MARK: - Direct Action Callbacks Tests

    func testDirectActionRegistration() async {
        var actionCalled = false

        // Register action callback
        AwareIOSPlatform.shared.registerActionCallback("test-button") {
            actionCalled = true
        }

        // Execute direct action
        let result = await AwareIOSPlatform.shared.tapDirect("test-button")

        // Verify action was executed
        XCTAssertTrue(result, "Direct tap should succeed")
        XCTAssertTrue(actionCalled, "Action callback should be executed")

        // Test non-existent action
        let failResult = await AwareIOSPlatform.shared.tapDirect("non-existent")
        XCTAssertFalse(failResult, "Direct tap on non-existent action should fail")
    }

    // MARK: - iOS-Specific Assertions Tests

    func testIOSAssertions() {
        // Register test views with iOS-specific state
        aware.registerView("test-textfield", label: "Test Field", type: .textField, frame: .zero)
        aware.registerState("test-textfield", key: "isFocused", value: "true")
        aware.registerState("test-textfield", key: "isEmpty", value: "false")
        aware.registerState("test-textfield", key: "charCount", value: "5")

        aware.registerView("test-toggle", label: "Test Toggle", type: .toggle, frame: .zero)
        aware.registerState("test-toggle", key: "isOn", value: "true")

        aware.registerView("test-slider", label: "Test Slider", type: .slider, frame: .zero)
        aware.registerState("test-slider", key: "value", value: "0.75")

        // Test iOS-specific assertions
        XCTAssertTrue(aware.assertFocused("test-textfield").passed, "Text field should be focused")
        XCTAssertTrue(aware.assertNotFocused("non-existent").passed == false, "Non-existent view should not be focused")

        XCTAssertTrue(aware.assertToggleOn("test-toggle").passed, "Toggle should be on")
        XCTAssertTrue(aware.assertToggleOff("test-toggle").passed == false, "Toggle should not be off")

        XCTAssertTrue(aware.assertTextFieldNotEmpty("test-textfield").passed, "Text field should not be empty")

        XCTAssertTrue(aware.assertSliderValue("test-slider", expected: 0.75).passed, "Slider should have correct value")
        XCTAssertTrue(aware.assertSliderValue("test-slider", expected: 0.8, tolerance: 0.1).passed, "Slider should be within tolerance")
        XCTAssertTrue(aware.assertSliderValue("test-slider", expected: 0.5, tolerance: 0.1).passed == false, "Slider should not be within tolerance")
    }

    // MARK: - iOS Modifier Integration Tests

    func testIOSModifierIntegration() {
        // This would require SwiftUI testing infrastructure
        // For now, we test that the modifiers compile and can be instantiated

        // Test that the modifier types exist and can be created
        let buttonModifier = AwareButtonModifier(id: "test-btn", label: "Test", action: nil)
        XCTAssertNotNil(buttonModifier)

        let textFieldModifier = AwareTextFieldModifier(
            id: "test-field",
            text: .constant("test"),
            label: "Test Field",
            placeholder: nil,
            isFocused: nil
        )
        XCTAssertNotNil(textFieldModifier)
    }

    // MARK: - IPC Communication Tests

    func testIPCCommunication() async {
        // Configure IPC
        Aware.configureForIOS(ipcPath: "/tmp/aware-ipc-test")

        // Create and send command
        let command = AwareCommand(type: "test", viewId: "test-view", parameters: ["key": "value"])

        // Note: Full IPC testing would require a running app
        // This tests the command/result structure
        XCTAssertEqual(command.type, "test")
        XCTAssertEqual(command.viewId, "test-view")
        XCTAssertEqual(command.parameters?["key"], "value")
    }

    // MARK: - Performance Tests

    func testIOSAssertionPerformance() {
        // Register many views for performance testing
        for i in 0..<100 {
            aware.registerView("view-\(i)", label: "View \(i)", type: .textField, frame: .zero)
            aware.registerState("view-\(i)", key: "isFocused", value: i % 2 == 0 ? "true" : "false")
        }

        measure {
            // Test assertion performance
            for i in 0..<100 {
                let result = aware.assertFocused("view-\(i)")
                XCTAssertNotNil(result)
            }
        }
    }
}
#endif