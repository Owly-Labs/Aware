//
//  AwareFinding.swift
//  Breathe
//
//  Element finding, assertions, and diff tracking methods extracted from AwareService.swift
//  Phase 3.2 Architecture Refactoring
//

import SwiftUI

extension Aware {

    // MARK: - Element Finding

    /// Find elements matching a predicate
    public func findElements(where predicate: (AwareViewSnapshot) -> Bool) -> [AwareViewSnapshot] {
        viewRegistry.values.filter(predicate)
    }

    /// Find elements by label (partial match, case-insensitive)
    public func findByLabel(_ label: String) -> [AwareViewSnapshot] {
        let lowered = label.lowercased()
        return viewRegistry.values.filter {
            $0.label?.lowercased().contains(lowered) == true
        }
    }

    /// Find elements by text content (partial match)
    public func findByText(_ text: String) -> [AwareViewSnapshot] {
        let lowered = text.lowercased()
        return viewRegistry.values.filter {
            $0.isVisible && $0.visual?.text?.lowercased().contains(lowered) == true
        }
    }

    /// Find elements by state key-value
    public func findByState(key: String, value: String) -> [AwareViewSnapshot] {
        viewRegistry.values.filter { snapshot in
            snapshot.isVisible && stateRegistry[snapshot.id]?[key] == value
        }
    }

    /// Find all tappable elements
    public func findTappable() -> [AwareViewSnapshot] {
        viewRegistry.values.filter { $0.action != nil && $0.isVisible }
    }

    /// Find elements by action type
    public func findByActionType(_ type: AwareActionMetadata.ActionType) -> [AwareViewSnapshot] {
        viewRegistry.values.filter { $0.action?.actionType == type && $0.isVisible }
    }

    /// Find elements with focus
    public func findFocused() -> AwareViewSnapshot? {
        viewRegistry.values.first { $0.visual?.isFocused == true }
    }

    /// Query builder for chainable element finding
    public func query() -> AwareElementQuery {
        let visibleSnapshots = viewRegistry.values.filter { $0.isVisible }
        return AwareElementQuery(snapshots: Array(visibleSnapshots), stateRegistry: stateRegistry)
    }

    // MARK: - Assertions

