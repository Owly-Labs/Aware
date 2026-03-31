import Foundation
import os.log

/// Aware - Ghost UI toolkit for LLM-assisted Swift and iOS development
///
/// Provides invisible view tracking, state observation, and action dispatch
/// that LLMs can query and control without touching the visible UI.
///
/// Usage:
/// ```swift
/// import GhostUI
///
/// // Ghost UI tracking
/// Text("Hello").ghostID("greeting")
///
/// // Structured logging
/// Aware.logger.info("App launched", metadata: ["version": "1.0"])
///
/// // Run tests on launch
/// #if DEBUG
/// await Aware.runOnLaunchIfNeeded()
/// #endif
/// ```
public final class Aware: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = Aware()

    // MARK: - Properties

    private var config: AwareConfig
    private var testRunner: TestRunner
    private var lastTestedBuild: String?

    private static let buildKey = "GhostUI.lastTestedBuild"

    // MARK: - Static Accessors

    /// Shared logger instance
    public static var logger: Logger {
        shared.loggerInstance
    }

    private lazy var loggerInstance: Logger = {
        Logger(config: config.logging)
    }()

    // MARK: - Initialization

    private init() {
        self.config = ConfigLoader.load()
        self.testRunner = TestRunner(config: config)
        self.lastTestedBuild = UserDefaults.standard.string(forKey: Self.buildKey)
    }

    /// Initialize with a specific config file path
    public static func initialize(configPath: String? = nil) {
        if let path = configPath {
            shared.config = ConfigLoader.load(from: path)
        } else {
            shared.config = ConfigLoader.load()
        }
        shared.testRunner = TestRunner(config: shared.config)
    }

    // MARK: - Test Running

    /// Run tests with optional preset
    public static func run(preset: Preset = .minimal) async -> TestResult {
        await shared.runTests(preset: preset)
    }

    /// Run tests with custom options
    public static func run(options: RunOptions) async -> TestResult {
        await shared.runTests(options: options)
    }

    /// Run tests on launch if needed (checks build number)
    public static func runOnLaunchIfNeeded() async -> TestResult? {
        guard shared.config.testing.runOnLaunch else {
            logger.debug("Skipping launch tests (disabled in config)")
            return nil
        }

        let currentBuild = shared.config.project.buildNumber

        if shared.config.testing.runOnBuildChange, let build = currentBuild {
            if shared.lastTestedBuild == build {
                logger.debug("Skipping tests (build unchanged)", metadata: ["build": build])
                return nil
            }
        }

        logger.info("Running launch tests", metadata: ["build": currentBuild ?? "unknown"])
        let result = await shared.runTests(preset: .minimal)

        if let build = currentBuild {
            shared.lastTestedBuild = build
            UserDefaults.standard.set(build, forKey: Self.buildKey)
        }

        return result
    }

    /// Validate configuration
    public static func validate() -> Bool {
        do {
            _ = try ConfigLoader.loadAndValidate()
            logger.info("Configuration is valid")
            return true
        } catch {
            logger.error("Configuration is invalid", metadata: ["error": error.localizedDescription])
            return false
        }
    }

    /// Get the test runner for registering tests
    public static func getTestRunner() async -> TestRunner {
        shared.testRunner
    }

    /// Get the UI action dispatcher for accessibility-based control
    @MainActor
    public static var dispatcher: UIActionDispatcher {
        UIActionDispatcher.shared
    }

    /// Run a test plan with plan vs actual comparison
    @MainActor
    public static func runPlan(_ plan: TestPlan) async -> TestPlanResult {
        let runner = TestPlanRunner()
        return await runner.run(plan)
    }

    // MARK: - Private

    private func runTests(preset: Preset) async -> TestResult {
        let presetConfig = preset.config
        let options = RunOptions(
            tiers: presetConfig.tiers,
            stopOnFirstFailure: presetConfig.stopOnFirstFailure,
            parallel: presetConfig.parallel,
            retries: presetConfig.retries
        )
        return await runTests(options: options)
    }

    private func runTests(options: RunOptions) async -> TestResult {
        await testRunner.run(options: options)
    }
}

// MARK: - Run Options

public struct RunOptions: Sendable {
    public var tiers: [TestTier]
    public var stopOnFirstFailure: Bool
    public var parallel: Bool
    public var retries: Int

    public init(
        tiers: [TestTier] = [.smoke, .structure],
        stopOnFirstFailure: Bool = true,
        parallel: Bool = false,
        retries: Int = 2
    ) {
        self.tiers = tiers
        self.stopOnFirstFailure = stopOnFirstFailure
        self.parallel = parallel
        self.retries = retries
    }
}

// MARK: - Backward Compatibility

/// Typealias for backward compatibility
public typealias GhostUI = Aware
