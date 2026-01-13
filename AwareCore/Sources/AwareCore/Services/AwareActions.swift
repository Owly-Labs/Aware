//
//  AwareActions.swift
//  AwareCore
//
//  Explicit type-safe action methods to replace generic executeAction().
//  Provides LLM-friendly API with specific parameters and result types.
//

import Foundation
import SwiftUI

// MARK: - Explicit Action API

extension Aware {

    // MARK: - Tap & Gesture Actions

    /// Tap a view by ID using direct callback (no mouse movement - ghost UI)
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use for clicking buttons, triggering actions
    ///
    /// - Parameter viewId: View identifier to tap
    /// - Returns: Tap result with success status and duration
    @MainActor
    public func tap(viewId: String) async -> AwareTapResult {
        return await tapDirect(viewId)
    }

    /// Long press a view by ID
    ///
    /// **Token Cost:** ~30 tokens per call
    /// **LLM Guidance:** Use for context menus, drag initiation
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - duration: Hold duration in seconds (default 0.5s)
    /// - Returns: Tap result with action type .longPress
    @MainActor
    public func longPress(viewId: String, duration: TimeInterval = 0.5) async -> AwareTapResult {
        return await longPressDirect(viewId)
    }

    /// Double tap a view by ID
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use for quick actions, zoom gestures
    ///
    /// - Parameter viewId: View identifier
    /// - Returns: Tap result with action type .doubleTap
    @MainActor
    public func doubleTap(viewId: String) async -> AwareTapResult {
        return await self.doubleTap(viewId)
    }

    /// Swipe on a view in specified direction
    ///
    /// **Token Cost:** ~30 tokens per call
    /// **LLM Guidance:** Use for dismissing, navigating, refreshing
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - direction: Swipe direction (up, down, left, right)
    /// - Returns: Swipe result with direction confirmation
    @MainActor
    public func swipe(viewId: String, direction: AwareSwipeDirection) async -> AwareSwipeResult {
        let result = await self.swipe(viewId, direction: direction)
        return AwareSwipeResult(
            success: result.success,
            viewId: viewId,
            direction: direction.rawValue,
            message: result.message
        )
    }

    // MARK: - Text Input Actions

    /// Set text field to specific value (replaces content)
    ///
    /// **Token Cost:** ~30 tokens per call
    /// **LLM Guidance:** Use for filling forms, setting inputs
    ///
    /// - Parameters:
    ///   - viewId: Text field identifier
    ///   - text: New text value
    /// - Returns: Text result with final value confirmation
    @MainActor
    public func setText(viewId: String, text: String) async -> AwareTextResult {
        let internalResult = await setText(viewId, text: text)

        return AwareTextResult(
            success: internalResult.success,
            viewId: viewId,
            actionType: .setText,
            text: text,
            finalValue: getText(viewId),
            message: internalResult.message
        )
    }

    /// Append text to existing content
    ///
    /// **Token Cost:** ~30 tokens per call
    /// **LLM Guidance:** Use for adding to existing text
    ///
    /// - Parameters:
    ///   - viewId: Text field identifier
    ///   - text: Text to append
    /// - Returns: Text result with final value
    @MainActor
    public func appendText(viewId: String, text: String) async -> AwareTextResult {
        let internalResult = await appendText(viewId, text: text)

        return AwareTextResult(
            success: internalResult.success,
            viewId: viewId,
            actionType: .appendText,
            text: text,
            finalValue: getText(viewId),
            message: internalResult.message
        )
    }

    /// Clear all text from field
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use for resetting inputs
    ///
    /// - Parameter viewId: Text field identifier
    /// - Returns: Text result confirming clear
    @MainActor
    public func clearText(viewId: String) async -> AwareTextResult {
        let internalResult = await clearText(viewId)

        return AwareTextResult(
            success: internalResult.success,
            viewId: viewId,
            actionType: .clearText,
            text: nil,
            finalValue: "",
            message: internalResult.message
        )
    }

