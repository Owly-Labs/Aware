//
//  AwareActions.swift
//  Aware
//
//  Action execution methods for Aware framework.
//  Extracted from AwareService.swift (Phase 3 Architecture Refactoring)
//

import Foundation
import SwiftUI
import os.log

// MARK: - Action Execution Extension

extension Aware {

    // MARK: - Action Execution

    public func executeAction(_ command: AwareCommand) async -> AwareResult {
        logger.info("Aware: Executing action: \(command.action) on viewId: \(command.viewId ?? "nil")")

        switch command.action {
        case "tap":
            guard let viewId = command.viewId else {
                return .error("tap requires viewId")
            }
            guard let callback = actionCallbacks[viewId] else {
                return .error("No action registered for '\(viewId)'. Available: \(Array(actionCallbacks.keys).prefix(10))")
            }

            // Ensure callback executes on MainActor for SwiftUI state updates
            await Task { @MainActor in
                await callback()
            }.value

            // Brief delay to allow SwiftUI to process state changes
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

            return .success("Tapped '\(viewId)'")

        case "type":
            guard let viewId = command.viewId else {
                return .error("type requires viewId")
            }
            guard let text = command.value else {
                return .error("type requires value (text to input)")
            }
            NotificationCenter.default.post(
                name: Notification.Name("AwareTextInput"),
                object: nil,
                userInfo: ["viewId": viewId, "text": text]
            )
            return .success("Typed '\(text)' into '\(viewId)'")

        case "assert":
            guard let viewId = command.viewId else {
                return .error("assert requires viewId")
            }
            guard let key = command.key else {
                return .error("assert requires key (state key to check)")
            }
            guard let actual = getStateValue(viewId, key: key) else {
                return .error("No state '\(key)' found for view '\(viewId)'")
            }
            if let expected = command.value {
                if actual == expected {
                    return AwareResult(status: "success", message: "Assert passed: \(key)=\(actual)", actual: actual)
                } else {
                    return AwareResult(status: "error", message: "Assert failed: expected '\(expected)' but got '\(actual)'", actual: actual)
                }
            }
            return AwareResult(status: "success", message: "State found", actual: actual)

        case "snapshot":
            let snapshot = captureSnapshot(format: .compact)
            return AwareResult(
                status: "success",
                message: "Captured \(snapshot.viewCount) views",
                viewCount: snapshot.viewCount,
                snapshot: snapshot
            )

        case "find":
            guard let viewId = command.viewId else {
                return .error("find requires viewId (partial match)")
            }
            let matches = viewRegistry.keys.filter { $0.contains(viewId) }
            return AwareResult(
                status: "success",
                message: "Found \(matches.count) matches: \(matches.prefix(10).joined(separator: ", "))",
                viewCount: matches.count
            )

        // iOS Gesture Commands
        case "longPress":
            guard let viewId = command.viewId else {
                return .error("longPress requires viewId")
            }
            let result = await longPressDirect(viewId)
            return result.success ? .success(result.message) : .error(result.message)

        case "doubleTap":
            guard let viewId = command.viewId else {
                return .error("doubleTap requires viewId")
            }
            let result = await doubleTap(viewId)
            return result.success ? .success(result.message) : .error(result.message)

        case "swipe":
            guard let viewId = command.viewId else {
                return .error("swipe requires viewId")
            }
            guard let directionStr = command.value,
                  let direction = AwareSwipeDirection(rawValue: directionStr) else {
                return .error("swipe requires value (direction: up/down/left/right)")
            }
            let result = await swipe(viewId, direction: direction)
            return result.success ? .success(result.message) : .error(result.message)

        // Text Commands
        case "setText":
            guard let viewId = command.viewId else {
                return .error("setText requires viewId")
            }
            guard let text = command.value else {
                return .error("setText requires value (text to set)")
            }
            let result = await setText(viewId, text: text)
            return result.success ? .success(result.message) : .error(result.message)

        case "appendText":
            guard let viewId = command.viewId else {
                return .error("appendText requires viewId")
            }
            guard let text = command.value else {
                return .error("appendText requires value (text to append)")
            }
            let result = await appendText(viewId, text: text)
            return result.success ? .success(result.message) : .error(result.message)

        case "clearText":
            guard let viewId = command.viewId else {
                return .error("clearText requires viewId")
            }
            let result = await clearText(viewId)
            return result.success ? .success(result.message) : .error(result.message)

        // Focus Commands
        case "focus":
            guard let viewId = command.viewId else {
                return .error("focus requires viewId")
            }
            let result = await focus(viewId)
            return result.success ? .success(result.message) : .error(result.message)

        case "blur":
            let result = await blur()
            return result.success ? .success(result.message) : .error(result.message)

        case "focusNext":
            let result = await focusNext()
            return result.success ? .success(result.message) : .error(result.message)

        case "focusPrevious":
            let result = await focusPrevious()
            return result.success ? .success(result.message) : .error(result.message)

        // Navigation Commands
        case "back":
            let result = await goBack()
            return result.success ? .success(result.message) : .error(result.message)

        case "dismiss":
            let result = await dismiss()
            return result.success ? .success(result.message) : .error(result.message)

        default:
            return .error("Unknown action: \(command.action). Supported: tap, longPress, doubleTap, swipe, type, setText, appendText, clearText, focus, blur, focusNext, focusPrevious, back, dismiss, assert, snapshot, find")
        }
    }

