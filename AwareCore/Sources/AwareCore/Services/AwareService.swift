//
//  AwareService.swift
//  Aware
//
//  Central service for building UI snapshots for LLM consumption.
//  Captures view hierarchy, positions, colors, fonts, and state as text.
//

import Foundation
import SwiftUI
import os.log

// MARK: - Aware

/// Central service for capturing UI state as text for LLM consumption
@MainActor
public final class Aware: ObservableObject {
    public static let shared = Aware()

    // MARK: - Configuration

    /// Configurable snapshot file path (default: ~/.aware/ui-snapshot.json)
    public var snapshotFilePath: String = NSHomeDirectory() + "/.aware/ui-snapshot.json"

    private var writeDebounceTask: Task<Void, Never>?
    let logger = Logger(subsystem: "com.aware.framework", category: "Aware")

    // MARK: - State Registry

    /// Registered views with session/project context
    @Published public var viewRegistry: [String: AwareViewRegistration] = [:]

    /// State values by view ID
    public var stateRegistry: [String: [String: String]] = [:]

    /// Parent-child relationships
    var parentChildMap: [String: String] = [:]  // childId -> parentId

    /// Registry version - incremented on any structural change
    var registryVersion: Int = 0

    /// Maximum number of registrations to keep (LRU eviction)
    private let maxRegistrations: Int = 1000

    /// Default TTL for registrations (5 minutes)
    public var defaultTTL: TimeInterval = 300

    // MARK: - Prop-State Consistency Tracking (Stale @State Detection)

    /// Tracks prop → state bindings for staleness detection
    private var propStateBindings: [String: [PropStateBinding]] = [:]

    /// Detected staleness warnings (prop changed but state didn't follow)
    @Published public var stalenessWarnings: [StalenessWarning] = []

    /// Staleness detection threshold (how long after prop change before warning)
    private let stalenessThreshold: TimeInterval = 0.3  // 300ms

    /// Register a prop-state binding for staleness detection
    public func registerPropStateBinding(
        _ viewId: String,
        propKey: String,
        stateKey: String,
        propValue: String,
        stateValue: String
    ) {
        let binding = PropStateBinding(
            propKey: propKey,
            stateKey: stateKey,
            propValue: propValue,
            stateValue: stateValue
        )

        if propStateBindings[viewId] == nil {
            propStateBindings[viewId] = []
        }

        // Replace existing binding for same prop-state pair
        propStateBindings[viewId]?.removeAll { $0.propKey == propKey && $0.stateKey == stateKey }
        propStateBindings[viewId]?.append(binding)

        // Clear any existing warning for this binding (it's now in sync)
        stalenessWarnings.removeAll { $0.viewId == viewId && $0.propKey == propKey && $0.stateKey == stateKey }
    }

    /// Update prop value and check for staleness
    public func updatePropValue(
        _ viewId: String,
        propKey: String,
        newPropValue: String
    ) {
        guard var bindings = propStateBindings[viewId] else { return }

        for i in bindings.indices {
            if bindings[i].propKey == propKey {
                let oldPropValue = bindings[i].lastPropValue

                // Prop changed - mark the time for staleness detection
                if oldPropValue != newPropValue {
                    bindings[i].lastPropValue = newPropValue
                    bindings[i].lastSyncTime = Date()

                    // Schedule staleness check
                    let stateKey = bindings[i].stateKey
                    Task { @MainActor [weak self] in
                        do {
                            try await Task.sleep(nanoseconds: UInt64((self?.stalenessThreshold ?? 0.3) * 1_000_000_000))
                        } catch is CancellationError {
                            return  // Exit if staleness check cancelled
                        } catch {
                            // Unexpected error in staleness timer, ignore
                        }
                        self?.checkForStaleness(viewId: viewId, propKey: propKey, stateKey: stateKey)
                    }
                }
            }
        }
        propStateBindings[viewId] = bindings
    }

    /// Update state value - clears staleness warning if state caught up
    public func updateStateValue(
        _ viewId: String,
        stateKey: String,
        newStateValue: String
    ) {
        guard var bindings = propStateBindings[viewId] else { return }

        for i in bindings.indices {
            if bindings[i].stateKey == stateKey {
                bindings[i].lastStateValue = newStateValue
                bindings[i].lastSyncTime = Date()

                // Clear any staleness warning
                stalenessWarnings.removeAll {
                    $0.viewId == viewId && $0.stateKey == stateKey
                }
            }
        }
        propStateBindings[viewId] = bindings
    }

    /// Check if state is stale (prop changed but state didn't follow)
    private func checkForStaleness(viewId: String, propKey: String, stateKey: String) {
        guard let bindings = propStateBindings[viewId],
              let binding = bindings.first(where: { $0.propKey == propKey && $0.stateKey == stateKey })
        else { return }

        let timeSinceSync = Date().timeIntervalSince(binding.lastSyncTime)

        // If state hasn't been updated since prop changed, it's stale
        if timeSinceSync >= stalenessThreshold {
            let warningExists = stalenessWarnings.contains {
                $0.viewId == viewId && $0.propKey == propKey && $0.stateKey == stateKey
            }

            if !warningExists {
                let warning = StalenessWarning(
                    viewId: viewId,
                    propKey: propKey,
                    stateKey: stateKey,
                    propValue: binding.lastPropValue,
                    staleStateValue: binding.lastStateValue,
                    staleDuration: timeSinceSync
                )
                stalenessWarnings.append(warning)
                logger.warning("Aware: \(warning.description)")
            }
        }
    }

