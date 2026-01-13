//
//  MCPProtocol.swift
//  AwareBridge
//
//  MCP (Model Context Protocol) command types for LLM-driven UI testing.
//  Defines the wire protocol for communication between Breathe IDE and Aware apps.
//

import Foundation

// MARK: - MCP Command

/// MCP command from LLM/Breathe to Aware app
public struct MCPCommand: Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let action: MCPAction
    public let parameters: [String: String]?

    public init(id: String = UUID().uuidString, timestamp: Date = Date(), action: MCPAction, parameters: [String: String]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.parameters = parameters
    }
}

/// MCP action types
public enum MCPAction: String, Codable, Sendable {
    // UI Queries
    case snapshot           // Get current UI state
    case find               // Find element by criteria
    case getState           // Get specific element state

    // UI Actions
    case tap                // Tap element
    case type               // Type text into field
    case swipe              // Swipe gesture
    case scroll             // Scroll container
    case longPress          // Long press element
    case doubleTap          // Double tap element

    // Focus Management
    case focus              // Focus specific element
    case focusNext          // Tab to next field
    case focusPrevious      // Shift+Tab to previous

    // Testing
    case wait               // Wait for condition
    case assert             // Assert condition
    case test               // Run batch test

    // Lifecycle
    case ping               // Health check
    case configure          // Configure bridge
}

// MARK: - MCP Result

/// MCP result from Aware app back to LLM/Breathe
public struct MCPResult: Codable, Sendable {
    public let commandId: String
    public let timestamp: Date
    public let success: Bool
    public let data: [String: String]?
    public let error: MCPError?

    public init(commandId: String, timestamp: Date = Date(), success: Bool, data: [String: String]? = nil, error: MCPError? = nil) {
        self.commandId = commandId
        self.timestamp = timestamp
        self.success = success
        self.data = data
        self.error = error
    }

    /// Create success result
    public static func success(commandId: String, data: [String: String]? = nil) -> MCPResult {
        MCPResult(commandId: commandId, success: true, data: data, error: nil)
    }

    /// Create error result
    public static func failure(commandId: String, error: MCPError) -> MCPResult {
        MCPResult(commandId: commandId, success: false, data: nil, error: error)
    }
}

/// MCP error types
public struct MCPError: Codable, Sendable {
    public let code: String
    public let message: String
    public let details: [String: String]?

    public init(code: String, message: String, details: [String: String]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }

    // Common error codes
    public static let elementNotFound = MCPError(code: "ELEMENT_NOT_FOUND", message: "Element not found")
    public static let actionFailed = MCPError(code: "ACTION_FAILED", message: "Action execution failed")
    public static let timeout = MCPError(code: "TIMEOUT", message: "Operation timed out")
    public static let invalidParameters = MCPError(code: "INVALID_PARAMETERS", message: "Invalid command parameters")
    public static let notReady = MCPError(code: "NOT_READY", message: "UI not ready")
}

// MARK: - MCP Event

/// MCP event streamed from Aware app to LLM/Breathe (push notifications)
public struct MCPEvent: Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let type: MCPEventType
    public let viewId: String?
    public let data: [String: String]?

    public init(id: String = UUID().uuidString, timestamp: Date = Date(), type: MCPEventType, viewId: String? = nil, data: [String: String]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.viewId = viewId
        self.data = data
    }
}

/// MCP event types
public enum MCPEventType: String, Codable, Sendable {
    case viewAppeared       // View appeared on screen
    case viewDisappeared    // View disappeared from screen
    case stateChanged       // View state changed
    case actionCompleted    // Action completed
    case error              // Error occurred
    case navigationChanged  // Navigation changed
    case focusChanged       // Focus changed
    case ready              // App ready for commands
}

// MARK: - MCP Batch

/// Batch multiple commands for atomic execution
public struct MCPBatch: Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let commands: [MCPCommand]
    public let atomic: Bool  // If true, rollback all on any failure

    public init(id: String = UUID().uuidString, timestamp: Date = Date(), commands: [MCPCommand], atomic: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.commands = commands
        self.atomic = atomic
    }
}

/// Batch result
public struct MCPBatchResult: Codable, Sendable {
    public let batchId: String
    public let timestamp: Date
    public let results: [MCPResult]
    public let allSucceeded: Bool

    public init(batchId: String, timestamp: Date = Date(), results: [MCPResult]) {
        self.batchId = batchId
        self.timestamp = timestamp
        self.results = results
        self.allSucceeded = results.allSatisfy { $0.success }
    }
}

// MARK: - MCP Configuration

/// Configuration for MCP bridge
public struct MCPConfiguration: Codable, Sendable {
    public let port: Int
    public let host: String
    public let enableEvents: Bool
    public let eventBufferSize: Int
    public let commandTimeout: TimeInterval

    public init(port: Int = 9999, host: String = "localhost", enableEvents: Bool = true, eventBufferSize: Int = 100, commandTimeout: TimeInterval = 30.0) {
        self.port = port
        self.host = host
        self.enableEvents = enableEvents
        self.eventBufferSize = eventBufferSize
        self.commandTimeout = commandTimeout
    }

    /// Default configuration for Breathe IDE integration
    public static let breatheDefault = MCPConfiguration(
        port: 9999,
        host: "localhost",
        enableEvents: true,
        eventBufferSize: 100,
        commandTimeout: 30.0
    )
}
