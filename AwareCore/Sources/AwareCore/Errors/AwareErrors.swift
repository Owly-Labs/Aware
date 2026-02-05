//  AwareErrors.swift
//  Aware
//
//  Comprehensive error types and handling for the Aware framework.
//  Provides structured error reporting and recovery mechanisms.
//

import Foundation

/// Comprehensive error types for the Aware framework
public enum AwareError: LocalizedError, Sendable {
    // MARK: - Registration Errors

    /// View registration failed
    case viewRegistrationFailed(reason: String, viewId: String)

    /// Invalid view identifier
    case invalidViewId(String)

    /// View already exists with different properties
    case viewAlreadyExists(viewId: String, existingLabel: String?, newLabel: String?)

    /// Parent view not found
    case parentViewNotFound(parentId: String, childId: String)

    // MARK: - State Management Errors

    /// State registration failed
    case stateRegistrationFailed(reason: String, viewId: String, key: String)

    /// State value type mismatch
    case stateTypeMismatch(viewId: String, key: String, expectedType: String, actualType: String)

    /// State not found
    case stateNotFound(viewId: String, key: String)

    // MARK: - Action Errors

    /// Action registration failed
    case actionRegistrationFailed(reason: String, viewId: String)

    /// Action execution failed
    case actionExecutionFailed(reason: String, viewId: String, actionType: String)

    /// Action not found for view
    case actionNotFound(viewId: String)

    /// Direct action not available
    case directActionUnavailable(viewId: String, reason: String)

    // MARK: - Text/Gesture Input Errors

    /// Text input failed
    case textInputFailed(reason: String, viewId: String)

    /// Text binding not found
    case textBindingNotFound(viewId: String)

    /// Gesture not supported
    case gestureNotSupported(gesture: String, viewId: String)

    /// Gesture execution failed
    case gestureExecutionFailed(reason: String, viewId: String, gesture: String)

    // MARK: - Query and Search Errors

    /// Query execution failed
    case queryExecutionFailed(reason: String)

    /// No views match the query criteria
    case noViewsFoundForQuery(String)

    /// Invalid query predicate
    case invalidQueryPredicate(String)

    // MARK: - Snapshot Errors

    /// Snapshot generation failed
    case snapshotGenerationFailed(reason: String, format: String)

    /// Invalid snapshot format
    case invalidSnapshotFormat(String)

    /// Snapshot too large
    case snapshotTooLarge(actualSize: Int, maxSize: Int)

    // MARK: - Animation Errors

    /// Animation registration failed
    case animationRegistrationFailed(reason: String, viewId: String)

    /// Animation not supported
    case animationNotSupported(type: String, viewId: String)

    // MARK: - Network/Backend Errors

    /// Backend communication failed
    case backendCommunicationFailed(reason: String, endpoint: String?)

    /// Invalid response from backend
    case invalidBackendResponse(String)

    // MARK: - Configuration Errors

    /// Invalid configuration
    case invalidConfiguration(reason: String, key: String?)

    /// Feature not available on this platform
    case featureNotAvailable(feature: String, platform: String)

    /// Git integration error
    case gitIntegrationError(reason: String)

    // MARK: - System Errors

    /// Internal framework error
    case internalError(String)

    /// Resource exhaustion
    case resourceExhausted(resource: String, available: Int, requested: Int)

    /// Timeout exceeded
    case timeoutExceeded(operation: String, timeout: TimeInterval)

    // MARK: - Error Properties

    public var errorDescription: String? {
        switch self {
        case .viewRegistrationFailed(let reason, let viewId):
            return "Failed to register view '\(viewId)': \(reason)"
        case .invalidViewId(let viewId):
            return "Invalid view identifier: '\(viewId)'"
        case .viewAlreadyExists(let viewId, let existing, let new):
            return "View '\(viewId)' already exists. Existing label: '\(existing ?? "none")', new label: '\(new ?? "none")'"
        case .parentViewNotFound(let parentId, let childId):
            return "Parent view '\(parentId)' not found for child '\(childId)'"
        case .stateRegistrationFailed(let reason, let viewId, let key):
            return "Failed to register state for view '\(viewId)', key '\(key)': \(reason)"
        case .stateTypeMismatch(let viewId, let key, let expected, let actual):
            return "State type mismatch for view '\(viewId)', key '\(key)': expected \(expected), got \(actual)"
        case .stateNotFound(let viewId, let key):
            return "State not found for view '\(viewId)', key '\(key)'"
        case .actionRegistrationFailed(let reason, let viewId):
            return "Failed to register action for view '\(viewId)': \(reason)"
        case .actionExecutionFailed(let reason, let viewId, let actionType):
            return "Failed to execute \(actionType) action on view '\(viewId)': \(reason)"
        case .actionNotFound(let viewId):
            return "No action registered for view '\(viewId)'"
        case .directActionUnavailable(let viewId, let reason):
            return "Direct action unavailable for view '\(viewId)': \(reason)"
        case .textInputFailed(let reason, let viewId):
            return "Text input failed for view '\(viewId)': \(reason)"
        case .textBindingNotFound(let viewId):
            return "Text binding not found for view '\(viewId)'"
        case .gestureNotSupported(let gesture, let viewId):
            return "Gesture '\(gesture)' not supported for view '\(viewId)'"
        case .gestureExecutionFailed(let reason, let viewId, let gesture):
            return "Failed to execute gesture '\(gesture)' on view '\(viewId)': \(reason)"
        case .queryExecutionFailed(let reason):
            return "Query execution failed: \(reason)"
        case .noViewsFoundForQuery(let query):
            return "No views found matching query: \(query)"
        case .invalidQueryPredicate(let predicate):
            return "Invalid query predicate: \(predicate)"
        case .snapshotGenerationFailed(let reason, let format):
            return "Failed to generate \(format) snapshot: \(reason)"
        case .invalidSnapshotFormat(let format):
            return "Invalid snapshot format: '\(format)'"
        case .snapshotTooLarge(let actual, let max):
            return "Snapshot too large: \(actual) bytes (max: \(max))"
        case .animationRegistrationFailed(let reason, let viewId):
            return "Failed to register animation for view '\(viewId)': \(reason)"
        case .animationNotSupported(let type, let viewId):
            return "Animation type '\(type)' not supported for view '\(viewId)'"
        case .backendCommunicationFailed(let reason, let endpoint):
            return "Backend communication failed\(endpoint.map { " at '\($0)'" } ?? ""): \(reason)"
        case .invalidBackendResponse(let reason):
            return "Invalid response from backend: \(reason)"
        case .invalidConfiguration(let reason, let key):
            return "Invalid configuration\(key.map { " for '\($0)'" } ?? ""): \(reason)"
        case .featureNotAvailable(let feature, let platform):
            return "Feature '\(feature)' not available on \(platform)"
        case .gitIntegrationError(let reason):
            return "Git integration error: \(reason)"
        case .internalError(let reason):
            return "Internal framework error: \(reason)"
        case .resourceExhausted(let resource, let available, let requested):
            return "\(resource) exhausted: requested \(requested), available \(available)"
        case .timeoutExceeded(let operation, let timeout):
            return "Operation '\(operation)' timed out after \(timeout) seconds"
        }
    }
}

