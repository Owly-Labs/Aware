//
//  AwareFocusManager.swift
//  Aware
//
//  Manages programmatic focus control for iOS text fields and interactive elements.
//  Enables LLM-controlled keyboard focus and tab navigation.
//

import Foundation
import SwiftUI

// MARK: - AwareFocusManager

/// Manages programmatic focus control for iOS
@MainActor
public final class AwareFocusManager: ObservableObject {
    public static let shared = AwareFocusManager()

    // MARK: - Published State

    /// Currently focused view ID
    @Published public private(set) var focusedViewId: String?

    // MARK: - Private State

    /// Focus state bindings by view ID
    private var focusBindings: [String: Binding<Bool>] = [:]

    /// Focus order (tab order) by view ID
    private var focusOrder: [String] = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Registration

    /// Register a focus binding for a view
    /// - Parameters:
    ///   - viewId: The view identifier
    ///   - binding: The focus state binding
    ///   - order: Optional position in focus order (tab order)
    public func registerFocus(_ viewId: String, binding: Binding<Bool>, order: Int? = nil) {
        focusBindings[viewId] = binding

        // Update focus order
        if let order = order {
            // Remove if exists elsewhere
            focusOrder.removeAll { $0 == viewId }
            // Insert at specified position
            focusOrder.insert(viewId, at: min(order, focusOrder.count))
        } else if !focusOrder.contains(viewId) {
            focusOrder.append(viewId)
        }

        // Update focusedViewId if this binding is already focused
        if binding.wrappedValue && focusedViewId != viewId {
            focusedViewId = viewId
        }
    }

    /// Unregister focus binding when view disappears
    public func unregisterFocus(_ viewId: String) {
        focusBindings.removeValue(forKey: viewId)
        focusOrder.removeAll { $0 == viewId }

        // Clear focused view if it was this one
        if focusedViewId == viewId {
            focusedViewId = nil
        }
    }

    // MARK: - Focus Control

    /// Focus a specific view by ID
    /// - Returns: true if focus was successfully set
    @discardableResult
    public func focus(_ viewId: String) -> Bool {
        guard let binding = focusBindings[viewId] else {
            return false
        }

        // Blur current focus first
        if let current = focusedViewId, current != viewId {
            focusBindings[current]?.wrappedValue = false
        }

        // Set new focus
        binding.wrappedValue = true
        focusedViewId = viewId
        return true
    }

    /// Blur (unfocus) the currently focused view
    public func blur() {
        if let current = focusedViewId {
            focusBindings[current]?.wrappedValue = false
            focusedViewId = nil
        }
    }

    /// Focus the next view in tab order
    /// - Returns: true if next view was focused
    @discardableResult
    public func focusNext() -> Bool {
        guard let current = focusedViewId,
              let currentIndex = focusOrder.firstIndex(of: current) else {
            // No current focus - focus the first field
            if let first = focusOrder.first {
                return focus(first)
            }
            return false
        }

        // Try to focus next in order
        let nextIndex = currentIndex + 1
        if nextIndex < focusOrder.count {
            return focus(focusOrder[nextIndex])
        }

        // Wrap around to first
        if let first = focusOrder.first {
            return focus(first)
        }

        return false
    }

    /// Focus the previous view in tab order
    /// - Returns: true if previous view was focused
    @discardableResult
    public func focusPrevious() -> Bool {
        guard let current = focusedViewId,
              let currentIndex = focusOrder.firstIndex(of: current) else {
            // No current focus - focus the last field
            if let last = focusOrder.last {
                return focus(last)
            }
            return false
        }

        // Try to focus previous in order
        if currentIndex > 0 {
            return focus(focusOrder[currentIndex - 1])
        }

        // Wrap around to last
        if let last = focusOrder.last {
            return focus(last)
        }

        return false
    }

    // MARK: - Query

    /// Get list of focusable view IDs in tab order
    public var focusableViews: [String] {
        focusOrder
    }

    /// Check if a view is focusable
    public func isFocusable(_ viewId: String) -> Bool {
        focusBindings[viewId] != nil
    }

    /// Get the current focus index in tab order (-1 if none)
    public var currentFocusIndex: Int {
        guard let current = focusedViewId else { return -1 }
        return focusOrder.firstIndex(of: current) ?? -1
    }

    // MARK: - Reset

    /// Clear all focus registrations
    public func reset() {
        // Blur current focus
        blur()

        // Clear registrations
        focusBindings.removeAll()
        focusOrder.removeAll()
    }

    // MARK: - Internal

    /// Called when a focus binding changes externally
    func notifyFocusChanged(_ viewId: String, isFocused: Bool) {
        if isFocused {
            // Blur other views
            for (id, binding) in focusBindings where id != viewId {
                if binding.wrappedValue {
                    binding.wrappedValue = false
                }
            }
            focusedViewId = viewId
        } else if focusedViewId == viewId {
            focusedViewId = nil
        }
    }
}
