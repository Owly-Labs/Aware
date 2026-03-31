import Foundation

/// Action to take for matching files
public enum LoggingAction: String, Codable, Sendable {
    case include
    case exclude
}

/// A rule for automatic logging based on file path patterns
public struct LoggingRule: Codable, Sendable, Equatable {
    /// Glob-style pattern to match file paths (e.g., "Services/*", "ViewModels/*.swift")
    public let pattern: String

    /// Action to take when pattern matches
    public let action: LoggingAction

    /// Priority for rule evaluation (higher = evaluated first)
    public let priority: Int

    /// Optional description explaining the rule's purpose
    public let description: String?

    public init(
        pattern: String,
        action: LoggingAction,
        priority: Int = 0,
        description: String? = nil
    ) {
        self.pattern = pattern
        self.action = action
        self.priority = priority
        self.description = description
    }
}

/// Configuration for automatic logging based on file paths
public struct AutoLogConfig: Codable, Sendable {
    /// Whether auto-logging is enabled
    public var enabled: Bool

    /// Default rules applied when no custom rule matches
    public var defaultRules: [LoggingRule]

    /// Custom rules that override defaults (checked first)
    public var customRules: [LoggingRule]

    /// Default configuration with sensible defaults
    public static let `default` = AutoLogConfig()

    public init(
        enabled: Bool = true,
        defaultRules: [LoggingRule]? = nil,
        customRules: [LoggingRule] = []
    ) {
        self.enabled = enabled
        self.defaultRules = defaultRules ?? Self.standardDefaultRules
        self.customRules = customRules
    }

    /// Standard default rules for typical Swift projects
    public static let standardDefaultRules: [LoggingRule] = [
        LoggingRule(
            pattern: "Services/*",
            action: .include,
            priority: 100,
            description: "Include all service files for debugging"
        ),
        LoggingRule(
            pattern: "ViewModels/*",
            action: .include,
            priority: 100,
            description: "Include view models for state tracking"
        ),
        LoggingRule(
            pattern: "Utilities/*",
            action: .exclude,
            priority: 50,
            description: "Exclude utility files to reduce noise"
        ),
        LoggingRule(
            pattern: "Models/*",
            action: .exclude,
            priority: 50,
            description: "Exclude model files (data only)"
        )
    ]

    /// Determines whether logging should occur for a given file path
    /// - Parameter file: The file path to check (can be full path or relative)
    /// - Returns: `true` if the file should be logged, `false` otherwise
    public func shouldLog(file: String) -> Bool {
        guard enabled else { return false }

        // Extract the relevant path component for matching
        let pathToMatch = extractPathForMatching(file)

        // Combine rules and sort by priority (highest first)
        let allRules = (customRules + defaultRules).sorted { $0.priority > $1.priority }

        // Find first matching rule
        for rule in allRules {
            if matchesGlobPattern(pathToMatch, pattern: rule.pattern) {
                return rule.action == .include
            }
        }

        // Default: include if no rule matches
        return true
    }

    /// Extracts the path component relevant for pattern matching
    private func extractPathForMatching(_ file: String) -> String {
        // Handle full paths by extracting from known directories
        let components = file.components(separatedBy: "/")

        // Look for common directory markers and return path from there
        let knownDirs = ["Services", "ViewModels", "Utilities", "Models", "Views", "Controllers"]
        for (index, component) in components.enumerated() {
            if knownDirs.contains(component) {
                return components[index...].joined(separator: "/")
            }
        }

        // If no known directory found, use last two components
        if components.count >= 2 {
            return components.suffix(2).joined(separator: "/")
        }

        return file
    }

    /// Matches a path against a glob-style pattern
    /// - Parameters:
    ///   - path: The path to match
    ///   - pattern: Glob pattern (* = wildcard for any characters)
    /// - Returns: `true` if the path matches the pattern
    private func matchesGlobPattern(_ path: String, pattern: String) -> Bool {
        // Convert glob pattern to regex
        var regexPattern = NSRegularExpression.escapedPattern(for: pattern)

        // Replace escaped * with regex wildcard
        regexPattern = regexPattern.replacingOccurrences(of: "\\*", with: ".*")

        // Anchor the pattern
        regexPattern = "^" + regexPattern

        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive])
            let range = NSRange(path.startIndex..<path.endIndex, in: path)
            return regex.firstMatch(in: path, options: [], range: range) != nil
        } catch {
            // If regex fails, fall back to simple prefix matching
            let prefix = pattern.replacingOccurrences(of: "*", with: "")
            return path.hasPrefix(prefix)
        }
    }

    /// Adds a custom rule to the configuration
    /// - Parameter rule: The rule to add
    /// - Returns: A new configuration with the rule added
    public func adding(rule: LoggingRule) -> AutoLogConfig {
        var newConfig = self
        newConfig.customRules.append(rule)
        return newConfig
    }

    /// Removes all custom rules matching a pattern
    /// - Parameter pattern: The pattern to remove
    /// - Returns: A new configuration with matching rules removed
    public func removing(pattern: String) -> AutoLogConfig {
        var newConfig = self
        newConfig.customRules.removeAll { $0.pattern == pattern }
        return newConfig
    }
}
