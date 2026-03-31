import Foundation

/// Automatically adds logging to a function's entry, exit, and error paths.
///
/// This macro injects logging code at the beginning and end of the function body,
/// as well as around any throwing expressions.
///
/// - Parameters:
///   - verbosity: The level of detail to log. Defaults to `.standard`.
///   - category: An optional category string for organizing logs. Defaults to the type name.
///
/// ## Example Usage
///
/// ```swift
/// @AutoLog(verbosity: .verbose, category: "Network")
/// func fetchUser(id: Int) async throws -> User {
///     // Function implementation
/// }
/// ```
///
/// With `.verbose` verbosity, this will log:
/// - Entry: "fetchUser(id: 42) entered"
/// - Exit: "fetchUser returned User(...) in 0.123s"
/// - Error (if thrown): "fetchUser threw NetworkError.timeout"
@attached(body)
public macro AutoLog(
    verbosity: AutoLogVerbosity = .standard,
    category: String? = nil
) = #externalMacro(module: "GhostUIMacrosPlugin", type: "AutoLogMacro")

/// Automatically adds logging to all methods in a type.
///
/// Apply this macro to a class, struct, or actor to add `@AutoLog` to all of its methods.
/// This is useful for comprehensive logging across an entire type without annotating each method.
///
/// - Parameters:
///   - verbosity: The level of detail to log for all methods. Defaults to `.standard`.
///   - category: An optional category string for organizing logs. Defaults to the type name.
///
/// ## Example Usage
///
/// ```swift
/// @AutoLogAll(verbosity: .standard, category: "UserService")
/// class UserService {
///     func fetchUser(id: Int) async throws -> User { ... }
///     func updateUser(_ user: User) async throws { ... }
///     func deleteUser(id: Int) async throws { ... }
/// }
/// ```
///
/// All methods in `UserService` will automatically have logging injected.
@attached(memberAttribute)
public macro AutoLogAll(
    verbosity: AutoLogVerbosity = .standard,
    category: String? = nil
) = #externalMacro(module: "GhostUIMacrosPlugin", type: "AutoLogAllMacro")

/// Marker macro to exclude a function from `@AutoLogAll`.
///
/// Apply this macro to individual functions within a type that has `@AutoLogAll`
/// to prevent automatic logging for that specific function.
///
/// ## Example Usage
///
/// ```swift
/// @AutoLogAll
/// class UserService {
///     func fetchUser(id: Int) async throws -> User { ... }  // Will be logged
///
///     @NoLog
///     func internalHelper() { ... }  // Will NOT be logged
/// }
/// ```
@attached(peer)
public macro NoLog() = #externalMacro(module: "GhostUIMacrosPlugin", type: "NoLogMacro")
