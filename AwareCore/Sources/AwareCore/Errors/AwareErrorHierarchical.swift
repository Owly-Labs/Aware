//
//  AwareErrorHierarchical.swift
//  AwareCore
//
//  Hierarchical error enum structure for better LLM error routing.
//  Organizes errors by category with nested types for improved context.
//

import Foundation

// MARK: - Hierarchical Error Structure

/// Hierarchical error type for the Aware framework
///
/// **Token Cost:** ~30-50 tokens per error (vs 40-60 for flat structure)
/// **LLM Guidance:** Use category to route error handling logic
///
/// **Benefits:**
/// - Category-based routing: LLMs can handle error families together
/// - Better context: Nested errors include category information
/// - Clearer semantics: .registration(.viewAlreadyExists) vs .viewAlreadyExists
/// - Token efficiency: Category prefixes reduce redundancy
public enum AwareErrorV3: LocalizedError, Sendable {

    // MARK: - Error Categories

    case registration(RegistrationError)
    case state(StateError)
    case action(ActionError)
    case input(InputError)
    case query(QueryError)
    case snapshot(SnapshotError)
    case animation(AnimationError)
    case backend(BackendError)
    case configuration(ConfigurationError)
    case system(SystemError)

    // MARK: - Registration Errors

    public enum RegistrationError: Sendable, Equatable {
        case viewRegistrationFailed(reason: String, viewId: String)
        case invalidViewId(String)
        case viewAlreadyExists(viewId: String, existingLabel: String?, newLabel: String?)
        case parentViewNotFound(parentId: String, childId: String)
        case circularDependency(viewId: String, parentId: String)
        case registryFull(maxViews: Int, currentViews: Int)

        var localizedDescription: String {
            switch self {
            case .viewRegistrationFailed(let reason, let viewId):
                return "Failed to register view '\(viewId)': \(reason)"
            case .invalidViewId(let viewId):
                return "Invalid view identifier: '\(viewId)'"
            case .viewAlreadyExists(let viewId, let existing, let new):
                return "View '\(viewId)' already exists. Existing: '\(existing ?? "none")', new: '\(new ?? "none")'"
            case .parentViewNotFound(let parentId, let childId):
                return "Parent view '\(parentId)' not found for child '\(childId)'"
            case .circularDependency(let viewId, let parentId):
                return "Circular dependency detected: view '\(viewId)' cannot be parent of '\(parentId)'"
            case .registryFull(let max, let current):
                return "Registry full: \(current) views registered (max: \(max))"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .invalidViewId:
                return "Use a non-empty string without special characters"
            case .viewAlreadyExists:
                return "Use a different view ID or update the existing view"
            case .parentViewNotFound:
                return "Ensure the parent view is registered before adding children"
            case .circularDependency:
                return "Check parent-child relationships to avoid cycles"
            case .registryFull:
                return "Unregister unused views or increase registry size"
            default:
                return nil
            }
        }
    }

    // MARK: - State Errors

    public enum StateError: Sendable, Equatable {
        case registrationFailed(reason: String, viewId: String, key: String)
        case typeMismatch(viewId: String, key: String, expectedType: String, actualType: String)
        case notFound(viewId: String, key: String)
        case invalidKey(viewId: String, key: String, reason: String)
        case encodingFailed(viewId: String, key: String, valueType: String)
        case decodingFailed(viewId: String, key: String, expectedType: String)

        var localizedDescription: String {
            switch self {
            case .registrationFailed(let reason, let viewId, let key):
                return "Failed to register state for '\(viewId)'.\(key): \(reason)"
            case .typeMismatch(let viewId, let key, let expected, let actual):
                return "State type mismatch for '\(viewId)'.\(key): expected \(expected), got \(actual)"
            case .notFound(let viewId, let key):
                return "State not found: '\(viewId)'.\(key)"
            case .invalidKey(let viewId, let key, let reason):
                return "Invalid state key '\(key)' for view '\(viewId)': \(reason)"
            case .encodingFailed(let viewId, let key, let valueType):
                return "Failed to encode \(valueType) value for '\(viewId)'.\(key)"
            case .decodingFailed(let viewId, let key, let expectedType):
                return "Failed to decode '\(viewId)'.\(key)' as \(expectedType)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .notFound:
                return "Register the state value before querying it"
            case .typeMismatch:
                return "Use the correct type accessor method (getStateBool, getStateInt, etc.)"
            case .invalidKey:
                return "Use a valid state key (non-empty, no special characters)"
            case .encodingFailed, .decodingFailed:
                return "Ensure the value is Codable and matches the expected type"
            default:
                return nil
            }
        }
    }

