//
//  AwareRegistration.swift
//  Breathe
//
//  View registration and metadata methods extracted from AwareService.swift
//  Phase 3.2 Architecture Refactoring
//

import SwiftUI

extension Aware {

    // MARK: - iOS Gesture Registration

    /// Register a gesture callback for a view
    public func registerGesture(_ viewId: String, type: AwareGestureType, callback: @escaping AwareGestureCallback) {
        if gestureCallbacks[viewId] == nil {
            gestureCallbacks[viewId] = [:]
        }
        gestureCallbacks[viewId]?[type] = callback
    }

    /// Register a parameterized gesture callback
    public func registerParameterizedGesture(_ viewId: String, type: AwareGestureType, callback: @escaping AwareParameterizedGestureCallback) {
        if parameterizedGestureCallbacks[viewId] == nil {
            parameterizedGestureCallbacks[viewId] = [:]
        }
        parameterizedGestureCallbacks[viewId]?[type] = callback
    }

    /// Unregister all gestures for a view
    public func unregisterGestures(_ viewId: String) {
        gestureCallbacks.removeValue(forKey: viewId)
        parameterizedGestureCallbacks.removeValue(forKey: viewId)
    }

    /// Check if a gesture is registered for a view
    public func hasGesture(_ viewId: String, type: AwareGestureType) -> Bool {
        gestureCallbacks[viewId]?[type] != nil || parameterizedGestureCallbacks[viewId]?[type] != nil
    }

    /// List registered gestures for a view
    public func registeredGestures(_ viewId: String) -> [AwareGestureType] {
        var result: Set<AwareGestureType> = []
        if let simple = gestureCallbacks[viewId] {
            result.formUnion(simple.keys)
        }
        if let parameterized = parameterizedGestureCallbacks[viewId] {
            result.formUnion(parameterized.keys)
        }
        return Array(result)
    }

    // MARK: - Text Binding Registration

    /// Register a text binding for direct LLM text manipulation
    public func registerTextBinding(_ viewId: String, binding: AwareTextBinding) {
        textBindings[viewId] = binding
    }

    /// Unregister text binding
    public func unregisterTextBinding(_ viewId: String) {
        textBindings.removeValue(forKey: viewId)
    }

    /// Check if a text binding exists for a view
    public func hasTextBinding(_ viewId: String) -> Bool {
        textBindings[viewId] != nil
    }

    // MARK: - Registration

    /// Register a view as visible with session/project context
    public func registerView(
        _ id: String,
        label: String? = nil,
        isContainer: Bool = false,
        parentId: String? = nil,
        projectId: String? = nil,
        sessionId: String? = nil,
        ttl: TimeInterval? = nil
    ) {
        // Input validation
        guard !id.isEmpty else {
            AwareError.invalidViewId(id).log()
            return
        }

        if let existing = viewRegistry[id], existing.snapshot.label != label {
            AwareError.viewAlreadyExists(viewId: id, existingLabel: existing.snapshot.label, newLabel: label).log()
            return
        }

        if let parentId = parentId, viewRegistry[parentId] == nil {
            AwareError.parentViewNotFound(parentId: parentId, childId: id).log()
            return
        }

        // Use default TTL if not specified
        let effectiveTTL = ttl ?? defaultTTL

        if viewRegistry[id] == nil {
            // Create new registration
            let snapshot = AwareViewSnapshot(
                id: id,
                label: label,
                isContainer: isContainer,
                parentId: parentId
            )
            viewRegistry[id] = AwareViewRegistration(
                snapshot: snapshot,
                projectId: projectId,
                sessionId: sessionId,
                ttl: effectiveTTL
            )
        } else {
            // Update existing registration
            var existing = viewRegistry[id]!
            var updatedSnapshot = existing.snapshot
            updatedSnapshot.isVisible = true
            if let label = label { updatedSnapshot.label = label }
            if let parentId = parentId { updatedSnapshot.parentId = parentId }

            // Create new registration with updated snapshot but preserve context
            viewRegistry[id] = AwareViewRegistration(
                snapshot: updatedSnapshot,
                projectId: existing.projectId,
                sessionId: existing.sessionId,
                ttl: effectiveTTL
            )
        }

        // Add to parent's children (deduplicated)
        if let parentId = parentId {
            parentChildMap[id] = parentId
            if viewRegistry[parentId]?.snapshot.childIds.contains(id) == false {
                var parentReg = viewRegistry[parentId]!
                var parentSnapshot = parentReg.snapshot
                parentSnapshot.childIds.append(id)
                viewRegistry[parentId] = AwareViewRegistration(
                    snapshot: parentSnapshot,
                    projectId: parentReg.projectId,
                    sessionId: parentReg.sessionId,
                    ttl: effectiveTTL
                )
            }
        }

        // Enforce size limit
        enforceSizeLimit()

        registryVersion += 1
        scheduleSnapshotWrite()
    }