    /// Assert that a view is visible
    public func assertVisible(_ viewId: String) -> AwareAssertionResult {
        guard let registration = viewRegistry[viewId] else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)' not found")
        }
        let snapshot = registration.snapshot
        if snapshot.isVisible {
            return AwareAssertionResult(passed: true, message: "View '\(viewId)' is visible")
        } else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)' exists but is not visible")
        }
    }

    /// Assert that a view has a specific state value
    public func assertState(_ viewId: String, key: String, equals expected: String) -> AwareAssertionResult {
        guard let state = stateRegistry[viewId] else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)' has no registered state")
        }
        guard let actual = state[key] else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)' has no state key '\(key)'")
        }
        if actual == expected {
            return AwareAssertionResult(passed: true, message: "View '\(viewId)'.\(key) == '\(expected)'")
        } else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)'.\(key) is '\(actual)', expected '\(expected)'")
        }
    }

    /// Assert that a view's text contains a substring
    public func assertTextContains(_ viewId: String, substring: String) -> AwareAssertionResult {
        guard let registration = viewRegistry[viewId],
              let text = registration.snapshot.visual?.text else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)' has no text")
        }
        if text.contains(substring) {
            return AwareAssertionResult(passed: true, message: "View '\(viewId)' text contains '\(substring)'")
        } else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)' text '\(text)' does not contain '\(substring)'")
        }
    }

    /// Assert that a view exists
    public func assertExists(_ viewId: String) -> AwareAssertionResult {
        if viewRegistry[viewId] != nil {
            return AwareAssertionResult(passed: true, message: "View '\(viewId)' exists")
        } else {
            return AwareAssertionResult(passed: false, message: "View '\(viewId)' does not exist")
        }
    }

    /// Assert view count matches expected
    public func assertViewCount(_ expected: Int) -> AwareAssertionResult {
        let actual = visibleViewCount
        if actual == expected {
            return AwareAssertionResult(passed: true, message: "View count is \(expected)")
        } else {
            return AwareAssertionResult(passed: false, message: "View count is \(actual), expected \(expected)")
        }
    }

    // MARK: - iOS-Specific Assertions (AetherSing Contribution)

    #if os(iOS)
    /// Assert that a text field is focused
    public func assertFocused(_ viewId: String) -> AwareAssertionResult {
        let result = assertState(viewId, key: "isFocused", equals: "true")
        return AwareAssertionResult(
            passed: result.passed,
            message: result.passed ? "View '\(viewId)' is focused" : "View '\(viewId)' is not focused"
        )
    }

    /// Assert that a text field is not focused
    public func assertNotFocused(_ viewId: String) -> AwareAssertionResult {
        let result = assertState(viewId, key: "isFocused", equals: "false")
        return AwareAssertionResult(
            passed: result.passed,
            message: result.passed ? "View '\(viewId)' is not focused" : "View '\(viewId)' is focused"
        )
    }

    /// Assert that a toggle is on
    public func assertToggleOn(_ viewId: String) -> AwareAssertionResult {
        let result = assertState(viewId, key: "isOn", equals: "true")
        return AwareAssertionResult(
            passed: result.passed,
            message: result.passed ? "Toggle '\(viewId)' is on" : "Toggle '\(viewId)' is off"
        )
    }

    /// Assert that a toggle is off
    public func assertToggleOff(_ viewId: String) -> AwareAssertionResult {
        let result = assertState(viewId, key: "isOn", equals: "false")
        return AwareAssertionResult(
            passed: result.passed,
            message: result.passed ? "Toggle '\(viewId)' is off" : "Toggle '\(viewId)' is on"
        )
    }

    /// Assert that a text field is empty
    public func assertTextFieldEmpty(_ viewId: String) -> AwareAssertionResult {
        let result = assertState(viewId, key: "isEmpty", equals: "true")
        return AwareAssertionResult(
            passed: result.passed,
            message: result.passed ? "Text field '\(viewId)' is empty" : "Text field '\(viewId)' is not empty"
        )
    }

    /// Assert that a text field is not empty
    public func assertTextFieldNotEmpty(_ viewId: String) -> AwareAssertionResult {
        let result = assertState(viewId, key: "isEmpty", equals: "false")
        return AwareAssertionResult(
            passed: result.passed,
            message: result.passed ? "Text field '\(viewId)' is not empty" : "Text field '\(viewId)' is empty"
        )
    }

    /// Assert that a slider has a specific value within tolerance
    public func assertSliderValue(_ viewId: String, expected: Double, tolerance: Double = 0.01) -> AwareAssertionResult {
        guard let stateString = getStateValue(viewId, key: "value"),
              let actual = Double(stateString) else {
            return AwareAssertionResult(passed: false, message: "Slider '\(viewId)' has no valid value")
        }

        let lowerBound = expected - tolerance
        let upperBound = expected + tolerance

        if actual >= lowerBound && actual <= upperBound {
            return AwareAssertionResult(passed: true, message: "Slider '\(viewId)' value \(actual) is within tolerance of \(expected)")
        } else {
            return AwareAssertionResult(passed: false, message: "Slider '\(viewId)' value \(actual) is not within tolerance of \(expected)")
        }
    }

    /// Assert that a picker has a specific selection
    public func assertPickerSelection(_ viewId: String, expected: String) -> AwareAssertionResult {
        return assertState(viewId, key: "selection", equals: expected)
    }

    /// Assert that a picker has a specific selected index
    public func assertPickerIndex(_ viewId: String, expected: Int) -> AwareAssertionResult {
        return assertState(viewId, key: "selectedIndex", equals: String(expected))
    }

    /// Assert iOS navigation tabs are present and visible
    public func assertNavigationTabsPresent() -> AwareAssertionResult {
        let tabIds = ["tabButton-sing", "tabButton-discover", "tabButton-library", "tabButton-you"]
        for tabId in tabIds {
            let result = assertExists(tabId)
            if !result.passed {
                return AwareAssertionResult(passed: false, message: "Navigation tab '\(tabId)' is missing")
            }
        }
        return AwareAssertionResult(passed: true, message: "All navigation tabs are present")
    }
    #endif

    // MARK: - Diff Tracking

    /// Capture current state for later comparison
    public func captureCheckpoint() -> AwareCheckpoint {
        AwareCheckpoint(
            timestamp: Date(),
            viewIds: Set(viewRegistry.keys),
            states: stateRegistry,
            visibleCount: visibleViewCount
        )
    }

    /// Compare current state to a checkpoint
    public func diff(from checkpoint: AwareCheckpoint) -> AwareDiff {
        let currentIds = Set(viewRegistry.keys)
        let addedViews = currentIds.subtracting(checkpoint.viewIds)
        let removedViews = checkpoint.viewIds.subtracting(currentIds)

        var changedStates: [String: (old: String?, new: String?)] = [:]
        let commonViews = currentIds.intersection(checkpoint.viewIds)
        for viewId in commonViews {
            let oldState = checkpoint.states[viewId] ?? [:]
            let newState = stateRegistry[viewId] ?? [:]
            let allKeys = Set(oldState.keys).union(Set(newState.keys))
            for key in allKeys {
                let oldVal = oldState[key]
                let newVal = newState[key]
                if oldVal != newVal {
                    changedStates["\(viewId).\(key)"] = (old: oldVal, new: newVal)
                }
            }
        }

        return AwareDiff(
            addedViews: addedViews,
            removedViews: removedViews,
            changedStates: changedStates,
            viewCountDelta: visibleViewCount - checkpoint.visibleCount
        )
    }
}
