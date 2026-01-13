//
//  AwareMetadataEnhanced.swift
//  AwareCore
//
//  Enhanced metadata fields for better LLM decision-making.
//  Extends action and behavior metadata with richer semantic information.
//

import Foundation

// MARK: - Enhanced Action Metadata

/// Enhanced action metadata for better LLM understanding
///
/// **Token Cost:** ~40-60 tokens per action (vs 30-40 for basic)
/// **LLM Guidance:** Use for complex actions requiring decision-making
public struct AwareActionMetadataV2: Codable, Sendable {
    // MARK: - Basic Fields (from V1)

    public let actionDescription: String
    public let actionType: ActionType
    public let isEnabled: Bool
    public let isDestructive: Bool
    public let requiresConfirmation: Bool
    public let shortcutKey: String?
    public let apiEndpoint: String?
    public let sideEffects: [String]?

    // MARK: - Enhanced Fields (V2)

    /// Expected duration in milliseconds (helps LLMs set timeouts)
    public let expectedDurationMs: Int?

    /// Conditions that must be true for action to execute
    /// Example: ["user.isAuthenticated", "document.hasUnsavedChanges"]
    public let preconditions: [String]?

    /// State changes that result from this action
    /// Example: ["document.isDirty = false", "syncStatus = syncing"]
    public let postconditions: [String]?

    /// Related actions that might be needed before/after
    /// Example: ["validate-form", "show-confirmation"]
    public let relatedActions: [String]?

    /// Success indicators for verification
    /// Example: ["status code 200", "success toast shown", "modal dismissed"]
    public let successIndicators: [String]?

    /// Known failure modes and their causes
    /// Example: ["Network timeout", "Invalid credentials", "Quota exceeded"]
    public let failureModes: [String]?

    /// Undo/rollback action if this action can be undone
    /// Example: "undo-delete", "restore-previous-state"
    public let undoAction: String?

    /// Cost/risk level for LLM decision-making
    public let riskLevel: RiskLevel

    /// User impact level
    public let impactLevel: ImpactLevel

    /// Whether this action can be safely retried on failure
    public let isIdempotent: Bool

    /// Maximum retry attempts if action fails
    public let maxRetries: Int?

    /// Telemetry/analytics event name
    public let analyticsEvent: String?

    /// Tags for categorization and search
    public let tags: [String]?

    // MARK: - Enums

    public enum ActionType: String, Codable, Sendable {
        case navigation
        case mutation
        case network
        case fileSystem
        case system
        case destructive
        case query
        case computation
        case unknown
    }

    public enum RiskLevel: String, Codable, Sendable {
        case low        // Read-only, safe operations
        case medium     // Modifies state but recoverable
        case high       // Destructive or irreversible
        case critical   // System-level or security-sensitive
    }

    public enum ImpactLevel: String, Codable, Sendable {
        case minimal    // Single view affected
        case moderate   // Multiple views affected
        case significant // App-wide state changed
        case major      // User data modified
    }

    // MARK: - Initializer

    public init(
        actionDescription: String,
        actionType: ActionType = .unknown,
        isEnabled: Bool = true,
        isDestructive: Bool = false,
        requiresConfirmation: Bool = false,
        shortcutKey: String? = nil,
        apiEndpoint: String? = nil,
        sideEffects: [String]? = nil,
        expectedDurationMs: Int? = nil,
        preconditions: [String]? = nil,
        postconditions: [String]? = nil,
        relatedActions: [String]? = nil,
        successIndicators: [String]? = nil,
        failureModes: [String]? = nil,
        undoAction: String? = nil,
        riskLevel: RiskLevel = .low,
        impactLevel: ImpactLevel = .minimal,
        isIdempotent: Bool = true,
        maxRetries: Int? = nil,
        analyticsEvent: String? = nil,
        tags: [String]? = nil
    ) {
        self.actionDescription = actionDescription
        self.actionType = actionType
        self.isEnabled = isEnabled
        self.isDestructive = isDestructive
        self.requiresConfirmation = requiresConfirmation
        self.shortcutKey = shortcutKey
        self.apiEndpoint = apiEndpoint
        self.sideEffects = sideEffects
        self.expectedDurationMs = expectedDurationMs
        self.preconditions = preconditions
        self.postconditions = postconditions
        self.relatedActions = relatedActions
        self.successIndicators = successIndicators
        self.failureModes = failureModes
        self.undoAction = undoAction
        self.riskLevel = riskLevel
        self.impactLevel = impactLevel
        self.isIdempotent = isIdempotent
        self.maxRetries = maxRetries
        self.analyticsEvent = analyticsEvent
        self.tags = tags
    }

    // MARK: - Helpers

    /// Compact representation for LLM consumption
    public var compactDescription: String {
        var parts = [actionDescription]

        if !isEnabled { parts.append("⚪️disabled") }
        if isDestructive { parts.append("🔴destructive") }
        if riskLevel == .high || riskLevel == .critical {
            parts.append("⚠️\(riskLevel.rawValue)-risk")
        }
        if let duration = expectedDurationMs {
            parts.append("⏱️\(duration)ms")
        }

        return parts.joined(separator: " ")
    }

