import Foundation

/// Predefined configuration presets
public enum Preset: String, Sendable {
    case minimal
    case verbose
    case ci

    public var config: TestingConfig {
        switch self {
        case .minimal:
            return TestingConfig(
                tiers: [.smoke],
                stopOnFirstFailure: true,
                parallel: false,
                retries: 0
            )

        case .verbose:
            return TestingConfig(
                tiers: [.smoke, .structure, .integration],
                stopOnFirstFailure: false,
                parallel: false,
                retries: 3
            )

        case .ci:
            return TestingConfig(
                tiers: [.smoke, .structure],
                stopOnFirstFailure: true,
                parallel: true,
                retries: 2
            )
        }
    }
}