    /// Type text character-by-character (CGEvent simulation on macOS)
    ///
    /// **Token Cost:** ~35 tokens per call
    /// **LLM Guidance:** Use when setText doesn't work (non-instrumented apps)
    ///
    /// - Parameters:
    ///   - text: Text to type
    ///   - viewId: Optional field identifier for focus context
    /// - Returns: Text result with typed value
    @MainActor
    public func typeText(text: String, in viewId: String? = nil) async -> AwareTextResult {
        // Type the text (uses platform-specific implementation)
        let result = await self.type(text, in: viewId)

        return AwareTextResult(
            success: result.success,
            viewId: viewId ?? "",
            actionType: .type,
            text: text,
            finalValue: viewId != nil ? getText(viewId!) : nil,
            message: result.message
        )
    }

    // MARK: - Focus Management

    /// Focus a specific view
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use to move keyboard focus to input fields
    ///
    /// - Parameter viewId: View identifier to focus
    /// - Returns: Focus result with newly focused view
    @MainActor
    public func focus(viewId: String) async -> AwareFocusResult {
        let internalResult = await focus(viewId)

        return AwareFocusResult(
            success: internalResult.success,
            focusedViewId: internalResult.success ? viewId : nil,
            actionType: .focus,
            message: internalResult.message
        )
    }

    /// Blur current focused view
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use to unfocus/dismiss keyboard
    ///
    /// - Returns: Focus result with previous focus
    @MainActor
    public func blurFocus() async -> AwareFocusResult {
        let internalResult = await blur()

        return AwareFocusResult(
            success: internalResult.success,
            focusedViewId: nil,
            actionType: .blur,
            message: internalResult.message
        )
    }

    /// Focus next view in tab order
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use to navigate forms with Tab key
    ///
    /// - Returns: Focus result with newly focused view
    @MainActor
    public func focusNextField() async -> AwareFocusResult {
        let internalResult = await focusNext()

        return AwareFocusResult(
            success: internalResult.success,
            focusedViewId: AwareFocusManager.shared.focusedViewId,
            actionType: .focusNext,
            message: internalResult.message
        )
    }

    /// Focus previous view in tab order
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use to navigate forms with Shift+Tab
    ///
    /// - Returns: Focus result with newly focused view
    @MainActor
    public func focusPreviousField() async -> AwareFocusResult {
        let internalResult = await focusPrevious()

        return AwareFocusResult(
            success: internalResult.success,
            focusedViewId: AwareFocusManager.shared.focusedViewId,
            actionType: .focusPrevious,
            message: internalResult.message
        )
    }

    // MARK: - Navigation

    /// Navigate back (pop navigation stack)
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use to go back in navigation hierarchy
    ///
    /// - Returns: Navigation result
    @MainActor
    public func navigateBack() async -> AwareNavigationResult {
        let success = await goBack()

        return AwareNavigationResult(
            success: success.success,
            actionType: .goBack,
            message: success.message
        )
    }

    /// Dismiss current modal/sheet
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use to close modals, sheets, popovers
    ///
    /// - Returns: Navigation result
    @MainActor
    public func dismissModal() async -> AwareNavigationResult {
        let success = await dismiss()

        return AwareNavigationResult(
            success: success.success,
            actionType: .dismiss,
            message: success.message
        )
    }

    // MARK: - Query & Snapshot

    /// Find views matching query (by ID substring, label, text)
    ///
    /// **Token Cost:** ~50 tokens per result
    /// **LLM Guidance:** Use to discover available views before interaction
    ///
    /// - Parameters:
    ///   - query: Search query string
    ///   - matchType: How to match (idContains, label, etc.)
    /// - Returns: Find result with matching view IDs
    @MainActor
    public func find(query: String, matchType: FindMatchType = .idContains) async -> AwareFindResult {
        var matches: [String] = []

        switch matchType {
        case .idContains:
            matches = registeredViewIds.filter { $0.contains(query) }
        case .idExact:
            matches = registeredViewIds.filter { $0 == query }
        case .label:
            matches = registeredViewIds.filter { id in
                describeView(id)?.label?.contains(query) == true
            }
        case .tappable:
            matches = listRegisteredActions().sorted()
        case .focused:
            if let focused = AwareFocusManager.shared.focusedViewId {
                matches = [focused]
            }
        default:
            matches = []
        }

        return AwareFindResult(
            success: !matches.isEmpty,
            matches: matches,
            query: query,
            message: matches.isEmpty ? "No matches found for '\(query)'" : "Found \(matches.count) matches"
        )
    }