    /// Whether LLM should ask for confirmation before executing
    public var shouldConfirmWithLLM: Bool {
        return isDestructive || requiresConfirmation || riskLevel == .critical
    }
}

// MARK: - Enhanced Behavior Metadata

/// Enhanced behavior metadata for data-bound views
///
/// **Token Cost:** ~50-70 tokens per behavior (vs 30-40 for basic)
/// **LLM Guidance:** Use for views with complex data flow
public struct AwareBehaviorMetadataV2: Codable, Sendable {
    // MARK: - Basic Fields (from V1)

    public let dataSource: String?
    public let refreshTrigger: String?
    public let cacheDuration: String?
    public let errorHandling: String?
    public let loadingBehavior: String?
    public let validationRules: [String]?
    public let boundModel: String?
    public let dependencies: [String]?

    // MARK: - Enhanced Fields (V2)

    /// Data flow direction
    public let dataFlow: DataFlow

    /// Expected data update frequency
    public let updateFrequency: UpdateFrequency?

    /// Pagination support details
    public let pagination: PaginationInfo?

    /// Filtering capabilities
    public let filterOptions: [FilterOption]?

    /// Sorting capabilities
    public let sortOptions: [SortOption]?

    /// Search capabilities
    public let searchConfig: SearchConfig?

    /// Offline support level
    public let offlineSupport: OfflineSupport

    /// Data synchronization strategy
    public let syncStrategy: SyncStrategy?

    /// Conflict resolution approach
    public let conflictResolution: ConflictResolution?

    /// Data transformation pipeline
    /// Example: ["fetch → parse → validate → transform → cache"]
    public let transformationPipeline: [String]?

    /// Optimistic update support
    public let supportsOptimisticUpdates: Bool

    /// Real-time update mechanism
    /// Example: "WebSocket", "Server-Sent Events", "Polling"
    public let realtimeUpdate: String?

    /// Data consistency requirements
    public let consistencyLevel: ConsistencyLevel

    /// Performance SLAs
    public let performanceSLA: PerformanceSLA?

    // MARK: - Enums

    public enum DataFlow: String, Codable, Sendable {
        case readonly       // View displays data only
        case writeonly      // View submits data only
        case bidirectional  // View reads and writes
        case stream         // Continuous data stream
    }

    public enum UpdateFrequency: String, Codable, Sendable {
        case realtime      // Milliseconds
        case high          // Seconds
        case medium        // Minutes
        case low           // Hours
        case onDemand      // User-triggered
    }

    public enum OfflineSupport: String, Codable, Sendable {
        case none          // Requires network
        case readonly      // Can view cached data
        case full          // Can read and write offline
    }

    public enum SyncStrategy: String, Codable, Sendable {
        case immediate     // Sync on every change
        case batched       // Sync in batches
        case periodic      // Sync on timer
        case manual        // User-triggered sync
    }

    public enum ConflictResolution: String, Codable, Sendable {
        case serverWins    // Server data takes precedence
        case clientWins    // Client data takes precedence
        case lastWriteWins // Most recent change wins
        case mergeStrategy // Custom merge logic
        case userResolves  // Prompt user to choose
    }

    public enum ConsistencyLevel: String, Codable, Sendable {
        case eventual      // Eventually consistent
        case strong        // Strongly consistent
        case causal        // Causal consistency
    }

    // MARK: - Supporting Types

    public struct PaginationInfo: Codable, Sendable {
        public let pageSize: Int
        public let supportsCursor: Bool
        public let supportsOffset: Bool

        public init(pageSize: Int, supportsCursor: Bool = true, supportsOffset: Bool = true) {
            self.pageSize = pageSize
            self.supportsCursor = supportsCursor
            self.supportsOffset = supportsOffset
        }
    }

    public struct FilterOption: Codable, Sendable {
        public let field: String
        public let operators: [String]  // ["equals", "contains", "greaterThan"]
        public let dataType: String     // "string", "number", "date", "boolean"

        public init(field: String, operators: [String], dataType: String) {
            self.field = field
            self.operators = operators
            self.dataType = dataType
        }
    }

    public struct SortOption: Codable, Sendable {
        public let field: String
        public let defaultDirection: String  // "asc" or "desc"
        public let isDefault: Bool

        public init(field: String, defaultDirection: String = "asc", isDefault: Bool = false) {
            self.field = field
            self.defaultDirection = defaultDirection
            self.isDefault = isDefault
        }
    }

    public struct SearchConfig: Codable, Sendable {
        public let searchableFields: [String]
        public let minQueryLength: Int
        public let debounceMs: Int
        public let supportsWildcard: Bool

        public init(
            searchableFields: [String],
            minQueryLength: Int = 3,
            debounceMs: Int = 300,
            supportsWildcard: Bool = true
        ) {
            self.searchableFields = searchableFields
            self.minQueryLength = minQueryLength
            self.debounceMs = debounceMs
            self.supportsWildcard = supportsWildcard
        }
    }

    public struct PerformanceSLA: Codable, Sendable {
        public let maxLoadTimeMs: Int
        public let maxRenderTimeMs: Int
        public let targetFPS: Int?

