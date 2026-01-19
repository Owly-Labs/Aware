//
//  AwareLogger+Extensions.swift
//  Breathe
//
//  Convenience methods for common logging patterns.
//  Provides simple APIs with automatic file/line capture.
//

import Foundation

// MARK: - Convenience Logging Methods

extension AwareCentralLogger {
    /// Log debug message
    public func debug(
        _ message: String,
        component: String,
        tags: [String] = [],
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        await log(
            level: .debug,
            component: component,
            message: message,
            file: file,
            line: line,
            function: function,
            tags: tags
        )
    }

    /// Log info message
    public func info(
        _ message: String,
        component: String,
        tags: [String] = [],
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        await log(
            level: .info,
            component: component,
            message: message,
            file: file,
            line: line,
            function: function,
            tags: tags
        )
    }

    /// Log warning message
    public func warning(
        _ message: String,
        component: String,
        tags: [String] = [],
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        await log(
            level: .warning,
            component: component,
            message: message,
            file: file,
            line: line,
            function: function,
            tags: tags
        )
    }

    /// Log error message
    public func error(
        _ message: String,
        error: Error? = nil,
        component: String,
        tags: [String] = [],
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        await log(
            level: .error,
            component: component,
            message: message,
            error: error,
            file: file,
            line: line,
            function: function,
            tags: tags
        )
    }

    /// Log critical message
    public func critical(
        _ message: String,
        error: Error? = nil,
        component: String,
        tags: [String] = [],
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        await log(
            level: .critical,
            component: component,
            message: message,
            error: error,
            file: file,
            line: line,
            function: function,
            tags: tags
        )
    }
}

// MARK: - Structured Logging for Common Patterns

extension AwareCentralLogger {
    /// Log UI action execution with duration
    @discardableResult
    public func logAction(
        _ action: String,
        elementId: String,
        success: Bool,
        duration: TimeInterval,
        error: Error? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async -> String {
        let durationMs = String(format: "%.2f", duration * 1000)
        let message = "\(action) on '\(elementId)': \(success ? "success" : "failed") (\(durationMs)ms)"

        return await log(
            level: success ? .info : .error,
            component: "AwareActionExecutor",
            message: message,
            error: error,
            file: file,
            line: line,
            function: function,
            tags: ["action", action.lowercased(), elementId]
        )
    }

    /// Log state change
    public func logStateChange(
        elementId: String,
        key: String,
        oldValue: String?,
        newValue: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        let message = "State changed: '\(elementId).\(key)' = \(oldValue ?? "nil") → \(newValue)"

        await log(
            level: .debug,
            component: "AwareStateTracker",
            message: message,
            file: file,
            line: line,
            function: function,
            tags: ["state", elementId, key]
        )
    }

    /// Log performance measurement
    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        threshold: TimeInterval,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        let exceeded = duration > threshold
        let durationMs = String(format: "%.2f", duration * 1000)
        let thresholdMs = String(format: "%.2f", threshold * 1000)
        let message = "\(operation): \(durationMs)ms (threshold: \(thresholdMs)ms)"

        await log(
            level: exceeded ? .warning : .info,
            component: "AwarePerformanceMonitor",
            message: message,
            file: file,
            line: line,
            function: function,
            tags: ["performance", operation]
        )
    }

    /// Log focus change
    public func logFocus(
        elementId: String?,
        action: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        let message: String
        if let elementId = elementId {
            message = "Focus \(action): '\(elementId)'"
        } else {
            message = "Focus \(action): none"
        }

        await log(
            level: .debug,
            component: "AwareFocusManager",
            message: message,
            file: file,
            line: line,
            function: function,
            tags: ["focus", action]
        )
    }

    /// Log accessibility violation
    public func logAccessibilityViolation(
        elementId: String,
        violation: String,
        severity: String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        let message = "Accessibility violation (\(severity)): '\(elementId)' - \(violation)"

        let level: AwareLogLevel = {
            switch severity.uppercased() {
            case "CRITICAL": return .critical
            case "ERROR": return .error
            case "WARNING": return .warning
            default: return .info
            }
        }()

        await log(
            level: level,
            component: "AwareAccessibilityAuditor",
            message: message,
            file: file,
            line: line,
            function: function,
            tags: ["accessibility", "violation", severity.lowercased()]
        )
    }

    /// Log coverage event
    public func logCoverage(
        elementId: String,
        action: String,
        isNewElement: Bool,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        let message = "Coverage: '\(elementId)' - \(action) (new: \(isNewElement))"

        await log(
            level: .debug,
            component: "AwareCoverageTracker",
            message: message,
            file: file,
            line: line,
            function: function,
            tags: ["coverage", action, isNewElement ? "new" : "existing"]
        )
    }

    /// Log visual comparison result
    public func logVisualComparison(
        name: String,
        matched: Bool,
        differences: Int?,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        let message: String
        if matched {
            message = "Visual comparison '\(name)': matched"
        } else if let differences = differences {
            message = "Visual comparison '\(name)': failed (\(differences) differences)"
        } else {
            message = "Visual comparison '\(name)': failed"
        }

        await log(
            level: matched ? .info : .warning,
            component: "AwareVisualTester",
            message: message,
            file: file,
            line: line,
            function: function,
            tags: ["visual", "comparison", matched ? "passed" : "failed"]
        )
    }

    /// Log navigation event
    public func logNavigation(
        action: String,
        destination: String?,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        let message: String
        if let destination = destination {
            message = "Navigation \(action): \(destination)"
        } else {
            message = "Navigation \(action)"
        }

        await log(
            level: .debug,
            component: "AwareNavigationManager",
            message: message,
            file: file,
            line: line,
            function: function,
            tags: ["navigation", action]
        )
    }
}
