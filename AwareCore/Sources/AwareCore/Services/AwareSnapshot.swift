//
//  AwareSnapshot.swift
//  Breathe
//
//  Snapshot generation and tree building methods extracted from AwareService.swift
//  Phase 3.2 Architecture Refactoring
//

import SwiftUI

extension Aware {

    // MARK: - Snapshot Generation

    /// Generate full UI snapshot (defaults to .compact for LLM optimization)
    public func captureSnapshot(
        format: AwareSnapshotFormat = .compact,
        includeHidden: Bool = false,
        maxDepth: Int = 10,
        compression: CompressionStrategy = .basic,
        projectId: String? = nil,
        sessionId: String? = nil,
        includeExpired: Bool = false
    ) -> AwareSnapshotResult {
        // Clean expired registrations before snapshot
        if !includeExpired {
            cleanExpiredRegistrations()
        }

        // Input validation
        guard maxDepth > 0 && maxDepth <= 50 else {
            AwareError.invalidConfiguration(reason: "Invalid maxDepth: \(maxDepth) (must be 1-50)", key: "maxDepth").log()
            return AwareSnapshotResult(
                format: format,
                content: "Error: Invalid maxDepth parameter",
                viewCount: 0
            )
        }

        // Filter by context (projectId/sessionId)
        var filteredRegistry = viewRegistry
        if let projectId = projectId {
            filteredRegistry = filteredRegistry.filter { $0.value.projectId == projectId }
        }
        if let sessionId = sessionId {
            filteredRegistry = filteredRegistry.filter { $0.value.sessionId == sessionId }
        }

        // Filter by visibility
        let visibleViews = includeHidden
            ? filteredRegistry
            : filteredRegistry.filter { $0.value.snapshot.isVisible }

        // Build tree structure
        let rootNodes = buildViewTree(from: visibleViews, maxDepth: maxDepth)

        // Check cache first
        let cacheKey = "\(format.rawValue)-\(includeHidden)-\(maxDepth)-\(compression)-v\(registryVersion)"
        if let cachedContent = AwareCache.shared.getCachedSnapshot(cacheKey) {
            return AwareSnapshotResult(
                format: format,
                content: cachedContent,
                viewCount: visibleViews.count
            )
        }

        // Format output
        let renderer = AwareSnapshotRenderer(visibleViewCount: visibleViews.count)
        let uncompressedContent: String
        switch format {
        case .text:
            uncompressedContent = renderer.renderAsText(rootNodes)
        case .json:
            uncompressedContent = renderer.renderAsJSON(rootNodes)
        case .markdown:
            uncompressedContent = renderer.renderAsMarkdown(rootNodes)
        case .compact:
            uncompressedContent = renderer.renderAsCompact(rootNodes)
        }

        // Apply compression
        let content = AwareCompressionEngine.shared.compress(
            content: uncompressedContent,
            format: format,
            strategy: compression
        )

        // Cache the result
        AwareCache.shared.cacheSnapshot(cacheKey, content: content)

        return AwareSnapshotResult(
            format: format,
            content: content,
            viewCount: visibleViews.count
        )
    }

    // MARK: - Snapshot Convenience Methods

    /// Get compact snapshot (LLM-optimized, ~100-120 tokens)
    public func snapshotCompact(includeHidden: Bool = false, maxDepth: Int = 10, compression: CompressionStrategy = .basic) -> AwareSnapshotResult {
        captureSnapshot(format: .compact, includeHidden: includeHidden, maxDepth: maxDepth, compression: compression)
    }

    /// Alias for snapshotCompact - semantic clarity for LLM testing contexts
    public func snapshotForLLM(includeHidden: Bool = false, maxDepth: Int = 10, compression: CompressionStrategy = .basic) -> AwareSnapshotResult {
        snapshotCompact(includeHidden: includeHidden, maxDepth: maxDepth, compression: compression)
    }

    /// Get human-readable snapshot (text format, ~200-300 tokens)
    public func snapshotHumanReadable(includeHidden: Bool = false, maxDepth: Int = 10, compression: CompressionStrategy = .basic) -> AwareSnapshotResult {
        captureSnapshot(format: .text, includeHidden: includeHidden, maxDepth: maxDepth, compression: compression)
    }

    /// Alias for snapshotHumanReadable - semantic clarity for debugging
    public func snapshotForDebug(includeHidden: Bool = false, maxDepth: Int = 10, compression: CompressionStrategy = .basic) -> AwareSnapshotResult {
        snapshotHumanReadable(includeHidden: includeHidden, maxDepth: maxDepth, compression: compression)
    }

    /// Query specific view by ID
    public func describeView(_ viewId: String) -> AwareViewDescription? {
        guard let registration = viewRegistry[viewId] else { return nil }
        let snapshot = registration.snapshot

        return AwareViewDescription(
            id: viewId,
            label: snapshot.label,
            frame: snapshot.frame,
            visual: snapshot.visual,
            state: stateRegistry[viewId],
            isVisible: snapshot.isVisible,
            childCount: snapshot.childIds.count,
            animation: snapshot.animation,
            action: snapshot.action,
            behavior: snapshot.behavior
        )
    }

    /// Get all registered view IDs
    public var registeredViewIds: [String] {
        Array(viewRegistry.keys).sorted()
    }

    /// Get visible view count
    public var visibleViewCount: Int {
        viewRegistry.values.filter { $0.snapshot.isVisible }.count
    }

    // MARK: - Tree Building

    private func buildViewTree(from views: [String: AwareViewRegistration], maxDepth: Int) -> [AwareViewNode] {
        // Find root nodes (no parent or parent not in views)
        let rootIds = views.keys.filter { id in
            guard let registration = views[id] else { return false }
            let snapshot = registration.snapshot
            if let parentId = snapshot.parentId {
                return views[parentId] == nil
            }
            return true
        }

        return rootIds.sorted().compactMap { id in
            buildNode(id: id, views: views, depth: 0, maxDepth: maxDepth)
        }
    }

    private func buildNode(id: String, views: [String: AwareViewRegistration], depth: Int, maxDepth: Int) -> AwareViewNode? {
        guard depth < maxDepth, let registration = views[id] else { return nil }
        let snapshot = registration.snapshot

        let children = snapshot.childIds.sorted().compactMap { childId in
            buildNode(id: childId, views: views, depth: depth + 1, maxDepth: maxDepth)
        }

        return AwareViewNode(
            id: id,
            label: snapshot.label,
            frame: snapshot.frame,
            visual: snapshot.visual,
            state: stateRegistry[id],
            children: children,
            animation: snapshot.animation,
            action: snapshot.action,
            behavior: snapshot.behavior
        )
    }

    // MARK: - Reset
}
