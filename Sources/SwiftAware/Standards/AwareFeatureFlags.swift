// AwareFeatureFlags.swift
// SwiftAware Standards Module
//
// Feature flag infrastructure for gradual rollouts and A/B testing.

import Foundation

// MARK: - Feature Flag Protocol

/// Protocol for feature flag providers.
/// Implement this to provide custom feature flag logic.
public protocol AwareFeatureFlagProvider: Sendable {
    /// Check if a feature is enabled
    func isEnabled(_ flag: String) async -> Bool

    /// Get a feature flag value with a default
    func getValue<T>(_ flag: String, default: T) async -> T where T: Sendable
}

// MARK: - Feature Flag Registry

/// Thread-safe registry for managing feature flags.
/// Supports both boolean flags and typed values.
public actor FeatureFlagRegistry: AwareFeatureFlagProvider {

    /// Shared singleton instance
    public static let shared = FeatureFlagRegistry()

    // MARK: - Storage

    private var boolFlags: [String: Bool]
    private var stringFlags: [String: String] = [:]
    private var intFlags: [String: Int]
    private var doubleFlags: [String: Double]
    private var providers: [any AwareFeatureFlagProvider] = []

    // MARK: - Initialization

    public init() {
        // Initialize with built-in defaults directly
        #if DEBUG
        self.boolFlags = [
            "debug_mode": true,
            "cook_enabled": true,
            "swarm_enabled": true,
            "meta_learner_enabled": true,
            "checkpoint_enabled": true,
            "experimental_parallel_agents": false,
            "experimental_worktrees": false
        ]
        #else
        self.boolFlags = [
            "debug_mode": false,
            "cook_enabled": true,
            "swarm_enabled": true,
            "meta_learner_enabled": true,
            "checkpoint_enabled": true,
            "experimental_parallel_agents": false,
            "experimental_worktrees": false
        ]
        #endif

        self.intFlags = [
            "max_concurrent_agents": 8,
            "max_retries": 3
        ]

        self.doubleFlags = [
            "agent_timeout_seconds": 300.0
        ]
    }

    /// Load from a configuration file (call loadFromFile after init)
    public init(configPath: String) async {
        // Initialize with defaults first
        #if DEBUG
        self.boolFlags = [
            "debug_mode": true,
            "cook_enabled": true,
            "swarm_enabled": true,
            "meta_learner_enabled": true,
            "checkpoint_enabled": true,
            "experimental_parallel_agents": false,
            "experimental_worktrees": false
        ]
        #else
        self.boolFlags = [
            "debug_mode": false,
            "cook_enabled": true,
            "swarm_enabled": true,
            "meta_learner_enabled": true,
            "checkpoint_enabled": true,
            "experimental_parallel_agents": false,
            "experimental_worktrees": false
        ]
        #endif

        self.intFlags = [
            "max_concurrent_agents": 8,
            "max_retries": 3
        ]

        self.doubleFlags = [
            "agent_timeout_seconds": 300.0
        ]

        // Then load from file
        await loadFromFileAsync(configPath)
    }

    /// Async version of loadFromFile for use after init
    public func loadFromFileAsync(_ path: String) {
        guard let data = FileManager.default.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        for (key, value) in json {
            switch value {
            case let bool as Bool:
                boolFlags[key] = bool
            case let string as String:
                stringFlags[key] = string
            case let int as Int:
                intFlags[key] = int
            case let double as Double:
                doubleFlags[key] = double
            default:
                break
            }
        }
    }

    // MARK: - Registration

    /// Register a boolean feature flag
    public func register(_ flag: String, enabled: Bool) {
        boolFlags[flag] = enabled
    }

    /// Register multiple flags at once
    public func register(_ flags: [String: Bool]) {
        for (flag, enabled) in flags {
            boolFlags[flag] = enabled
        }
    }

    /// Register a string flag
    public func register(_ flag: String, value: String) {
        stringFlags[flag] = value
    }

    /// Register an integer flag
    public func register(_ flag: String, value: Int) {
        intFlags[flag] = value
    }

    /// Register a double flag
    public func register(_ flag: String, value: Double) {
        doubleFlags[flag] = value
    }

    /// Add a custom provider (checked after local flags)
    public func addProvider(_ provider: any AwareFeatureFlagProvider) {
        providers.append(provider)
    }

    // MARK: - Querying

    /// Check if a boolean flag is enabled
    public func isEnabled(_ flag: String) async -> Bool {
        // Check local first
        if let value = boolFlags[flag] {
            return value
        }

        // Check providers
        for provider in providers {
            let value = await provider.isEnabled(flag)
            if value {
                return true
            }
        }

        return false
    }

    /// Get a typed value with default
    public func getValue<T>(_ flag: String, default defaultValue: T) async -> T where T: Sendable {
        // Type-specific lookups
        if T.self == Bool.self, let value = boolFlags[flag] as? T {
            return value
        }
        if T.self == String.self, let value = stringFlags[flag] as? T {
            return value
        }
        if T.self == Int.self, let value = intFlags[flag] as? T {
            return value
        }
        if T.self == Double.self, let value = doubleFlags[flag] as? T {
            return value
        }

        // Check providers
        for provider in providers {
            let value = await provider.getValue(flag, default: defaultValue)
            if value as AnyObject !== defaultValue as AnyObject {
                return value
            }
        }

        return defaultValue
    }

    /// Get string value
    public func getString(_ flag: String, default defaultValue: String = "") -> String {
        stringFlags[flag] ?? defaultValue
    }

    /// Get integer value
    public func getInt(_ flag: String, default defaultValue: Int = 0) -> Int {
        intFlags[flag] ?? defaultValue
    }

    /// Get double value
    public func getDouble(_ flag: String, default defaultValue: Double = 0.0) -> Double {
        doubleFlags[flag] ?? defaultValue
    }

    // MARK: - Setting

    /// Set a flag value at runtime
    public func setFlag(_ flag: String, enabled: Bool) {
        boolFlags[flag] = enabled
    }

    /// Toggle a boolean flag
    public func toggle(_ flag: String) {
        boolFlags[flag] = !(boolFlags[flag] ?? false)
    }

    /// Remove a flag
    public func remove(_ flag: String) {
        boolFlags.removeValue(forKey: flag)
        stringFlags.removeValue(forKey: flag)
        intFlags.removeValue(forKey: flag)
        doubleFlags.removeValue(forKey: flag)
    }

    /// Clear all flags
    public func clear() {
        boolFlags.removeAll()
        stringFlags.removeAll()
        intFlags.removeAll()
        doubleFlags.removeAll()
    }

    // MARK: - All Flags

    /// Get all registered flag names
    public func allFlags() -> [String] {
        Array(Set(boolFlags.keys)
            .union(stringFlags.keys)
            .union(intFlags.keys)
            .union(doubleFlags.keys))
            .sorted()
    }

    /// Get all boolean flags
    public func allBoolFlags() -> [String: Bool] {
        boolFlags
    }

    // MARK: - Persistence

    /// Save flags to a JSON file
    public func saveToFile(_ path: String) throws {
        var json: [String: Any] = [:]

        for (key, value) in boolFlags {
            json[key] = value
        }
        for (key, value) in stringFlags {
            json[key] = value
        }
        for (key, value) in intFlags {
            json[key] = value
        }
        for (key, value) in doubleFlags {
            json[key] = value
        }

        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path))
    }

}