    /// Clear all prop-state bindings for a view (on disappear)
    public func clearPropStateBindings(_ viewId: String) {
        propStateBindings.removeValue(forKey: viewId)
        stalenessWarnings.removeAll { $0.viewId == viewId }
    }

    /// Get active staleness warnings for assertions
    public func getStalenessWarnings(for viewId: String? = nil) -> [StalenessWarning] {
        if let viewId = viewId {
            return stalenessWarnings.filter { $0.viewId == viewId }
        }
        return stalenessWarnings
    }

    /// Assert no staleness warnings exist (for tests)
    public func assertNoPropStateStaleness(viewId: String? = nil) -> (passed: Bool, message: String) {
        let warnings = getStalenessWarnings(for: viewId)
        if warnings.isEmpty {
            return (true, "No prop-state staleness detected")
        } else {
            let details = warnings.map { $0.description }.joined(separator: "\n")
            return (false, "Prop-state staleness detected:\n\(details)")
        }
    }

    // MARK: - Identity-Based Staleness Detection (Automatic)

    /// Tracks view identity values for automatic staleness detection
    private var identityRegistry: [String: [String: String]] = [:]

    /// Tracks pending identity change checks
    private var pendingIdentityChecks: Set<String> = []

    /// Register/update a view's identity value
    public func trackIdentity(_ viewId: String, identityKey: String, value: String) {
        let oldValue = identityRegistry[viewId]?[identityKey]

        // Update registry
        if identityRegistry[viewId] == nil {
            identityRegistry[viewId] = [:]
        }
        identityRegistry[viewId]?[identityKey] = value

        // Check if identity changed (skip first registration)
        if let oldValue = oldValue, oldValue != value {
            logger.debug("Aware: Identity change detected for '\(viewId)': \(identityKey) '\(oldValue)' → '\(value)'")
            scheduleAutoStalenessCheck(viewId: viewId, identityKey: identityKey, oldIdentity: oldValue, newIdentity: value)
        }
    }

    /// Clear identity tracking when view disappears
    public func clearIdentity(_ viewId: String) {
        identityRegistry.removeValue(forKey: viewId)
        pendingIdentityChecks.remove(viewId)
    }

