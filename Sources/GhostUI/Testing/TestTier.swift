import Foundation

/// Test tier classification
public enum TestTier: String, Codable, Sendable, CaseIterable {
    case smoke
    case structure
    case integration

    public var targetDuration: TimeInterval {
        switch self {
        case .smoke: return 3
        case .structure: return 30
        case .integration: return 120
        }
    }

    public var description: String {
        switch self {
        case .smoke: return "Smoke Tests (< 3s)"
        case .structure: return "Structure Tests (< 30s)"
        case .integration: return "Integration Tests (< 2min)"
        }
    }
}