    // MARK: - iOS Gesture Execution

    public func gesture(_ viewId: String, type: AwareGestureType, parameters: AwareGestureParameters? = nil) async -> AwareTapResult {
        guard let registration = viewRegistry[viewId] else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' not found")
        }
        let snapshot = registration.snapshot

        guard snapshot.isVisible else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' is not visible")
        }

        // Try parameterized callback first
        if let callback = parameterizedGestureCallbacks[viewId]?[type] {
            await callback(parameters ?? AwareGestureParameters())
            return AwareTapResult(
                success: true,
                viewId: viewId,
                message: "\(type.rawValue) gesture executed on '\(viewId)'"
            )
        }

        // Try simple callback
        if let callback = gestureCallbacks[viewId]?[type] {
            await callback()
            return AwareTapResult(
                success: true,
                viewId: viewId,
                message: "\(type.rawValue) gesture executed on '\(viewId)'"
            )
        }

        return AwareTapResult(
            success: false,
            viewId: viewId,
            message: "No \(type.rawValue) gesture registered for '\(viewId)'"
        )
    }

    /// Swipe on a view (iOS)
    @discardableResult
    public func swipe(_ viewId: String, direction: AwareSwipeDirection) async -> AwareTapResult {
        let gestureType: AwareGestureType
        switch direction {
        case .up: gestureType = .swipeUp
        case .down: gestureType = .swipeDown
        case .left: gestureType = .swipeLeft
        case .right: gestureType = .swipeRight
        }

        return await gesture(viewId, type: gestureType, parameters: AwareGestureParameters(direction: direction))
    }

    /// Long press on a view using callback (iOS)
    @discardableResult
    public func longPressDirect(_ viewId: String) async -> AwareTapResult {
        return await gesture(viewId, type: .longPress)
    }

    /// Double tap on a view (iOS)
    @discardableResult
    public func doubleTap(_ viewId: String) async -> AwareTapResult {
        return await gesture(viewId, type: .doubleTap)
    }

    /// Pinch gesture on a view (iOS)
    @discardableResult
    public func pinch(_ viewId: String, scale: CGFloat) async -> AwareTapResult {
        let type: AwareGestureType = scale > 1.0 ? .pinchOut : .pinchIn
        return await gesture(viewId, type: type, parameters: AwareGestureParameters(scale: scale))
    }


    // MARK: - Text Manipulation

    public func setText(_ viewId: String, text: String) async -> AwareTapResult {
        guard let binding = textBindings[viewId] else {
            // Fallback to notification
            NotificationCenter.default.post(
                name: Notification.Name("AwareTextInput"),
                object: nil,
                userInfo: ["viewId": viewId, "text": text]
            )
            return AwareTapResult(
                success: true,
                viewId: viewId,
                message: "Posted text notification for '\(viewId)' (no binding registered)"
            )
        }

        binding.setValue(text)
        return AwareTapResult(success: true, viewId: viewId, message: "Set text to '\(text)' in '\(viewId)'")
    }

    /// Append text to a field
    @discardableResult
    public func appendText(_ viewId: String, text: String) async -> AwareTapResult {
        guard let binding = textBindings[viewId] else {
            return AwareTapResult(success: false, viewId: viewId, message: "No text binding for '\(viewId)'")
        }

        binding.append(text)
        return AwareTapResult(success: true, viewId: viewId, message: "Appended '\(text)' to '\(viewId)'")
    }

    /// Clear text in a field
    @discardableResult
    public func clearText(_ viewId: String) async -> AwareTapResult {
        guard let binding = textBindings[viewId] else {
            return AwareTapResult(success: false, viewId: viewId, message: "No text binding for '\(viewId)'")
        }

        binding.clear()
        return AwareTapResult(success: true, viewId: viewId, message: "Cleared text in '\(viewId)'")
    }

    /// Get current text value from binding
    public func getText(_ viewId: String) -> String? {
        textBindings[viewId]?.value
    }


    // MARK: - Focus Control

    public func focus(_ viewId: String) async -> AwareTapResult {
        let success = AwareFocusManager.shared.focus(viewId)
        return AwareTapResult(
            success: success,
            viewId: viewId,
            message: success ? "Focused '\(viewId)'" : "Could not focus '\(viewId)'"
        )
    }

    /// Blur (unfocus) the current view
    @discardableResult
    public func blur() async -> AwareTapResult {
        let previousFocus = AwareFocusManager.shared.focusedViewId
        AwareFocusManager.shared.blur()
        return AwareTapResult(
            success: true,
            viewId: previousFocus ?? "",
            message: "Blurred focus"
        )
    }

    /// Focus next field in tab order
    @discardableResult
    public func focusNext() async -> AwareTapResult {
        let success = AwareFocusManager.shared.focusNext()
        return AwareTapResult(
            success: success,
            viewId: AwareFocusManager.shared.focusedViewId ?? "",
            message: success ? "Focused next field" : "No next field to focus"
        )
    }

    /// Focus previous field in tab order
    @discardableResult
    public func focusPrevious() async -> AwareTapResult {
        let success = AwareFocusManager.shared.focusPrevious()
        return AwareTapResult(
            success: success,
            viewId: AwareFocusManager.shared.focusedViewId ?? "",
            message: success ? "Focused previous field" : "No previous field to focus"
        )
    }


    // MARK: - Navigation

    public func goBack() async -> AwareTapResult {
        let success = await AwareNavigationManager.shared.goBack()
        return AwareTapResult(
            success: success,
            viewId: AwareNavigationManager.shared.currentContext ?? "",
            message: success ? "Navigated back" : "Could not navigate back"
        )
    }

    /// Dismiss current modal (delegates to AwareNavigationManager)
    @discardableResult
    public func dismiss() async -> AwareTapResult {
        let success = await AwareNavigationManager.shared.dismiss()
        return AwareTapResult(
            success: success,
            viewId: AwareNavigationManager.shared.currentContext ?? "",
            message: success ? "Dismissed modal" : "Could not dismiss"
        )
    }


    // MARK: - Tap Actions

    public func tapDirect(_ viewId: String) async -> AwareTapResult {
        guard let registration = viewRegistry[viewId] else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' not found")
        }
        let snapshot = registration.snapshot

        guard snapshot.isVisible else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' is not visible")
        }

        // Check if direct action callback exists
        guard let callback = actionCallbacks[viewId] else {
            // Fallback: Post notification for views listening to tap events
            NotificationCenter.default.post(
                name: Notification.Name("Aware.DirectTap"),
                object: nil,
                userInfo: ["viewId": viewId]
            )

            // Brief delay for UI to settle after notification
            do {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            } catch is CancellationError {
                // Action cancelled, return early
                return AwareTapResult(success: false, viewId: viewId, message: "Tap cancelled")
            } catch {
                // Unexpected error in delay, continue anyway
            }

            return AwareTapResult(
                success: true,
                viewId: viewId,
                message: "Posted direct tap notification for '\(viewId)' (no callback registered)",
                actionDescription: snapshot.action?.actionDescription
            )
        }

        // Invoke the callback directly on MainActor
        await Task { @MainActor in
            await callback()
        }.value

        // Brief delay for UI to settle after callback and allow SwiftUI to process state changes
        do {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        } catch is CancellationError {
            // Action cancelled, but callback already invoked
        } catch {
            // Unexpected error in delay, continue anyway
        }

        NotificationCenter.default.post(
            name: Notification.Name("Aware.DirectTap"),
            object: nil,
            userInfo: ["viewId": viewId, "invoked": true]
        )

        return AwareTapResult(
            success: true,
            viewId: viewId,
            message: "Direct action invoked for '\(viewId)' (no mouse movement)",
            actionDescription: snapshot.action?.actionDescription
        )
    }

    /// Tap by view ID - uses CGEvent simulation on macOS
    @discardableResult
    public func tap(_ viewId: String) async -> AwareTapResult {
        guard let registration = viewRegistry[viewId] else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' not found")
        }
        let snapshot = registration.snapshot

        guard snapshot.isVisible else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' is not visible")
        }

        guard let frame = snapshot.frame else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' has no frame")
        }

        let center = CGPoint(x: frame.midX, y: frame.midY)
        return await tap(at: center, viewId: viewId)
    }

    /// Tap at coordinates - uses CGEvent simulation on macOS
    @discardableResult
    public func tap(at point: CGPoint, viewId: String? = nil) async -> AwareTapResult {
        #if os(macOS)
        let success = await AwareMouseInput.click(at: point)
        let resolvedViewId = viewId ?? findViewAt(point)?.id ?? "unknown"
        return AwareTapResult(
            success: success,
            viewId: resolvedViewId,
            message: success ? "Tapped at (\(Int(point.x)), \(Int(point.y)))" : "Tap failed"
        )
        #else
        return AwareTapResult(success: false, viewId: viewId ?? "unknown", message: "CGEvent tap not available on iOS")
        #endif
    }

    /// Long press by view ID
    @discardableResult
    public func longPress(_ viewId: String, duration: TimeInterval = 0.5) async -> AwareTapResult {
        guard let registration = viewRegistry[viewId] else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' not found")
        }
        let snapshot = registration.snapshot

        guard let frame = snapshot.frame else {
            return AwareTapResult(success: false, viewId: viewId, message: "View '\(viewId)' has no frame")
        }

        let center = CGPoint(x: frame.midX, y: frame.midY)
        #if os(macOS)
        let success = await AwareMouseInput.longPress(at: center, duration: duration)
        return AwareTapResult(
            success: success,
            viewId: viewId,
            message: success ? "Long pressed '\(viewId)' for \(duration)s" : "Long press failed"
        )
        #else
        return AwareTapResult(success: false, viewId: viewId, message: "CGEvent long press not available on iOS")
        #endif
    }

    /// Type text - optionally in a specific view
    @discardableResult
    public func type(_ text: String, in viewId: String? = nil) async -> AwareTapResult {
        #if os(macOS)
        if let viewId = viewId {
            // First tap the view to focus it
            let tapResult = await tap(viewId)
            if !tapResult.success {
                return AwareTapResult(success: false, viewId: viewId, message: "Failed to focus view '\(viewId)' before typing")
            }

            // Delay for focus to settle before typing
            do {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            } catch is CancellationError {
                // Typing cancelled, return early
                return AwareTapResult(success: false, viewId: viewId, message: "Typing cancelled before text entry")
            } catch {
                // Unexpected error in delay, continue anyway
            }
        }
        await AwareTextInput.type(text)
        return AwareTapResult(success: true, viewId: viewId ?? "keyboard", message: "Typed \(text.count) characters")
        #else
        return AwareTapResult(success: false, viewId: viewId ?? "keyboard", message: "CGEvent typing not available on iOS")
        #endif
    }

    /// Find view at a specific point
    private func findViewAt(_ point: CGPoint) -> AwareViewSnapshot? {
        viewRegistry.values.first { snapshot in
            guard let frame = snapshot.frame else { return false }
            return frame.contains(point)
        }
    }

}