// MARK: - Built-in Feature Flags

/// Well-known feature flag names used across SwiftAware apps
public struct AwareFeatureFlag {
    // Debug
    public static let debugMode = "debug_mode"
    public static let verboseLogging = "verbose_logging"

    // Cook features
    public static let cookEnabled = "cook_enabled"
    public static let swarmEnabled = "swarm_enabled"
    public static let metaLearnerEnabled = "meta_learner_enabled"
    public static let checkpointEnabled = "checkpoint_enabled"

    // Experimental
    public static let experimentalParallelAgents = "experimental_parallel_agents"
    public static let experimentalWorktrees = "experimental_worktrees"

    // Pro features
    public static let proUser = "pro_user"
    public static let cloudSync = "cloud_sync"
    public static let prioritySupport = "priority_support"
}

// MARK: - Environment-Based Provider

/// Feature flag provider that reads from environment variables
public actor EnvironmentFeatureFlagProvider: AwareFeatureFlagProvider {

    public init() {}

    public func isEnabled(_ flag: String) async -> Bool {
        let envKey = "AWARE_FLAG_\(flag.uppercased())"
        guard let value = ProcessInfo.processInfo.environment[envKey] else {
            return false
        }
        return value.lowercased() == "true" || value == "1"
    }

    public func getValue<T>(_ flag: String, default defaultValue: T) async -> T where T: Sendable {
        let envKey = "AWARE_FLAG_\(flag.uppercased())"
        guard let stringValue = ProcessInfo.processInfo.environment[envKey] else {
            return defaultValue
        }

        // Try to convert based on type
        if T.self == Bool.self {
            return (stringValue.lowercased() == "true" || stringValue == "1") as! T
        }
        if T.self == String.self {
            return stringValue as! T
        }
        if T.self == Int.self, let intValue = Int(stringValue) {
            return intValue as! T
        }
        if T.self == Double.self, let doubleValue = Double(stringValue) {
            return doubleValue as! T
        }

        return defaultValue
    }
}
