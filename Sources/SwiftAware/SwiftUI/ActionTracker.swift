import SwiftUI

/// A button that automatically logs when tapped
///
/// Usage:
/// ```swift
/// TrackedButton("Save") {
///     saveDocument()
/// } label: {
///     Text("Save")
/// }
/// ```
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
public struct TrackedButton<Label: View>: View {
    let actionName: String
    let viewName: String?
    let action: () -> Void
    let label: () -> Label

    public init(
        _ actionName: String,
        in viewName: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.actionName = actionName
        self.viewName = viewName
        self.action = action
        self.label = label
    }

    public var body: some View {
        Button(action: {
            var metadata: [String: String] = ["action": actionName]
            if let view = viewName {
                metadata["view"] = view
            }
            SwiftAware.logger.trace("👆 tapped: \(actionName)", metadata: metadata)
            action()
        }, label: label)
    }
}

/// String-label convenience initializer
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
public extension TrackedButton where Label == Text {
    init(
        _ actionName: String,
        in viewName: String? = nil,
        action: @escaping () -> Void
    ) {
        self.actionName = actionName
        self.viewName = viewName
        self.action = action
        self.label = { Text(actionName) }
    }
}

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
public extension View {
    /// Add tap tracking to any view
    ///
    /// - Parameters:
    ///   - name: Name for the tap action
    ///   - action: Closure to execute on tap
    /// - Returns: Modified view with tap tracking
    func trackTap(_ name: String, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            SwiftAware.logger.trace("👆 tapped: \(name)")
            action()
        }
    }

    /// Add tap tracking with async action
    ///
    /// - Parameters:
    ///   - name: Name for the tap action
    ///   - action: Async closure to execute on tap
    /// - Returns: Modified view with tap tracking
    func trackTap(_ name: String, action: @escaping () async -> Void) -> some View {
        self.onTapGesture {
            SwiftAware.logger.trace("👆 tapped: \(name)")
            Task { await action() }
        }
    }
}
