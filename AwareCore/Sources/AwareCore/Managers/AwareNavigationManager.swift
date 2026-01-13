//
//  AwareNavigationManager.swift
//  Aware
//
//  Manages programmatic navigation control for iOS.
//  Enables LLM-controlled back navigation, modal dismissal, and routing.
//

import Foundation
import SwiftUI

// MARK: - AwareNavigationManager

/// Manages programmatic navigation for iOS
@MainActor
public final class AwareNavigationManager: ObservableObject {
    public static let shared = AwareNavigationManager()

    // MARK: - Published State

    /// Current navigation context (screen/view ID)
    @Published public private(set) var currentContext: String?

    /// Navigation stack depth for current context
    @Published public private(set) var stackDepth: Int = 0

    // MARK: - Private State

    /// Registered back navigation callbacks by context
    private var backCallbacks: [String: AwareGestureCallback] = [:]

    /// Registered dismiss callbacks for modal contexts
    private var dismissCallbacks: [String: AwareGestureCallback] = [:]

    /// NavigationPath bindings for programmatic navigation
    private var navigationPaths: [String: Binding<NavigationPath>] = [:]

    /// Context hierarchy (child -> parent mapping)
    private var contextParents: [String: String] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Context Management

    /// Set the current navigation context
    public func setContext(_ contextId: String, parent: String? = nil) {
        currentContext = contextId
        if let parent = parent {
            contextParents[contextId] = parent
        }
        updateStackDepth()
    }

    /// Clear current context (used when navigating away)
    public func clearCurrentContext() {
        currentContext = nil
        stackDepth = 0
    }

    // MARK: - Registration

    /// Register a back navigation callback for a context
    public func registerBack(_ contextId: String, callback: @escaping AwareGestureCallback) {
        backCallbacks[contextId] = callback
    }

    /// Register a dismiss callback for a modal context
    public func registerDismiss(_ contextId: String, callback: @escaping AwareGestureCallback) {
        dismissCallbacks[contextId] = callback
    }

    /// Register a NavigationPath binding for programmatic navigation
    public func registerNavigationPath(_ contextId: String, path: Binding<NavigationPath>) {
        navigationPaths[contextId] = path
        updateStackDepth()
    }

    /// Unregister all navigation for a context
    public func clearContext(_ contextId: String) {
        backCallbacks.removeValue(forKey: contextId)
        dismissCallbacks.removeValue(forKey: contextId)
        navigationPaths.removeValue(forKey: contextId)
        contextParents.removeValue(forKey: contextId)

        // Clear as current if it was
        if currentContext == contextId {
            currentContext = nil
            stackDepth = 0
        }
    }

    // MARK: - Navigation Actions

    /// Go back (uses registered callback or pops navigation path)
    /// - Returns: true if navigation was successful
    @discardableResult
    public func goBack() async -> Bool {
        guard let context = currentContext else {
            return false
        }

        // Try registered back callback first
        if let callback = backCallbacks[context] {
            await callback()
            return true
        }

        // Try navigation path pop
        if let pathBinding = navigationPaths[context], !pathBinding.wrappedValue.isEmpty {
            pathBinding.wrappedValue.removeLast()
            updateStackDepth()
            return true
        }

        // Try parent context's back action
        if let parentContext = contextParents[context] {
            currentContext = parentContext
            return await goBack()
        }

        return false
    }

    /// Dismiss the current modal
    /// - Returns: true if dismissal was successful
    @discardableResult
    public func dismiss() async -> Bool {
        guard let context = currentContext,
              let callback = dismissCallbacks[context] else {
            return false
        }

        await callback()
        return true
    }

    /// Navigate to a destination by posting a notification
    /// Apps should listen for .awareNavigationRequest to handle routing
    /// - Returns: true if request was posted
    @discardableResult
    public func navigate(to destination: String, in contextId: String? = nil) -> Bool {
        let context = contextId ?? currentContext
        guard let context = context else {
            return false
        }

        // Post notification for custom handling
        NotificationCenter.default.post(
            name: .awareNavigationRequest,
            object: nil,
            userInfo: [
                "context": context,
                "destination": destination,
            ]
        )

        return true
    }

    /// Pop to root of navigation stack
    @discardableResult
    public func popToRoot() -> Bool {
        guard let context = currentContext,
              let pathBinding = navigationPaths[context] else {
            return false
        }

        if pathBinding.wrappedValue.isEmpty {
            return false
        }

        // Clear the path
        pathBinding.wrappedValue = NavigationPath()
        updateStackDepth()
        return true
    }

    // MARK: - Query

    /// Check if back navigation is available
    public var canGoBack: Bool {
        guard let context = currentContext else { return false }

        // Check callback
        if backCallbacks[context] != nil { return true }

        // Check navigation path
        if let path = navigationPaths[context], !path.wrappedValue.isEmpty { return true }

        // Check parent
        if contextParents[context] != nil { return true }

        return false
    }

    /// Check if dismiss is available
    public var canDismiss: Bool {
        guard let context = currentContext else { return false }
        return dismissCallbacks[context] != nil
    }

    /// Get the context hierarchy
    public func getContextHierarchy() -> [String] {
        var hierarchy: [String] = []
        var current = currentContext

        while let ctx = current {
            hierarchy.insert(ctx, at: 0)
            current = contextParents[ctx]
        }

        return hierarchy
    }

    // MARK: - Private

    private func updateStackDepth() {
        guard let context = currentContext,
              let pathBinding = navigationPaths[context] else {
            stackDepth = 0
            return
        }

        stackDepth = pathBinding.wrappedValue.count
    }

    // MARK: - Reset

    /// Clear all navigation registrations
    public func reset() {
        currentContext = nil
        stackDepth = 0
        backCallbacks.removeAll()
        dismissCallbacks.removeAll()
        navigationPaths.removeAll()
        contextParents.removeAll()
    }
}