    // MARK: - Action Errors

    public enum ActionError: Sendable, Equatable {
        case registrationFailed(reason: String, viewId: String)
        case executionFailed(reason: String, viewId: String, actionType: String)
        case notFound(viewId: String)
        case directActionUnavailable(viewId: String, reason: String)
        case invalidActionType(actionType: String, viewId: String)
        case callbackFailed(viewId: String, error: String)
        case concurrencyViolation(viewId: String, currentAction: String)

        var localizedDescription: String {
            switch self {
            case .registrationFailed(let reason, let viewId):
                return "Failed to register action for '\(viewId)': \(reason)"
            case .executionFailed(let reason, let viewId, let actionType):
                return "Failed to execute \(actionType) action on '\(viewId)': \(reason)"
            case .notFound(let viewId):
                return "No action registered for view '\(viewId)'"
            case .directActionUnavailable(let viewId, let reason):
                return "Direct action unavailable for '\(viewId)': \(reason)"
            case .invalidActionType(let actionType, let viewId):
                return "Invalid action type '\(actionType)' for view '\(viewId)'"
            case .callbackFailed(let viewId, let error):
                return "Action callback failed for '\(viewId)': \(error)"
            case .concurrencyViolation(let viewId, let currentAction):
                return "Concurrency violation on '\(viewId)': action '\(currentAction)' already running"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .notFound:
                return "Register an action callback for the view using .awareButton() or registerAction()"
            case .directActionUnavailable:
                return "Use tap(at:) with coordinates instead of tap(viewId:)"
            case .invalidActionType:
                return "Use one of the predefined action methods: tap(), longPress(), doubleTap(), swipe()"
            case .concurrencyViolation:
                return "Wait for the current action to complete before executing another"
            default:
                return nil
            }
        }
    }

    // MARK: - Input Errors

    public enum InputError: Sendable, Equatable {
        case textInputFailed(reason: String, viewId: String)
        case textBindingNotFound(viewId: String)
        case gestureNotSupported(gesture: String, viewId: String, platform: String)
        case gestureExecutionFailed(reason: String, viewId: String, gesture: String)
        case focusNotAvailable(viewId: String, reason: String)
        case keyboardEventFailed(reason: String, key: String)

        var localizedDescription: String {
            switch self {
            case .textInputFailed(let reason, let viewId):
                return "Text input failed for '\(viewId)': \(reason)"
            case .textBindingNotFound(let viewId):
                return "Text binding not found for '\(viewId)'"
            case .gestureNotSupported(let gesture, let viewId, let platform):
                return "Gesture '\(gesture)' not supported for '\(viewId)' on \(platform)"
            case .gestureExecutionFailed(let reason, let viewId, let gesture):
                return "Failed to execute gesture '\(gesture)' on '\(viewId)': \(reason)"
            case .focusNotAvailable(let viewId, let reason):
                return "Focus not available for '\(viewId)': \(reason)"
            case .keyboardEventFailed(let reason, let key):
                return "Keyboard event failed for key '\(key)': \(reason)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .textBindingNotFound:
                return "Ensure the text field uses .awareTextField() with text binding"
            case .gestureNotSupported:
                return "Check platform support for the requested gesture type"
            case .focusNotAvailable:
                return "Register focus binding using .awareFocus() or verify view is focusable"
            default:
                return nil
            }
        }
    }

    // MARK: - Query Errors

    public enum QueryError: Sendable, Equatable {
        case executionFailed(reason: String, query: String)
        case noViewsFound(query: String, matchType: String)
        case invalidPredicate(predicate: String, reason: String)
        case tooManyResults(count: Int, maxResults: Int, query: String)
        case ambiguousMatch(viewIds: [String], query: String)

