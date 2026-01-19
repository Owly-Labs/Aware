//
//  AwareInteractionCoordinator.swift
//  Aware
//
//  Coordinates multi-step LLM interactions and command sequences.
//  Provides higher-level operations like form filling and conditional waits.
//

import Foundation

// MARK: - AwareInteractionCoordinator

/// Coordinates multi-step LLM interactions
@MainActor
public final class AwareInteractionCoordinator {
    public static let shared = AwareInteractionCoordinator()

    // MARK: - Configuration

    /// Default delay between commands in a sequence (milliseconds)
    public var commandDelay: UInt64 = 50_000_000 // 50ms

    /// Default timeout for wait operations (seconds)
    public var defaultTimeout: TimeInterval = 5.0

    // MARK: - Initialization

    private init() {}

    // MARK: - Command Execution

    /// Execute a sequence of commands
    /// - Parameters:
    ///   - commands: Array of commands to execute
    ///   - stopOnError: Whether to stop execution on first error (default: true)
    /// - Returns: Array of results for each command
    public func execute(_ commands: [AwareCommand], stopOnError: Bool = true) async -> [AwareResult] {
        var results: [AwareResult] = []

        for command in commands {
            let result = await Aware.shared.executeAction(command)
            results.append(result)

            // Stop on error if configured
            if stopOnError && result.status == "error" {
                break
            }

            // Delay between commands for UI to settle
            if commandDelay > 0 {
                do {
                    try await Task.sleep(nanoseconds: commandDelay)
                } catch is CancellationError {
                    // Command sequence cancelled
                    break
                } catch {
                    // Unexpected error in delay, continue
                }
            }
        }

        return results
    }

    /// Execute a command and wait for a condition to become true
    /// - Parameters:
    ///   - command: The command to execute
    ///   - condition: Closure that returns true when the wait should end
    ///   - timeout: Maximum time to wait (default: 5 seconds)
    ///   - pollInterval: How often to check the condition (default: 100ms)
    /// - Returns: Result of the command execution
    public func executeAndWait(
        _ command: AwareCommand,
        until condition: @escaping @MainActor () -> Bool,
        timeout: TimeInterval? = nil,
        pollInterval: UInt64 = 100_000_000 // 100ms
    ) async -> AwareResult {
        let result = await Aware.shared.executeAction(command)

        // If command failed, return immediately
        guard result.status == "success" else {
            return result
        }

        let effectiveTimeout = timeout ?? defaultTimeout
        let deadline = Date().addingTimeInterval(effectiveTimeout)

        // Wait for condition
        while Date() < deadline {
            if condition() {
                return result
            }

            do {
                try await Task.sleep(nanoseconds: pollInterval)
            } catch is CancellationError {
                // Wait cancelled
                return .error("Wait cancelled for condition after '\(command.action)'")
            } catch {
                // Unexpected error in delay, continue polling
            }
        }

        return .error("Timeout waiting for condition after '\(command.action)' (waited \(effectiveTimeout)s)")
    }

    /// Wait for a view to appear
    /// - Parameters:
    ///   - viewId: The view ID to wait for
    ///   - timeout: Maximum time to wait
    /// - Returns: Success if view appeared, error if timeout
    public func waitForView(_ viewId: String, timeout: TimeInterval? = nil) async -> AwareResult {
        let effectiveTimeout = timeout ?? defaultTimeout
        let deadline = Date().addingTimeInterval(effectiveTimeout)

        while Date() < deadline {
            let result = Aware.shared.assertVisible(viewId)
            if result.passed {
                return .success("View '\(viewId)' appeared")
            }

            do {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            } catch is CancellationError {
                // Wait cancelled
                return .error("Wait cancelled for view '\(viewId)'")
            } catch {
                // Unexpected error in delay, continue polling
            }
        }

        return .error("Timeout waiting for view '\(viewId)' to appear")
    }

    /// Wait for a state value to match
    /// - Parameters:
    ///   - viewId: The view ID
    ///   - key: The state key
    ///   - expectedValue: The expected value
    ///   - timeout: Maximum time to wait
    /// - Returns: Success if state matched, error if timeout
    public func waitForState(
        _ viewId: String,
        key: String,
        equals expectedValue: String,
        timeout: TimeInterval? = nil
    ) async -> AwareResult {
        let effectiveTimeout = timeout ?? defaultTimeout
        let deadline = Date().addingTimeInterval(effectiveTimeout)

        while Date() < deadline {
            let result = Aware.shared.assertState(viewId, key: key, equals: expectedValue)
            if result.passed {
                return .success("State '\(key)' matched '\(expectedValue)'")
            }

            do {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            } catch is CancellationError {
                // Wait cancelled
                let actual = Aware.shared.getStateValue(viewId, key: key) ?? "nil"
                return .error("Wait cancelled for state '\(key)' (current: '\(actual)')")
            } catch {
                // Unexpected error in delay, continue polling
            }
        }

        let actual = Aware.shared.getStateValue(viewId, key: key) ?? "nil"
        return .error("Timeout waiting for state '\(key)' to equal '\(expectedValue)' (got '\(actual)')")
    }

