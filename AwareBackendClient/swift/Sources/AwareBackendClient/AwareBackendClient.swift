//
//  AwareBackendClient.swift
//  AwareBackendClient
//
//  HTTP client for connecting to BackendAware REST API.
//  Enables remote service introspection and control from iOS/macOS apps.
//

import Foundation

// MARK: - Backend Client

/// HTTP client for BackendAware REST API
public actor AwareBackendClient {
    // MARK: - Configuration

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    /// Initialize backend client with base URL
    /// - Parameters:
    ///   - baseURL: Base URL of BackendAware server (e.g., "http://localhost:8000")
    ///   - configuration: Optional URLSession configuration
    public init(baseURL: URL, configuration: URLSessionConfiguration = .default) {
        self.baseURL = baseURL
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    /// Convenience initializer with string URL
    public init?(baseURLString: String, configuration: URLSessionConfiguration = .default) {
        guard let url = URL(string: baseURLString) else { return nil }
        self.init(baseURL: url, configuration: configuration)
    }

    // MARK: - State Queries

    /// GET /aware/state - Get current backend state
    public func getState() async throws -> BackendState {
        let url = baseURL.appendingPathComponent("/aware/state")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return try decoder.decode(BackendState.self, from: data)
    }

    /// GET /aware/components - List available backend components
    public func getComponents() async throws -> [BackendComponent] {
        let url = baseURL.appendingPathComponent("/aware/components")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return try decoder.decode([BackendComponent].self, from: data)
    }

    /// GET /aware/snapshot - Get full backend snapshot
    public func getSnapshot() async throws -> BackendSnapshot {
        let url = baseURL.appendingPathComponent("/aware/snapshot")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return try decoder.decode(BackendSnapshot.self, from: data)
    }

    // MARK: - Command Execution

    /// POST /aware/execute - Execute a command on the backend
    /// - Parameter command: Command to execute
    /// - Returns: Result of command execution
    public func execute(_ command: BackendCommand) async throws -> BackendResult {
        let url = baseURL.appendingPathComponent("/aware/execute")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(command)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return try decoder.decode(BackendResult.self, from: data)
    }

    /// POST /aware/batch - Execute multiple commands in sequence
    /// - Parameter commands: Array of commands to execute
    /// - Returns: Array of results matching command order
    public func executeBatch(_ commands: [BackendCommand]) async throws -> [BackendResult] {
        let url = baseURL.appendingPathComponent("/aware/batch")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(commands)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return try decoder.decode([BackendResult].self, from: data)
    }

    // MARK: - Health Check

    /// GET /aware/health - Check if backend is healthy
    public func healthCheck() async throws -> BackendHealth {
        let url = baseURL.appendingPathComponent("/aware/health")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return try decoder.decode(BackendHealth.self, from: data)
    }

    // MARK: - Shutdown

    /// Invalidate session and cleanup resources
    public func shutdown() {
        session.invalidateAndCancel()
    }
}

// MARK: - Backend Types

/// Current state of the backend
public struct BackendState: Codable, Sendable {
    public let timestamp: Date
    public let components: [String: ComponentState]
    public let metrics: BackendMetrics?

    public struct ComponentState: Codable, Sendable {
        public let status: String
        public let metadata: [String: String]
    }
}

/// Backend component definition
public struct BackendComponent: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let type: String
    public let description: String?
    public let endpoints: [String]?
    public let methods: [String]?
}

/// Full backend snapshot
public struct BackendSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let state: BackendState
    public let components: [BackendComponent]
    public let requests: [BackendRequest]?
}

/// Backend command
public struct BackendCommand: Codable, Sendable {
    public let action: String
    public let target: String?
    public let parameters: [String: String]?

    public init(action: String, target: String? = nil, parameters: [String: String]? = nil) {
        self.action = action
        self.target = target
        self.parameters = parameters
    }
}

/// Backend command result
public struct BackendResult: Codable, Sendable {
    public let success: Bool
    public let message: String?
    public let data: [String: String]?

    public init(success: Bool, message: String? = nil, data: [String: String]? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

/// Backend health status
public struct BackendHealth: Codable, Sendable {
    public let status: String
    public let timestamp: Date
    public let uptime: TimeInterval?
    public let version: String?
}

/// Backend metrics
public struct BackendMetrics: Codable, Sendable {
    public let requestCount: Int?
    public let averageLatency: Double?
    public let errorRate: Double?
}

/// Backend request log entry
public struct BackendRequest: Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let method: String
    public let path: String
    public let statusCode: Int
    public let duration: TimeInterval
}

// MARK: - Errors

/// Backend client errors
public enum BackendError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        }
    }
}
