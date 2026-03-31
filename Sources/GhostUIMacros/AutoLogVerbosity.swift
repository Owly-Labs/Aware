import Foundation

/// Verbosity level for the `@AutoLog` and `@AutoLogAll` macros.
///
/// Controls how much information is logged when a function is called.
///
/// - `minimal`: Only log errors that occur during execution.
/// - `standard`: Log function entry, exit, and any errors.
/// - `verbose`: Log entry with all parameters, exit with return value, execution duration, and errors.
public enum AutoLogVerbosity: String, Sendable {
    /// Only log errors that occur during function execution.
    case minimal

    /// Log function entry, exit, and any errors.
    /// This is the default verbosity level.
    case standard

    /// Log entry with all parameters, exit with return value, execution duration, and errors.
    /// Use this level for detailed debugging.
    case verbose
}