        var localizedDescription: String {
            switch self {
            case .executionFailed(let reason, let query):
                return "Query execution failed for '\(query)': \(reason)"
            case .noViewsFound(let query, let matchType):
                return "No views found matching '\(query)' (\(matchType) search)"
            case .invalidPredicate(let predicate, let reason):
                return "Invalid query predicate '\(predicate)': \(reason)"
            case .tooManyResults(let count, let max, let query):
                return "Too many results for '\(query)': \(count) views (max: \(max))"
            case .ambiguousMatch(let viewIds, let query):
                return "Ambiguous match for '\(query)': multiple views found (\(viewIds.joined(separator: ", ")))"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .noViewsFound:
                return "Use find() with different matchType, or verify views are registered"
            case .invalidPredicate:
                return "Check predicate syntax and use supported query operators"
            case .tooManyResults:
                return "Use more specific query or increase maxResults limit"
            case .ambiguousMatch:
                return "Use more specific view ID or .idExact match type"
            default:
                return nil
            }
        }
    }

    // MARK: - Snapshot Errors

    public enum SnapshotError: Sendable, Equatable {
        case generationFailed(reason: String, format: String)
        case invalidFormat(format: String, supportedFormats: [String])
        case tooLarge(actualSize: Int, maxSize: Int, format: String)
        case serializationFailed(reason: String, format: String)
        case emptySnapshot(reason: String)

        var localizedDescription: String {
            switch self {
            case .generationFailed(let reason, let format):
                return "Failed to generate \(format) snapshot: \(reason)"
            case .invalidFormat(let format, let supported):
                return "Invalid snapshot format '\(format)'. Supported: \(supported.joined(separator: ", "))"
            case .tooLarge(let actual, let max, let format):
                return "Snapshot too large: \(actual) bytes (max: \(max)) for format '\(format)'"
            case .serializationFailed(let reason, let format):
                return "Failed to serialize \(format) snapshot: \(reason)"
            case .emptySnapshot(let reason):
                return "Empty snapshot generated: \(reason)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .invalidFormat(_, let supported):
                return "Use one of: \(supported.joined(separator: ", "))"
            case .tooLarge:
                return "Use .compact format, reduce maxDepth, or increase size limit"
            case .emptySnapshot:
                return "Register views before capturing snapshot"
            default:
                return nil
            }
        }
    }

    // MARK: - Animation Errors

    public enum AnimationError: Sendable, Equatable {
        case registrationFailed(reason: String, viewId: String)
        case notSupported(type: String, viewId: String, platform: String)
        case conflictingAnimations(viewId: String, existing: String, new: String)

        var localizedDescription: String {
            switch self {
            case .registrationFailed(let reason, let viewId):
                return "Failed to register animation for '\(viewId)': \(reason)"
            case .notSupported(let type, let viewId, let platform):
                return "Animation type '\(type)' not supported for '\(viewId)' on \(platform)"
            case .conflictingAnimations(let viewId, let existing, let new):
                return "Conflicting animations on '\(viewId)': '\(existing)' already running, cannot start '\(new)'"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .notSupported:
                return "Check platform support for the animation type"
            case .conflictingAnimations:
                return "Wait for the current animation to complete or cancel it first"
            default:
                return nil
            }
        }
    }

    // MARK: - Backend Errors

    public enum BackendError: Sendable, Equatable {
        case communicationFailed(reason: String, endpoint: String?)
        case invalidResponse(reason: String, endpoint: String?, statusCode: Int?)
        case timeout(endpoint: String, duration: TimeInterval)
        case unauthorized(endpoint: String, reason: String)
        case networkUnavailable(reason: String)

        var localizedDescription: String {
            switch self {
            case .communicationFailed(let reason, let endpoint):
                return "Backend communication failed\(endpoint.map { " at '\($0)'" } ?? ""): \(reason)"
            case .invalidResponse(let reason, let endpoint, let statusCode):
                let code = statusCode.map { " (HTTP \($0))" } ?? ""
                return "Invalid response\(endpoint.map { " from '\($0)'" } ?? "")\(code): \(reason)"
            case .timeout(let endpoint, let duration):
                return "Request to '\(endpoint)' timed out after \(duration)s"
            case .unauthorized(let endpoint, let reason):
                return "Unauthorized access to '\(endpoint)': \(reason)"
            case .networkUnavailable(let reason):
                return "Network unavailable: \(reason)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .communicationFailed, .timeout:
                return "Check network connection and retry"
            case .invalidResponse:
                return "Verify API endpoint and response format"
            case .unauthorized:
                return "Check authentication credentials"
            case .networkUnavailable:
                return "Enable network access and retry"
            }
        }
    }