    /// Schedule automatic staleness check after identity change
    private func scheduleAutoStalenessCheck(viewId: String, identityKey: String, oldIdentity: String, newIdentity: String) {
        guard !pendingIdentityChecks.contains(viewId) else { return }
        pendingIdentityChecks.insert(viewId)

        // Capture state snapshot BEFORE the change propagates
        let beforeState = stateRegistry[viewId] ?? [:]

        Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64((self?.stalenessThreshold ?? 0.3) * 1_000_000_000))
            } catch is CancellationError {
                return  // Exit if identity check cancelled
            } catch {
                // Unexpected error in identity check timer, ignore
            }

            guard let self = self else { return }
            self.pendingIdentityChecks.remove(viewId)

            // Get state AFTER the wait
            let afterState = self.stateRegistry[viewId] ?? [:]

            // Compare: if NO state changed after identity changed, it's likely stale
            if beforeState == afterState && !beforeState.isEmpty {
                let warning = StalenessWarning(
                    viewId: viewId,
                    propKey: identityKey,
                    stateKey: "auto:all_states",
                    propValue: newIdentity,
                    staleStateValue: "unchanged from \(oldIdentity)",
                    staleDuration: self.stalenessThreshold
                )
                self.stalenessWarnings.append(warning)
                self.logger.warning("Aware: AUTO-STALENESS DETECTED - \(warning.description)")

                // Post notification for visual overlay (DEBUG builds)
                #if DEBUG
                NotificationCenter.default.post(
                    name: .awareStalenessDetected,
                    object: nil,
                    userInfo: [
                        "viewId": viewId,
                        "message": warning.description,
                    ]
                )
                #endif
            } else if beforeState != afterState {
                self.logger.debug("Aware: State updated correctly after identity change '\(viewId)'")

                #if DEBUG
                NotificationCenter.default.post(
                    name: .awareStalenessCleared,
                    object: nil,
                    userInfo: ["viewId": viewId]
                )
                #endif
            }
        }
    }

    /// Get current identity value for a view
    public func getIdentity(_ viewId: String, key: String) -> String? {
        identityRegistry[viewId]?[key]
    }

    // MARK: - iOS Gesture Callbacks

    /// Gesture callbacks by view ID and gesture type
    var gestureCallbacks: [String: [AwareGestureType: AwareGestureCallback]] = [:]

    /// Parameterized gesture callbacks (for gestures that need direction, scale, etc.)
    var parameterizedGestureCallbacks: [String: [AwareGestureType: AwareParameterizedGestureCallback]] = [:]

    /// Text bindings by view ID for direct text manipulation
    var textBindings: [String: AwareTextBinding] = [:]

    // MARK: - Direct Action Callbacks (LLM-controlled without mouse)

    /// Action callbacks by view ID
    var actionCallbacks: [String: @MainActor () async -> Void] = [:]

    /// Register a direct action callback for a view
    public func registerAction(_ viewId: String, callback: @escaping @MainActor () async -> Void) {
        actionCallbacks[viewId] = callback
    }

    /// Unregister action callback when view disappears
    public func unregisterAction(_ viewId: String) {
        actionCallbacks.removeValue(forKey: viewId)
    }

    /// Check if a view has a direct action callback registered
    public func hasDirectAction(_ viewId: String) -> Bool {
        actionCallbacks[viewId] != nil
    }

    /// List all registered action callback IDs
    public func listRegisteredActions() -> [String] {
        Array(actionCallbacks.keys).sorted()
    }

    /// Get all tracked states
    public func getAllStates() -> [String: [String: String]] {
        stateRegistry
    }

    // MARK: - Auto-Save to File

    /// Schedule a debounced write to the snapshot file
    func scheduleSnapshotWrite() {
        writeDebounceTask?.cancel()
        writeDebounceTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch is CancellationError {
                return  // Debounce cancelled, don't write
            } catch {
                // Unexpected error in debounce timer, ignore
            }
            guard !Task.isCancelled else { return }
            writeSnapshotToFile()
        }
    }

    /// Write current snapshot to file for external consumption
    private func writeSnapshotToFile() {
        let snapshot = captureSnapshot(format: .compact)

        // Ensure directory exists
        let dir = (snapshotFilePath as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        } catch {
            // Directory creation failed, can't write snapshot
            return
        }

        // Build result object
        let result: [String: Any] = [
            "ok": true,
            "content": snapshot.content,
            "viewCount": snapshot.viewCount,
            "format": snapshot.format,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]

        // Write to file
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        } catch {
            // JSON serialization failed, can't write snapshot
            return
        }

        do {
            try data.write(to: URL(fileURLWithPath: snapshotFilePath))
        } catch {
            // File write failed, snapshot not saved (non-critical)
        }
    }


    // MARK: - Cache Management

    /// Clean expired registrations (called automatically before snapshots)
    public func cleanExpiredRegistrations() {
        let before = viewRegistry.count
        viewRegistry = viewRegistry.filter { _, registration in
            !registration.isExpired
        }
        let removed = before - viewRegistry.count
        if removed > 0 {
            logger.debug("Aware: Cleaned \(removed) expired view registrations")
        }
    }

    /// Clear all registrations for a specific session
    public func clearSession(_ sessionId: String) {
        let before = viewRegistry.count
        viewRegistry = viewRegistry.filter { _, registration in
            registration.sessionId != sessionId
        }

        // Also clear related state
        let viewIds = viewRegistry.keys
        stateRegistry = stateRegistry.filter { viewId, _ in
            viewIds.contains(viewId)
        }
        parentChildMap = parentChildMap.filter { childId, parentId in
            viewIds.contains(childId) && viewIds.contains(parentId)
        }

        let removed = before - viewRegistry.count
        logger.info("Aware: Cleared session '\(sessionId)' - removed \(removed) registrations")
    }

    /// Clear all registrations for a specific project
    public func clearProject(_ projectId: String) {
        let before = viewRegistry.count
        viewRegistry = viewRegistry.filter { _, registration in
            registration.projectId != projectId
        }

        // Also clear related state
        let viewIds = viewRegistry.keys
        stateRegistry = stateRegistry.filter { viewId, _ in
            viewIds.contains(viewId)
        }
        parentChildMap = parentChildMap.filter { childId, parentId in
            viewIds.contains(childId) && viewIds.contains(parentId)
        }

        let removed = before - viewRegistry.count
        logger.info("Aware: Cleared project '\(projectId)' - removed \(removed) registrations")
    }

    /// Enforce size limit using LRU eviction
    internal func enforceSizeLimit() {
        guard viewRegistry.count > maxRegistrations else { return }

        let sorted = viewRegistry.sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }
        let toKeep = sorted.suffix(maxRegistrations)

        var newRegistry: [String: AwareViewRegistration] = [:]
        for (key, value) in toKeep {
            newRegistry[key] = value
        }
        viewRegistry = newRegistry

        logger.warning("Aware: Registry size limit enforced - evicted \(sorted.count - self.maxRegistrations) least recently used views")
    }

    /// Clear all registered views
    public func reset() {
        viewRegistry.removeAll()
        stateRegistry.removeAll()
        parentChildMap.removeAll()
        gestureCallbacks.removeAll()
        parameterizedGestureCallbacks.removeAll()
        textBindings.removeAll()
        actionCallbacks.removeAll()
        propStateBindings.removeAll()
        stalenessWarnings.removeAll()
        identityRegistry.removeAll()
        pendingIdentityChecks.removeAll()
        registryVersion = 0
        logger.info("Aware: Full reset completed")
    }
}

