import Foundation

/// GhostUI configuration
public struct AwareConfig: Codable, Sendable {
    public var version: String = "1.0"
    public var project: ProjectConfig
    public var logging: LoggingConfig
    public var testing: TestingConfig
    public var presets: [String: TestingConfig]?

    public init(
        version: String = "1.0",
        project: ProjectConfig = ProjectConfig(),
        logging: LoggingConfig = LoggingConfig(),
        testing: TestingConfig = TestingConfig(),
        presets: [String: TestingConfig]? = nil
    ) {
        self.version = version
        self.project = project
        self.logging = logging
        self.testing = testing
        self.presets = presets
    }
}

/// Project configuration
public struct ProjectConfig: Codable, Sendable {
    public var name: String
    public var platform: String
    public var version: String?
    public var buildNumber: String?

    public init(
        name: String = "Unknown",
        platform: String = "swift",
        version: String? = nil,
        buildNumber: String? = nil
    ) {
        self.name = name
        self.platform = platform
        self.version = version
        self.buildNumber = buildNumber
    }
}

/// Logging configuration
public struct LoggingConfig: Codable, Sendable {
    public var level: LogLevel
    public var format: LogFormat
    public var output: String?
    public var includeTimestamps: Bool
    public var includeEmoji: Bool

    public init(
        level: LogLevel = .info,
        format: LogFormat = .pretty,
        output: String? = nil,
        includeTimestamps: Bool = true,
        includeEmoji: Bool = true
    ) {
        self.level = level
        self.format = format
        self.output = output
        self.includeTimestamps = includeTimestamps
        self.includeEmoji = includeEmoji
    }
}

public enum LogFormat: String, Codable, Sendable {
    case json
    case pretty
}

/// Testing configuration
public struct TestingConfig: Codable, Sendable {
    public var tiers: [TestTier]
    public var runOnLaunch: Bool
    public var runOnBuildChange: Bool
    public var stopOnFirstFailure: Bool
    public var parallel: Bool
    public var retries: Int
    public var retryDelay: Double
    public var useExponentialBackoff: Bool
    public var timeout: TierTimeout

    public init(
        tiers: [TestTier] = [.smoke, .structure],
        runOnLaunch: Bool = true,
        runOnBuildChange: Bool = true,
        stopOnFirstFailure: Bool = true,
        parallel: Bool = false,
        retries: Int = 2,
        retryDelay: Double = 0.5,
        useExponentialBackoff: Bool = true,
        timeout: TierTimeout = TierTimeout()
    ) {
        self.tiers = tiers
        self.runOnLaunch = runOnLaunch
        self.runOnBuildChange = runOnBuildChange
        self.stopOnFirstFailure = stopOnFirstFailure
        self.parallel = parallel
        self.retries = retries
        self.retryDelay = retryDelay
        self.useExponentialBackoff = useExponentialBackoff
        self.timeout = timeout
    }
}

public struct TierTimeout: Codable, Sendable {
    public var smoke: Double
    public var structure: Double
    public var integration: Double

    public init(smoke: Double = 3, structure: Double = 30, integration: Double = 120) {
        self.smoke = smoke
        self.structure = structure
        self.integration = integration
    }

    public func timeout(for tier: TestTier) -> Double {
        switch tier {
        case .smoke: return smoke
        case .structure: return structure
        case .integration: return integration
        }
    }
}