        public init(maxLoadTimeMs: Int, maxRenderTimeMs: Int, targetFPS: Int? = nil) {
            self.maxLoadTimeMs = maxLoadTimeMs
            self.maxRenderTimeMs = maxRenderTimeMs
            self.targetFPS = targetFPS
        }
    }

    // MARK: - Initializer

    public init(
        dataSource: String? = nil,
        refreshTrigger: String? = nil,
        cacheDuration: String? = nil,
        errorHandling: String? = nil,
        loadingBehavior: String? = nil,
        validationRules: [String]? = nil,
        boundModel: String? = nil,
        dependencies: [String]? = nil,
        dataFlow: DataFlow = .bidirectional,
        updateFrequency: UpdateFrequency? = nil,
        pagination: PaginationInfo? = nil,
        filterOptions: [FilterOption]? = nil,
        sortOptions: [SortOption]? = nil,
        searchConfig: SearchConfig? = nil,
        offlineSupport: OfflineSupport = .none,
        syncStrategy: SyncStrategy? = nil,
        conflictResolution: ConflictResolution? = nil,
        transformationPipeline: [String]? = nil,
        supportsOptimisticUpdates: Bool = false,
        realtimeUpdate: String? = nil,
        consistencyLevel: ConsistencyLevel = .eventual,
        performanceSLA: PerformanceSLA? = nil
    ) {
        self.dataSource = dataSource
        self.refreshTrigger = refreshTrigger
        self.cacheDuration = cacheDuration
        self.errorHandling = errorHandling
        self.loadingBehavior = loadingBehavior
        self.validationRules = validationRules
        self.boundModel = boundModel
        self.dependencies = dependencies
        self.dataFlow = dataFlow
        self.updateFrequency = updateFrequency
        self.pagination = pagination
        self.filterOptions = filterOptions
        self.sortOptions = sortOptions
        self.searchConfig = searchConfig
        self.offlineSupport = offlineSupport
        self.syncStrategy = syncStrategy
        self.conflictResolution = conflictResolution
        self.transformationPipeline = transformationPipeline
        self.supportsOptimisticUpdates = supportsOptimisticUpdates
        self.realtimeUpdate = realtimeUpdate
        self.consistencyLevel = consistencyLevel
        self.performanceSLA = performanceSLA
    }

    // MARK: - Helpers

    /// Compact representation for LLM consumption
    public var compactDescription: String {
        var parts: [String] = []

        if let source = dataSource {
            parts.append("📦\(source)")
        }

        parts.append("🔄\(dataFlow.rawValue)")

        if offlineSupport != .none {
            parts.append("📴\(offlineSupport.rawValue)")
        }

        if let pagination = pagination {
            parts.append("📄\(pagination.pageSize)/page")
        }

        if supportsOptimisticUpdates {
            parts.append("⚡️optimistic")
        }

        return parts.joined(separator: " ")
    }
}

// MARK: - Metadata Integration

extension Aware {

    /// Register enhanced action metadata for a view
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use for complex actions requiring decision support
    @MainActor
    public func registerActionMetadataV2(_ viewId: String, metadata: AwareActionMetadataV2) {
        // Store in extended metadata registry (would need to add this storage)
        // For now, convert to V1 format for backward compatibility
        let v1Metadata = AwareActionMetadata(
            actionDescription: metadata.actionDescription,
            actionType: convertActionType(metadata.actionType),
            isEnabled: metadata.isEnabled,
            isDestructive: metadata.isDestructive,
            requiresConfirmation: metadata.requiresConfirmation,
            shortcutKey: metadata.shortcutKey,
            apiEndpoint: metadata.apiEndpoint,
            sideEffects: metadata.sideEffects
        )

        // Register using existing V1 method
        registerAction(viewId, action: v1Metadata)
    }

    /// Register enhanced behavior metadata for a view
    ///
    /// **Token Cost:** ~30 tokens per call
    /// **LLM Guidance:** Use for data-bound views with complex behavior
    @MainActor
    public func registerBehaviorMetadataV2(_ viewId: String, metadata: AwareBehaviorMetadataV2) {
        // Store in extended metadata registry
        // Convert to V1 format for backward compatibility
        let v1Metadata = AwareBehaviorMetadata(
            dataSource: metadata.dataSource,
            refreshTrigger: metadata.refreshTrigger,
            cacheDuration: metadata.cacheDuration,
            errorHandling: metadata.errorHandling,
            loadingBehavior: metadata.loadingBehavior,
            validationRules: metadata.validationRules,
            boundModel: metadata.boundModel,
            dependencies: metadata.dependencies
        )

        // Register using existing V1 method
        registerBehavior(viewId, behavior: v1Metadata)
    }

    // MARK: - Helper Methods

    private func convertActionType(_ type: AwareActionMetadataV2.ActionType) -> AwareActionMetadata.ActionType {
        switch type {
        case .navigation: return .navigation
        case .mutation: return .mutation
        case .network: return .network
        case .fileSystem: return .fileSystem
        case .system: return .system
        case .destructive: return .destructive
        case .query, .computation, .unknown: return .unknown
        }
    }
}
