import Foundation

/// Performance breakdown item for tracking operation timing details
public struct PerformanceBreakdownItem: Codable, Sendable {
    public let operation: String
    public let duration: TimeInterval
    public let file: String
    public let line: Int

    public init(operation: String, duration: TimeInterval, file: String, line: Int) {
        self.operation = operation
        self.duration = duration
        self.file = file
        self.line = line
    }
}
