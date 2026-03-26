import Foundation

// MARK: - Configuration

/// Configuration for the LogCollector
public struct LogCollectorConfig: Sendable {
    /// Base storage directory for logs
    public let storageDirectory: URL

    /// Maximum size of a single log file in bytes (default: 10MB)
    public let maxFileSizeBytes: Int

    /// Number of rotated files to keep (default: 5)
    public let rotationCount: Int

    /// Interval in seconds between automatic flushes (default: 5s)
    public let flushInterval: TimeInterval

    /// Project identifier for organizing logs
    public let projectId: String

    public init(
        storageDirectory: URL? = nil,
        maxFileSizeBytes: Int = 10 * 1024 * 1024,
        rotationCount: Int = 5,
        flushInterval: TimeInterval = 5.0,
        projectId: String = "default"
    ) {
        if let dir = storageDirectory {
            self.storageDirectory = dir
        } else {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            self.storageDirectory = homeDir.appendingPathComponent(".swiftaware/logs")
        }
        self.maxFileSizeBytes = maxFileSizeBytes
        self.rotationCount = rotationCount
        self.flushInterval = flushInterval
        self.projectId = projectId
    }

    /// Full path to the log file for this project
    var logFilePath: URL {
        storageDirectory
            .appendingPathComponent(projectId)
            .appendingPathComponent("events.jsonl")
    }

    /// Directory for this project's logs
    var projectLogDirectory: URL {
        storageDirectory.appendingPathComponent(projectId)
    }
}

// MARK: - Persisted Log Event

/// A log event that can be persisted to disk
public struct PersistedLogEvent: Codable, Sendable {
    public let timestamp: Date
    public let level: AwareLogLevel
    public let category: String
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    public let metadata: [String: String]?

    public init(
        timestamp: Date = Date(),
        level: AwareLogLevel,
        category: String,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String]? = nil
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
    }

    /// Create from a LogEvent
    public init(from event: LogEvent) {
        self.timestamp = event.timestamp
        self.level = event.level
        self.category = event.category
        self.message = event.message
        self.file = event.source?.file ?? ""
        self.function = event.source?.function ?? ""
        self.line = event.source?.line ?? 0
        self.metadata = event.metadata
    }
}

// MARK: - Collector Metrics

/// Metrics tracked by the LogCollector
public struct CollectorMetrics: Sendable {
    /// Total number of events collected
    public let totalEvents: Int

    /// Count of events by log level
    public let eventsByLevel: [AwareLogLevel: Int]

    /// Count of events by category
    public let eventsByCategory: [String: Int]

    /// Number of flushes performed
    public let flushCount: Int

    /// Number of file rotations performed
    public let rotationCount: Int

    /// Last flush timestamp
    public let lastFlushTime: Date?

    public init(
        totalEvents: Int = 0,
        eventsByLevel: [AwareLogLevel: Int] = [:],
        eventsByCategory: [String: Int] = [:],
        flushCount: Int = 0,
        rotationCount: Int = 0,
        lastFlushTime: Date? = nil
    ) {
        self.totalEvents = totalEvents
        self.eventsByLevel = eventsByLevel
        self.eventsByCategory = eventsByCategory
        self.flushCount = flushCount
        self.rotationCount = rotationCount
        self.lastFlushTime = lastFlushTime
    }
}

// MARK: - Query Filter

/// Filter for querying log events
public struct LogEventFilter: Sendable {
    public var levels: Set<AwareLogLevel>?
    public var categories: Set<String>?
    public var startDate: Date?
    public var endDate: Date?
    public var messageContains: String?
    public var limit: Int?

    public init(
        levels: Set<AwareLogLevel>? = nil,
        categories: Set<String>? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        messageContains: String? = nil,
        limit: Int? = nil
    ) {
        self.levels = levels
        self.categories = categories
        self.startDate = startDate
        self.endDate = endDate
        self.messageContains = messageContains
        self.limit = limit
    }

    /// Check if an event matches this filter
    func matches(_ event: PersistedLogEvent) -> Bool {
        if let levels = levels, !levels.contains(event.level) {
            return false
        }
        if let categories = categories, !categories.contains(event.category) {
            return false
        }
        if let startDate = startDate, event.timestamp < startDate {
            return false
        }
        if let endDate = endDate, event.timestamp > endDate {
            return false
        }
        if let messageContains = messageContains,
           !event.message.localizedCaseInsensitiveContains(messageContains) {
            return false
        }
        return true
    }
}

// MARK: - Log Collector Actor

