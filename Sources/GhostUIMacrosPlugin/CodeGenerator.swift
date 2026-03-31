import SwiftSyntax

// MARK: - CodeGenerator

/// Code generation utilities for auto-logging
/// Note: The PeerMacro approach in AutoLogMacro generates body code as strings,
/// so this file provides only utility functions for future expansion.
public enum CodeGenerator {

    /// Generates a timing measurement prefix
    /// Returns: `let _start = CFAbsoluteTimeGetCurrent()`
    public static func generateTimingStart() -> String {
        "let _start = CFAbsoluteTimeGetCurrent()"
    }

    /// Generates a duration calculation
    /// Returns: `let _duration = CFAbsoluteTimeGetCurrent() - _start`
    public static func generateDurationCalc() -> String {
        "let _duration = CFAbsoluteTimeGetCurrent() - _start"
    }

    /// Generates a formatted duration string for logging
    /// Returns: `String(format: "%.3f", _duration)`
    public static func generateFormattedDuration() -> String {
        "String(format: \"%.3f\", _duration)"
    }

    /// Generates an entry log statement
    /// - Parameters:
    ///   - functionName: Name of the function
    ///   - parameters: Function parameters for verbose logging
    ///   - verbosity: Logging verbosity level
    ///   - category: Optional category string
    /// - Returns: The log statement or empty string for minimal verbosity
    public static func generateEntryLog(
        functionName: String,
        parameters: [FunctionParameter],
        verbosity: String,
        category: String?
    ) -> String {
        guard verbosity != "minimal" else { return "" }

        let categoryArg = category.map { ", category: \"\($0)\"" } ?? ""

        if verbosity == "verbose" && !parameters.isEmpty {
            let paramStr = parameters.map { "\\(\($0.name))" }.joined(separator: ", ")
            return "GhostUI.shared.logger.debug(\"[ENTER] \(functionName)(\(paramStr))\"\(categoryArg))"
        } else {
            return "GhostUI.shared.logger.debug(\"[ENTER] \(functionName)\"\(categoryArg))"
        }
    }

    /// Generates an exit log statement
    /// - Parameters:
    ///   - functionName: Name of the function
    ///   - hasReturnValue: Whether the function returns a value
    ///   - verbosity: Logging verbosity level
    ///   - category: Optional category string
    /// - Returns: The log statement or empty string for minimal verbosity
    public static func generateExitLog(
        functionName: String,
        hasReturnValue: Bool,
        verbosity: String,
        category: String?
    ) -> String {
        guard verbosity != "minimal" else { return "" }

        let categoryArg = category.map { ", category: \"\($0)\"" } ?? ""
        let durationStr = "\\(String(format: \\\"%.3f\\\", _duration))"

        if hasReturnValue {
            return "GhostUI.shared.logger.debug(\"[EXIT] \(functionName) -> \\(type(of: _result)) (\(durationStr)s)\"\(categoryArg))"
        } else {
            return "GhostUI.shared.logger.debug(\"[EXIT] \(functionName) (\(durationStr)s)\"\(categoryArg))"
        }
    }

    /// Generates an error log statement
    /// - Parameters:
    ///   - functionName: Name of the function
    ///   - category: Optional category string
    /// - Returns: The error log statement
    public static func generateErrorLog(
        functionName: String,
        category: String?
    ) -> String {
        let categoryArg = category.map { ", category: \"\($0)\"" } ?? ""
        let durationStr = "\\(String(format: \\\"%.3f\\\", _duration))"
        return "GhostUI.shared.logger.error(\"[ERROR] \(functionName): \\(_error) (\(durationStr)s)\"\(categoryArg))"
    }
}
