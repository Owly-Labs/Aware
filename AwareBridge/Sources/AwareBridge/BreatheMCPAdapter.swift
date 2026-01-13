//
//  BreatheMCPAdapter.swift
//  AwareBridge
//
//  High-level adapter for Breathe IDE integration with Aware apps.
//  Provides MCP tool implementations (ui_snapshot, ui_action, ui_wait, etc.)
//

import Foundation
import AwareCore

// MARK: - Breathe MCP Adapter

/// Adapter for Breathe IDE MCP tools
@MainActor
public final class BreatheMCPAdapter: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = BreatheMCPAdapter()

    // MARK: - Dependencies

    private let bridge: WebSocketBridge
    private var pendingResults: [String: CheckedContinuation<MCPResult, Never>] = [:]

    // MARK: - Initialization

    private init(bridge: WebSocketBridge = .shared) {
        self.bridge = bridge

        // Register handlers
        bridge.onCommand { [weak self] command in
            await self?.handleCommand(command) ?? MCPResult.failure(
                commandId: command.id,
                error: MCPError(code: "ADAPTER_ERROR", message: "Adapter not available")
            )
        }

        bridge.onBatch { [weak self] batch in
            await self?.handleBatch(batch) ?? MCPBatchResult(
                batchId: batch.id,
                results: batch.commands.map { cmd in
                    MCPResult.failure(commandId: cmd.id, error: MCPError(code: "ADAPTER_ERROR", message: "Adapter not available"))
                }
            )
        }
    }

    // MARK: - Lifecycle

    /// Start adapter (starts WebSocket server)
    public func start() async throws {
        try await bridge.start()
    }

    /// Stop adapter
    public func stop() async {
        await bridge.stop()
    }

    // MARK: - MCP Tool Implementations

    /// ui_snapshot - Get current UI state
    public func snapshot(format: AwareSnapshotFormat = .compact) async -> String {
        let command = MCPCommand(action: .snapshot, parameters: ["format": format.rawValue])
        let result = await executeCommand(command)

        if result.success, let snapshot = result.data?["snapshot"] {
            return snapshot
        }

        return "Error: \(result.error?.message ?? "Unknown error")"
    }

    /// ui_action - Perform UI action (tap, type, swipe, etc.)
    public func action(type: String, viewId: String, parameters: [String: String] = [:]) async -> Bool {
        var params = parameters
        params["viewId"] = viewId

        let action: MCPAction
        switch type.lowercased() {
        case "tap": action = .tap
        case "type": action = .type
        case "swipe": action = .swipe
        case "scroll": action = .scroll
        case "longpress": action = .longPress
        case "doubletap": action = .doubleTap
        default: return false
        }

        let command = MCPCommand(action: action, parameters: params)
        let result = await executeCommand(command)
        return result.success
    }

    /// ui_find - Find element by criteria
    public func find(label: String? = nil, type: String? = nil, state: [String: String]? = nil) async -> [String] {
        var parameters: [String: String] = [:]
        if let label = label { parameters["label"] = label }
        if let type = type { parameters["type"] = type }
        if let state = state {
            // Encode state as JSON string
            if let data = try? JSONSerialization.data(withJSONObject: state),
               let stateJson = String(data: data, encoding: .utf8) {
                parameters["state"] = stateJson
            }
        }

        let command = MCPCommand(action: .find, parameters: parameters)
        let result = await executeCommand(command)

        if result.success, let viewIds = result.data?["viewIds"] {
            return viewIds.split(separator: ",").map(String.init)
        }

        return []
    }

    /// ui_wait - Wait for condition
    public func wait(viewId: String, stateKey: String, expectedValue: String, timeout: TimeInterval = 5.0) async -> Bool {
        let parameters: [String: String] = [
            "viewId": viewId,
            "stateKey": stateKey,
            "expectedValue": expectedValue,
            "timeout": "\(timeout)"
        ]

        let command = MCPCommand(action: .wait, parameters: parameters)
        let result = await executeCommand(command)
        return result.success
    }

    /// ui_assert - Assert condition
    public func assert(viewId: String, condition: String, expectedValue: String) async -> Bool {
        let parameters: [String: String] = [
            "viewId": viewId,
            "condition": condition,
            "expectedValue": expectedValue
        ]

        let command = MCPCommand(action: .assert, parameters: parameters)
        let result = await executeCommand(command)
        return result.success
    }

    /// ui_test - Run batch test
    public func test(commands: [(action: String, viewId: String, parameters: [String: String])]) async -> Bool {
        let mcpCommands = commands.map { cmd -> MCPCommand in
            var params = cmd.parameters
            params["viewId"] = cmd.viewId

            let action: MCPAction
            switch cmd.action.lowercased() {
            case "tap": action = .tap
            case "type": action = .type
            case "wait": action = .wait
            case "assert": action = .assert
            default: action = .tap
            }

            return MCPCommand(action: action, parameters: params)
        }

        let batch = MCPBatch(commands: mcpCommands, atomic: true)
        let result = await executeBatch(batch)
        return result.allSucceeded
    }

    // MARK: - Focus Management

    /// Focus specific element
    public func focus(viewId: String) async -> Bool {
        let command = MCPCommand(action: .focus, parameters: ["viewId": viewId])
        let result = await executeCommand(command)
        return result.success
    }

    /// Tab to next field
    public func focusNext() async -> Bool {
        let command = MCPCommand(action: .focusNext)
        let result = await executeCommand(command)
        return result.success
    }

    /// Shift+Tab to previous field
    public func focusPrevious() async -> Bool {
        let command = MCPCommand(action: .focusPrevious)
        let result = await executeCommand(command)
        return result.success
    }

    // MARK: - Health

    /// Ping server
    public func ping() async -> Bool {
        let command = MCPCommand(action: .ping)
        let result = await executeCommand(command)
        return result.success
    }

    /// Check connection status
    public var isConnected: Bool {
        bridge.isConnected
    }

    // MARK: - Command Execution

    private func executeCommand(_ command: MCPCommand) async -> MCPResult {
        // This will be handled by the command handler which forwards to Aware
        return await withCheckedContinuation { continuation in
            pendingResults[command.id] = continuation
            Task {
                await bridge.sendEvent(MCPEvent(type: .actionCompleted, viewId: nil, data: ["commandId": command.id]))
            }
        }
    }

    private func executeBatch(_ batch: MCPBatch) async -> MCPBatchResult {
        // Execute commands sequentially
        var results: [MCPResult] = []

        for command in batch.commands {
            let result = await executeCommand(command)
            results.append(result)

            // If atomic and failed, stop
            if batch.atomic && !result.success {
                break
            }
        }

        return MCPBatchResult(batchId: batch.id, results: results)
    }

    // MARK: - Command Handlers

    private func handleCommand(_ command: MCPCommand) async -> MCPResult {
        // This is called when bridge receives a command
        // Forward to Aware for execution

        // For now, return success (actual implementation will integrate with Aware)
        return MCPResult.success(commandId: command.id, data: ["status": "executed"])
    }

    private func handleBatch(_ batch: MCPBatch) async -> MCPBatchResult {
        var results: [MCPResult] = []

        for command in batch.commands {
            let result = await handleCommand(command)
            results.append(result)

            if batch.atomic && !result.success {
                break
            }
        }

        return MCPBatchResult(batchId: batch.id, results: results)
    }

    // MARK: - Event Handling

    /// Register event handler for Breathe IDE
    public func onEvent(_ handler: @escaping (MCPEvent) -> Void) {
        // Events are already broadcast via bridge
        // This just provides a convenience hook
    }
}