    // MARK: - Form Operations

    /// Fill multiple form fields
    /// - Parameter fields: Dictionary of viewId -> text value
    /// - Returns: Success if all fields were filled, error otherwise
    public func fillForm(_ fields: [String: String]) async -> AwareResult {
        for (viewId, text) in fields.sorted(by: { $0.key < $1.key }) {
            // Try to focus the field first
            _ = await Aware.shared.focus(viewId)

            // Set the text
            let textResult = await Aware.shared.setText(viewId, text: text)
            if !textResult.success {
                return .error("Failed to fill field '\(viewId)': \(textResult.message)")
            }

            // Small delay between fields
            do {
                try await Task.sleep(nanoseconds: commandDelay)
            } catch is CancellationError {
                // Form filling cancelled
                return .error("Form filling cancelled at field '\(viewId)'")
            } catch {
                // Unexpected error in delay, continue
            }
        }

        return .success("Filled \(fields.count) form fields")
    }

    /// Fill form and submit
    /// - Parameters:
    ///   - fields: Dictionary of viewId -> text value
    ///   - submitButtonId: ID of the submit button
    /// - Returns: Result of the submission
    public func fillAndSubmit(fields: [String: String], submitButtonId: String) async -> AwareResult {
        // Fill the form
        let fillResult = await fillForm(fields)
        guard fillResult.status == "success" else {
            return fillResult
        }

        // Blur any focused field
        _ = await Aware.shared.blur()

        do {
            try await Task.sleep(nanoseconds: commandDelay)
        } catch is CancellationError {
            // Form submission cancelled after blur
            return .error("Form submission cancelled")
        } catch {
            // Unexpected error in delay, continue
        }

        // Tap submit
        let submitCommand = AwareCommand(action: "tap", viewId: submitButtonId)
        return await Aware.shared.executeAction(submitCommand)
    }

    // MARK: - Navigation Operations

    /// Navigate through a sequence of taps
    /// - Parameter viewIds: Array of view IDs to tap in sequence
    /// - Returns: Results for each tap
    public func tapSequence(_ viewIds: [String]) async -> [AwareResult] {
        let commands = viewIds.map { AwareCommand(action: "tap", viewId: $0) }
        return await execute(commands)
    }

    /// Navigate back multiple times
    /// - Parameter count: Number of times to go back
    /// - Returns: Success if all back navigations succeeded
    public func goBack(times count: Int) async -> AwareResult {
        for i in 0 ..< count {
            let result = await Aware.shared.goBack()
            if !result.success {
                return .error("Failed to go back on attempt \(i + 1): \(result.message)")
            }

            // Longer delay for navigation to settle
            do {
                try await Task.sleep(nanoseconds: commandDelay * 2)
            } catch is CancellationError {
                // Navigation cancelled
                return .error("Navigation cancelled after \(i + 1) back operations")
            } catch {
                // Unexpected error in delay, continue
            }
        }
        return .success("Navigated back \(count) times")
    }

    // MARK: - Scroll Operations

    /// Scroll to find a view
    /// - Parameters:
    ///   - scrollViewId: ID of the scrollable container
    ///   - targetViewId: ID of the view to find
    ///   - maxScrolls: Maximum number of scroll attempts
    /// - Returns: Success if view was found, error otherwise
    public func scrollToFind(
        in scrollViewId: String,
        target targetViewId: String,
        maxScrolls: Int = 10
    ) async -> AwareResult {
        for i in 0 ..< maxScrolls {
            // Check if target is visible
            let visible = Aware.shared.assertVisible(targetViewId)
            if visible.passed {
                return .success("Found '\(targetViewId)' after \(i) scrolls")
            }

            // Scroll down
            let scrollResult = await Aware.shared.swipe(scrollViewId, direction: .up)
            if !scrollResult.success {
                return .error("Could not scroll: \(scrollResult.message)")
            }

            // Wait for scroll to complete
            do {
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms
            } catch is CancellationError {
                // Scroll search cancelled
                return .error("Scroll search cancelled at scroll \(i + 1)")
            } catch {
                // Unexpected error in delay, continue
            }
        }

        return .error("Could not find '\(targetViewId)' after \(maxScrolls) scrolls")
    }
}