// MARK: - Operation Result Extensions

/// Convenience extensions for operation results
public extension AwareOperationResult {
    /// Throws the error if present, returns success value otherwise
    func unwrap() throws -> AwareSuccess {
        switch self {
        case .success(let success):
            return success
        case .failure(let error):
            throw error
        }
    }

    /// Gets the error if present, nil otherwise
    var error: AwareError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    /// True if the operation succeeded
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

// MARK: - Error Severity and Recovery

public extension AwareError {
    /// Error severity level for logging and handling
    var severity: ErrorSeverity {
        switch self {
        case .viewRegistrationFailed, .stateRegistrationFailed, .actionRegistrationFailed,
             .animationRegistrationFailed, .snapshotGenerationFailed, .backendCommunicationFailed,
             .invalidBackendResponse, .internalError, .resourceExhausted, .timeoutExceeded:
            return .error
        case .invalidViewId, .viewAlreadyExists, .parentViewNotFound, .stateTypeMismatch,
             .stateNotFound, .actionNotFound, .directActionUnavailable, .textBindingNotFound,
             .gestureNotSupported, .invalidQueryPredicate, .invalidSnapshotFormat,
             .animationNotSupported, .invalidConfiguration, .featureNotAvailable:
            return .warning
        case .actionExecutionFailed, .textInputFailed, .gestureExecutionFailed,
             .queryExecutionFailed, .noViewsFoundForQuery, .snapshotTooLarge, .gitIntegrationError:
            return .info
        }
    }

    /// Whether this error is recoverable
    var recoverySuggestion: String? {
        switch self {
        case .invalidViewId:
            return "Use a non-empty string without special characters"
        case .viewAlreadyExists:
            return "Use a different view ID or update the existing view"
        case .parentViewNotFound:
            return "Ensure the parent view is registered before adding children"
        case .stateNotFound:
            return "Register the state value before querying it"
        case .actionNotFound:
            return "Register an action callback for the view"
        case .textBindingNotFound:
            return "Ensure the text field has a binding registered"
        case .gestureNotSupported:
            return "Check platform support for the requested gesture"
        case .snapshotTooLarge:
            return "Use a smaller UI or compact format, or increase max size limit"
        case .timeoutExceeded:
            return "Increase timeout or check system performance"
        case .resourceExhausted:
            return "Free up resources or reduce concurrent operations"
        default:
            return "Check the error details and try again, or file a bug report"
        }
    }



}

/// Error severity levels for logging and handling
public enum ErrorSeverity: String, Sendable {
    case info
    case warning
    case error
}

/// Success marker for operations
public enum AwareSuccess: Sendable {
    case ok
}

/// Result type for operations that may succeed or fail with AwareError
public typealias AwareOperationResult = Result<AwareSuccess, AwareError>

// MARK: - Error Handling Utilities

public extension AwareError {
    /// Creates a user-friendly error message with context
    func contextualizedMessage(operation: String) -> String {
        return "Operation '\(operation)' failed: \(errorDescription ?? "Unknown error")"
    }

    /// Logs the error with appropriate severity
    func log(with logger: (String, ErrorSeverity) -> Void = { print("[\($1.rawValue.uppercased())] \($0)") }) {
        // Check suppression flag (set by AwareLogging.configureLogs())
        let shouldSuppress = UserDefaults.standard.bool(forKey: "aware_suppress_state_warnings")

        // Always log errors, suppress only warnings/info
        guard !shouldSuppress || severity == .error else {
            return // Suppress warning/info logs when flag is set
        }

        logger(errorDescription ?? "Unknown error", severity)
        if let suggestion = recoverySuggestion {
            logger("Suggestion: \(suggestion)", .info)
        }
    }

    /// Whether this error is recoverable
    var isRecoverable: Bool {
        switch self {
        case .timeoutExceeded, .resourceExhausted, .backendCommunicationFailed:
            return true // Can retry
        case .snapshotTooLarge, .featureNotAvailable:
            return true // Can use alternative approach
        case .invalidViewId, .invalidQueryPredicate, .invalidSnapshotFormat,
             .invalidConfiguration, .internalError:
            return false // Requires code changes
        default:
            return true // Most errors can be recovered from
        }
    }
}