    // MARK: - Configuration Errors

    public enum ConfigurationError: Sendable, Equatable {
        case invalidConfiguration(reason: String, key: String?)
        case featureNotAvailable(feature: String, platform: String, minimumVersion: String?)
        case gitIntegrationError(reason: String, gitCommand: String?)
        case incompatibleSettings(setting1: String, setting2: String, reason: String)

        var localizedDescription: String {
            switch self {
            case .invalidConfiguration(let reason, let key):
                return "Invalid configuration\(key.map { " for '\($0)'" } ?? ""): \(reason)"
            case .featureNotAvailable(let feature, let platform, let minVersion):
                let version = minVersion.map { " (requires \($0)+)" } ?? ""
                return "Feature '\(feature)' not available on \(platform)\(version)"
            case .gitIntegrationError(let reason, let gitCommand):
                return "Git integration error\(gitCommand.map { " ('\($0)')" } ?? ""): \(reason)"
            case .incompatibleSettings(let setting1, let setting2, let reason):
                return "Incompatible settings: '\(setting1)' and '\(setting2)' cannot be used together: \(reason)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .featureNotAvailable:
                return "Use an alternative approach or upgrade platform version"
            case .gitIntegrationError:
                return "Check git installation and repository status"
            case .incompatibleSettings:
                return "Choose only one of the conflicting settings"
            default:
                return nil
            }
        }
    }

    // MARK: - System Errors

    public enum SystemError: Sendable, Equatable {
        case internalError(reason: String, file: String?, line: Int?)
        case resourceExhausted(resource: String, available: Int, requested: Int)
        case timeout(operation: String, timeout: TimeInterval, elapsed: TimeInterval)
        case concurrencyViolation(reason: String, actor: String)
        case memoryPressure(allocatedMB: Int, availableMB: Int)

        var localizedDescription: String {
            switch self {
            case .internalError(let reason, let file, let line):
                let location = file.map { " at \($0)\(line.map { ":\($0)" } ?? "")" } ?? ""
                return "Internal framework error\(location): \(reason)"
            case .resourceExhausted(let resource, let available, let requested):
                return "\(resource) exhausted: requested \(requested), available \(available)"
            case .timeout(let operation, let timeout, let elapsed):
                return "Operation '\(operation)' timed out after \(elapsed)s (limit: \(timeout)s)"
            case .concurrencyViolation(let reason, let actor):
                return "Concurrency violation on \(actor): \(reason)"
            case .memoryPressure(let allocated, let available):
                return "Memory pressure: \(allocated)MB allocated, only \(available)MB available"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .resourceExhausted:
                return "Free up resources or reduce concurrent operations"
            case .timeout:
                return "Increase timeout or check system performance"
            case .memoryPressure:
                return "Release unused views or reduce snapshot cache size"
            case .internalError:
                return "File a bug report with reproduction steps"
            default:
                return nil
            }
        }
    }

    // MARK: - LocalizedError Implementation

    public var errorDescription: String? {
        switch self {
        case .registration(let error): return error.localizedDescription
        case .state(let error): return error.localizedDescription
        case .action(let error): return error.localizedDescription
        case .input(let error): return error.localizedDescription
        case .query(let error): return error.localizedDescription
        case .snapshot(let error): return error.localizedDescription
        case .animation(let error): return error.localizedDescription
        case .backend(let error): return error.localizedDescription
        case .configuration(let error): return error.localizedDescription
        case .system(let error): return error.localizedDescription
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .registration(let error): return error.recoverySuggestion
        case .state(let error): return error.recoverySuggestion
        case .action(let error): return error.recoverySuggestion
        case .input(let error): return error.recoverySuggestion
        case .query(let error): return error.recoverySuggestion
        case .snapshot(let error): return error.recoverySuggestion
        case .animation(let error): return error.recoverySuggestion
        case .backend(let error): return error.recoverySuggestion
        case .configuration(let error): return error.recoverySuggestion
        case .system(let error): return error.recoverySuggestion
        }
    }
}

// MARK: - Error Category