/// Thread-safe log collector that buffers and persists log events
public actor LogCollector {

    // MARK: - Properties

    private let config: LogCollectorConfig
    private var buffer: [PersistedLogEvent] = []
    private var flushTask: Task<Void, Never>?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // Metrics tracking
    private var totalEvents: Int = 0
    private var eventsByLevel: [AwareLogLevel: Int] = [:]
    private var eventsByCategory: [String: Int] = [:]
    private var flushCount: Int = 0
    private var rotationCountValue: Int = 0
    private var lastFlushTime: Date?

    // MARK: - Initialization

    public init(config: LogCollectorConfig = LogCollectorConfig()) {
        self.config = config

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// Start the automatic flush timer
    public func start() {
        guard flushTask == nil else { return }

        flushTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self?.config.flushInterval ?? 5.0) * 1_000_000_000)
                await self?.flush()
            }
        }
    }

    /// Stop the automatic flush timer
    public func stop() async {
        flushTask?.cancel()
        flushTask = nil
        await flush()
    }

    // MARK: - Collecting Events

    /// Collect a log event into the buffer
    public func collect(_ event: PersistedLogEvent) {
        buffer.append(event)

        // Update metrics
        totalEvents += 1
        eventsByLevel[event.level, default: 0] += 1
        eventsByCategory[event.category, default: 0] += 1
    }

    /// Collect a LogEvent (converts to PersistedLogEvent)
    public func collect(_ event: LogEvent) {
        collect(PersistedLogEvent(from: event))
    }

    // MARK: - Flushing

    /// Flush buffered events to disk in JSON Lines format
    public func flush() async {
        guard !buffer.isEmpty else { return }

        let eventsToWrite = buffer
        buffer = []

        do {
            try ensureDirectoryExists()
            try await checkAndRotateIfNeeded()

            let fileHandle = try getFileHandle()
            defer { try? fileHandle.close() }

            for event in eventsToWrite {
                let jsonData = try encoder.encode(event)
                try fileHandle.seekToEnd()
                try fileHandle.write(contentsOf: jsonData)
                try fileHandle.write(contentsOf: Data("\n".utf8))
            }

            flushCount += 1
            lastFlushTime = Date()

        } catch {
            // Re-buffer events on failure
            buffer = eventsToWrite + buffer
            print("[LogCollector] Flush failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Querying

    /// Get events matching the specified filter
    public func getEvents(matching filter: LogEventFilter = LogEventFilter()) async -> [PersistedLogEvent] {
        var results: [PersistedLogEvent] = []

        // First check buffer
        for event in buffer {
            if filter.matches(event) {
                results.append(event)
            }
        }

        // Then read from disk
        let diskEvents = await readEventsFromDisk(matching: filter)
        results = diskEvents + results

        // Apply limit if specified
        if let limit = filter.limit, results.count > limit {
            results = Array(results.suffix(limit))
        }

        return results
    }

    /// Get current metrics
    public func getMetrics() -> CollectorMetrics {
        CollectorMetrics(
            totalEvents: totalEvents,
            eventsByLevel: eventsByLevel,
            eventsByCategory: eventsByCategory,
            flushCount: flushCount,
            rotationCount: rotationCountValue,
            lastFlushTime: lastFlushTime
        )
    }

    // MARK: - Private Helpers

    private func ensureDirectoryExists() throws {
        let fm = FileManager.default
        let dir = config.projectLogDirectory

        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func getFileHandle() throws -> FileHandle {
        let fm = FileManager.default
        let path = config.logFilePath

        if !fm.fileExists(atPath: path.path) {
            fm.createFile(atPath: path.path, contents: nil)
        }

        return try FileHandle(forWritingTo: path)
    }

    private func checkAndRotateIfNeeded() async throws {
        let fm = FileManager.default
        let path = config.logFilePath

        guard fm.fileExists(atPath: path.path) else { return }

        let attributes = try fm.attributesOfItem(atPath: path.path)
        let fileSize = attributes[.size] as? Int ?? 0

        if fileSize >= config.maxFileSizeBytes {
            try await rotateLogFiles()
        }
    }

    private func rotateLogFiles() async throws {
        let fm = FileManager.default
        let basePath = config.logFilePath
        let directory = config.projectLogDirectory

        // Remove oldest file if at rotation limit
        let oldestPath = directory.appendingPathComponent("events.\(config.rotationCount).jsonl")
        if fm.fileExists(atPath: oldestPath.path) {
            try fm.removeItem(at: oldestPath)
        }

        // Shift existing rotated files
        for i in stride(from: config.rotationCount - 1, through: 1, by: -1) {
            let sourcePath = directory.appendingPathComponent("events.\(i).jsonl")
            let destPath = directory.appendingPathComponent("events.\(i + 1).jsonl")

            if fm.fileExists(atPath: sourcePath.path) {
                try fm.moveItem(at: sourcePath, to: destPath)
            }
        }

        // Move current file to .1
        if fm.fileExists(atPath: basePath.path) {
            let rotatedPath = directory.appendingPathComponent("events.1.jsonl")
            try fm.moveItem(at: basePath, to: rotatedPath)
        }

        rotationCountValue += 1
    }

    private func readEventsFromDisk(matching filter: LogEventFilter) async -> [PersistedLogEvent] {
        var events: [PersistedLogEvent] = []
        let fm = FileManager.default
        let directory = config.projectLogDirectory

        guard fm.fileExists(atPath: directory.path) else { return events }

        // Read from all log files (current + rotated)
        var filesToRead: [URL] = []

        // Add rotated files first (oldest to newest)
        for i in stride(from: config.rotationCount, through: 1, by: -1) {
            let rotatedPath = directory.appendingPathComponent("events.\(i).jsonl")
            if fm.fileExists(atPath: rotatedPath.path) {
                filesToRead.append(rotatedPath)
            }
        }

        // Add current file last
        let currentPath = config.logFilePath
        if fm.fileExists(atPath: currentPath.path) {
            filesToRead.append(currentPath)
        }

        // Read and parse each file
        for fileURL in filesToRead {
            if let fileEvents = readEventsFromFile(at: fileURL, matching: filter) {
                events.append(contentsOf: fileEvents)
            }
        }

        return events
    }

    private func readEventsFromFile(at url: URL, matching filter: LogEventFilter) -> [PersistedLogEvent]? {
        guard let data = FileManager.default.contents(atPath: url.path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        var events: [PersistedLogEvent] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines where !line.isEmpty {
            guard let lineData = line.data(using: .utf8) else { continue }

            do {
                let event = try decoder.decode(PersistedLogEvent.self, from: lineData)
                if filter.matches(event) {
                    events.append(event)
                }
            } catch {
                // Skip malformed lines
                continue
            }
        }

        return events
    }

    /// Clear all logs for this project
    public func clearLogs() throws {
        buffer = []

        let fm = FileManager.default
        let directory = config.projectLogDirectory

        if fm.fileExists(atPath: directory.path) {
            try fm.removeItem(at: directory)
        }
    }
}