    /// Unregister a view (mark as not visible)
    public func unregisterView(_ id: String) {
        guard var registration = viewRegistry[id] else { return }
        var snapshot = registration.snapshot
        snapshot.isVisible = false
        viewRegistry[id] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        registryVersion += 1
        scheduleSnapshotWrite()
    }

    /// Update view frame
    public func updateFrame(_ id: String, frame: CGRect) {
        guard var registration = viewRegistry[id] else { return }
        var snapshot = registration.snapshot
        snapshot.frame = frame
        viewRegistry[id] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Update visual properties
    public func updateVisual(_ id: String, visual: AwareSnapshot) {
        guard var registration = viewRegistry[id] else { return }
        var snapshot = registration.snapshot
        snapshot.visual = visual
        viewRegistry[id] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Update view properties
    public func updateView(
        _ id: String,
        frame: CGRect? = nil,
        visual: AwareSnapshot? = nil
    ) {
        guard var registration = viewRegistry[id] else { return }
        var snapshot = registration.snapshot

        if let frame = frame {
            snapshot.frame = frame
        }
        if let visual = visual {
            snapshot.visual = visual
        }

        // Recreate registration with updated snapshot
        viewRegistry[id] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Register state value
    public func registerState(_ viewId: String, key: String, value: String) {
        // Input validation
        guard viewRegistry[viewId] != nil else {
            AwareError.stateNotFound(viewId: viewId, key: key).log()
            return
        }

        guard !key.isEmpty else {
            AwareError.stateRegistrationFailed(reason: "Empty state key", viewId: viewId, key: key).log()
            return
        }

        if stateRegistry[viewId] == nil {
            stateRegistry[viewId] = [:]
        }
        stateRegistry[viewId]?[key] = value
        registryVersion += 1
        scheduleSnapshotWrite()
    }

    /// Clear state for a view
    public func clearState(_ viewId: String) {
        stateRegistry[viewId] = nil
        scheduleSnapshotWrite()
    }

    /// Get current state value for a view
    public func getStateValue(_ viewId: String, key: String) -> String? {
        stateRegistry[viewId]?[key]
    }

    /// Check if state matches expected value
    public func stateMatches(_ viewId: String, key: String, value: String) -> Bool {
        stateRegistry[viewId]?[key] == value
    }

    // MARK: - Extended Metadata Registration

    /// Register animation state for a view
    public func registerAnimation(_ viewId: String, animation: AwareAnimationState) {
        guard var registration = viewRegistry[viewId] else { return }
        var snapshot = registration.snapshot
        snapshot.animation = animation
        viewRegistry[viewId] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Clear animation state
    public func clearAnimation(_ viewId: String) {
        guard var registration = viewRegistry[viewId] else { return }
        var snapshot = registration.snapshot
        snapshot.animation = nil
        viewRegistry[viewId] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Register action metadata for a button/interactive element
    public func registerAction(_ viewId: String, action: AwareActionMetadata) {
        guard var registration = viewRegistry[viewId] else { return }
        var snapshot = registration.snapshot
        snapshot.action = action
        viewRegistry[viewId] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Register behavior metadata (data source, validation, etc.)
    public func registerBehavior(_ viewId: String, behavior: AwareBehaviorMetadata) {
        guard var registration = viewRegistry[viewId] else { return }
        var snapshot = registration.snapshot
        snapshot.behavior = behavior
        viewRegistry[viewId] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Update scroll state for a scrollable view
    public func updateScrollState(
        _ viewId: String,
        offset: CGPoint,
        contentSize: CGSize,
        visibleRect: CGRect
    ) {
        guard var registration = viewRegistry[viewId] else { return }
        var snapshot = registration.snapshot
        let visual = AwareSnapshot(
            frame: snapshot.visual?.frame,
            backgroundColor: snapshot.visual?.backgroundColor,
            foregroundColor: snapshot.visual?.foregroundColor,
            font: snapshot.visual?.font,
            text: snapshot.visual?.text,
            opacity: snapshot.visual?.opacity ?? 1.0,
            isHidden: snapshot.visual?.isHidden ?? false,
            isTextTruncated: snapshot.visual?.isTextTruncated,
            intrinsicSize: snapshot.visual?.intrinsicSize,
            lineCount: snapshot.visual?.lineCount,
            maxLines: snapshot.visual?.maxLines,
            isFocused: snapshot.visual?.isFocused,
            isHovered: snapshot.visual?.isHovered,
            scrollOffset: offset,
            contentSize: contentSize,
            visibleRect: visibleRect
        )
        snapshot.visual = visual
        viewRegistry[viewId] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Update focus state for a view
    public func updateFocusState(_ viewId: String, isFocused: Bool, isHovered: Bool = false) {
        guard var registration = viewRegistry[viewId] else { return }
        var snapshot = registration.snapshot
        let visual = AwareSnapshot(
            frame: snapshot.visual?.frame,
            backgroundColor: snapshot.visual?.backgroundColor,
            foregroundColor: snapshot.visual?.foregroundColor,
            font: snapshot.visual?.font,
            text: snapshot.visual?.text,
            opacity: snapshot.visual?.opacity ?? 1.0,
            isHidden: snapshot.visual?.isHidden ?? false,
            isTextTruncated: snapshot.visual?.isTextTruncated,
            intrinsicSize: snapshot.visual?.intrinsicSize,
            lineCount: snapshot.visual?.lineCount,
            maxLines: snapshot.visual?.maxLines,
            isFocused: isFocused,
            isHovered: isHovered,
            scrollOffset: snapshot.visual?.scrollOffset,
            contentSize: snapshot.visual?.contentSize,
            visibleRect: snapshot.visual?.visibleRect
        )
        snapshot.visual = visual
        viewRegistry[viewId] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

    /// Update text overflow detection
    public func updateTextOverflow(
        _ viewId: String,
        isTruncated: Bool,
        intrinsicSize: CGSize,
        lineCount: Int,
        maxLines: Int
    ) {
        guard var registration = viewRegistry[viewId] else { return }
        var snapshot = registration.snapshot
        let visual = AwareSnapshot(
            frame: snapshot.visual?.frame,
            backgroundColor: snapshot.visual?.backgroundColor,
            foregroundColor: snapshot.visual?.foregroundColor,
            font: snapshot.visual?.font,
            text: snapshot.visual?.text,
            opacity: snapshot.visual?.opacity ?? 1.0,
            isHidden: snapshot.visual?.isHidden ?? false,
            isTextTruncated: isTruncated,
            intrinsicSize: intrinsicSize,
            lineCount: lineCount,
            maxLines: maxLines,
            isFocused: snapshot.visual?.isFocused,
            isHovered: snapshot.visual?.isHovered,
            scrollOffset: snapshot.visual?.scrollOffset,
            contentSize: snapshot.visual?.contentSize,
            visibleRect: snapshot.visual?.visibleRect
        )
        snapshot.visual = visual
        viewRegistry[viewId] = AwareViewRegistration(
            snapshot: snapshot,
            projectId: registration.projectId,
            sessionId: registration.sessionId,
            ttl: defaultTTL
        )
        scheduleSnapshotWrite()
    }

}