extension AwareErrorV3 {
    /// Get the error category for routing
    ///
    /// **Token Cost:** ~5 tokens
    /// **LLM Guidance:** Use for error routing and handling logic
    public var category: ErrorCategory {
        switch self {
        case .registration: return .registration
        case .state: return .state
        case .action: return .action
        case .input: return .input
        case .query: return .query
        case .snapshot: return .snapshot
        case .animation: return .animation
        case .backend: return .backend
        case .configuration: return .configuration
        case .system: return .system
        }
    }

    /// Error category for routing and handling
    public enum ErrorCategory: String, Sendable {
        case registration
        case state
        case action
        case input
        case query
        case snapshot
        case animation
        case backend
        case configuration
        case system

        /// Emoji icon for visual identification
        public var emoji: String {
            switch self {
            case .registration: return "📝"
            case .state: return "💾"
            case .action: return "🎯"
            case .input: return "⌨️"
            case .query: return "🔍"
            case .snapshot: return "📸"
            case .animation: return "🎬"
            case .backend: return "🌐"
            case .configuration: return "⚙️"
            case .system: return "⚠️"
            }
        }
    }
}

// MARK: - Error Severity

extension AwareErrorV3 {
    /// Error severity level for logging and handling
    ///
    /// **Token Cost:** ~5 tokens
    /// **LLM Guidance:** Use to prioritize error handling
    public var severity: ErrorSeverity {
        switch self {
        case .registration(let error):
            switch error {
            case .viewRegistrationFailed, .registryFull, .circularDependency: return .error
            default: return .warning
            }
        case .state(let error):
            switch error {
            case .registrationFailed, .encodingFailed: return .error
            default: return .warning
            }
        case .action(let error):
            switch error {
            case .executionFailed, .callbackFailed, .concurrencyViolation: return .error
            default: return .warning
            }
        case .input(let error):
            switch error {
            case .gestureExecutionFailed, .textInputFailed: return .error
            default: return .warning
            }
        case .query(let error):
            switch error {
            case .executionFailed: return .error
            case .noViewsFound: return .info
            default: return .warning
            }
        case .snapshot(let error):
            switch error {
            case .generationFailed, .serializationFailed: return .error
            case .emptySnapshot: return .info
            default: return .warning
            }
        case .animation(let error):
            switch error {
            case .conflictingAnimations: return .error
            default: return .warning
            }
        case .backend(let error):
            switch error {
            case .communicationFailed, .networkUnavailable: return .error
            case .timeout: return .warning
            default: return .info
            }
        case .configuration(let error):
            switch error {
            case .invalidConfiguration, .incompatibleSettings: return .error
            default: return .warning
            }
        case .system(let error):
            return .error
        }
    }

    /// Whether this error is recoverable
    public var isRecoverable: Bool {
        switch self {
        case .registration(let error):
            switch error {
            case .invalidViewId, .circularDependency: return false
            default: return true
            }
        case .state(let error):
            switch error {
            case .invalidKey: return false
            default: return true
            }
        case .action(let error):
            switch error {
            case .invalidActionType: return false
            default: return true
            }
        case .backend(let error):
            switch error {
            case .unauthorized: return false
            default: return true
            }
        case .configuration(let error):
            switch error {
            case .invalidConfiguration, .featureNotAvailable: return false
            default: return true
            }
        case .system(let error):
            switch error {
            case .internalError: return false
            default: return true
            }
        default:
            return true
        }
    }
}

// MARK: - Logging Utilities

extension AwareErrorV3 {
    /// Logs the error with appropriate severity
    ///
    /// **Token Cost:** ~20 tokens per log
    /// **LLM Guidance:** Use for debugging and monitoring
    public func log(with logger: (String, ErrorSeverity) -> Void = { print("[\($1.rawValue.uppercased())] \($0)") }) {
        logger("\(category.emoji) \(errorDescription ?? "Unknown error")", severity)
        if let suggestion = recoverySuggestion {
            logger("💡 Suggestion: \(suggestion)", .info)
        }
    }

    /// Creates a compact error message for LLM consumption
    ///
    /// **Token Cost:** ~15-20 tokens
    /// **LLM Guidance:** Use in error results for token efficiency
    public var compactMessage: String {
        let categoryPrefix = category.emoji
        let description = errorDescription ?? "Unknown error"
        let truncated = description.count > 100 ? "\(description.prefix(100))..." : description
        return "\(categoryPrefix) \(truncated)"
    }
}