    /// Capture full UI snapshot
    ///
    /// **Token Cost:** ~100-120 tokens (compact), ~200-300 (text)
    /// **LLM Guidance:** Use to understand current UI state before actions
    ///
    /// - Parameters:
    ///   - format: Output format (default .compact for LLM optimization)
    ///   - includeHidden: Include hidden views (default false)
    /// - Returns: Snapshot result with formatted content
    @MainActor
    public func snapshot(format: AwareSnapshotFormat = .compact, includeHidden: Bool = false) async -> AwareSnapshotResult {
        return captureSnapshot(format: format, includeHidden: includeHidden)
    }

    // MARK: - Assertions

    /// Assert view exists in registry
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use to verify view presence before interaction
    ///
    /// - Parameter viewId: View identifier
    /// - Returns: Assertion result
    @MainActor
    public func assertExists(viewId: String) async -> AwareAssertionResult {
        let exists = registeredViewIds.contains(viewId)
        return AwareAssertionResult(
            passed: exists,
            viewId: viewId,
            key: "exists",
            expected: "true",
            actual: "\(exists)",
            message: exists ? "View '\(viewId)' exists" : "View '\(viewId)' not found"
        )
    }

    /// Assert view is visible
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use to verify view visibility before interaction
    ///
    /// - Parameter viewId: View identifier
    /// - Returns: Assertion result
    @MainActor
    public func assertVisible(viewId: String) async -> AwareAssertionResult {
        guard let viewDescription = describeView(viewId) else {
            return AwareAssertionResult(
                passed: false,
                viewId: viewId,
                key: "visible",
                expected: "true",
                actual: "not found",
                message: "View '\(viewId)' not found"
            )
        }

        return AwareAssertionResult(
            passed: viewDescription.isVisible,
            viewId: viewId,
            key: "visible",
            expected: "true",
            actual: "\(viewDescription.isVisible)",
            message: viewDescription.isVisible ? "View '\(viewId)' is visible" : "View '\(viewId)' is hidden"
        )
    }

    /// Assert view has specific state value
    ///
    /// **Token Cost:** ~30 tokens per call
    /// **LLM Guidance:** Use to verify state before/after actions
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - key: State key to check
    ///   - expected: Expected value
    /// - Returns: Assertion result with actual value
    @MainActor
    public func assertState(viewId: String, key: String, equals expected: String) async -> AwareAssertionResult {
        let actual = getStateValue(viewId, key: key)
        let passed = actual == expected

        return AwareAssertionResult(
            passed: passed,
            viewId: viewId,
            key: key,
            expected: expected,
            actual: actual,
            message: passed
                ? "State '\(key)' equals '\(expected)'"
                : "State '\(key)' is '\(actual ?? "nil")', expected '\(expected)'"
        )
    }

    /// Assert view count matches expected
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use to verify list/collection size
    ///
    /// - Parameter expected: Expected view count
    /// - Returns: Assertion result
    @MainActor
    public func assertViewCount(_ expected: Int) async -> AwareAssertionResult {
        let actual = registeredViewIds.count
        let passed = actual == expected

        return AwareAssertionResult(
            passed: passed,
            viewId: "",
            key: "viewCount",
            expected: "\(expected)",
            actual: "\(actual)",
            message: passed
                ? "View count is \(actual)"
                : "View count is \(actual), expected \(expected)"
        )
    }
}

// MARK: - Supporting Types

public enum FindMatchType: String, Sendable {
    case idContains      // Partial match on viewId
    case idExact         // Exact match on viewId
    case label           // Match on label
    case text            // Match on visual text
    case tappable        // All tappable views
    case focused         // Currently focused view
}
