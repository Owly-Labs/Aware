import SwiftUI

/// Automatic view lifecycle tracking modifier
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         Text("Hello")
///             .trackLifecycle("MyView")
///     }
/// }
/// ```
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
public struct ViewLifecycleTracker: ViewModifier {
    let viewName: String
    let properties: [String: String]

    @State private var appearedAt: Date?

    public init(viewName: String, properties: [String: String] = [:]) {
        self.viewName = viewName
        self.properties = properties
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                appearedAt = Date()
                var metadata = properties
                metadata["event"] = "appeared"
                GhostUI.logger.trace("📱 \(viewName)", metadata: metadata)
            }
            .onDisappear {
                var metadata = properties
                metadata["event"] = "disappeared"
                if let start = appearedAt {
                    let duration = Date().timeIntervalSince(start)
                    metadata["duration_ms"] = "\(Int(duration * 1000))"
                }
                GhostUI.logger.trace("👋 \(viewName)", metadata: metadata)
            }
    }
}

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
public extension View {
    /// Track view lifecycle (appear/disappear) automatically
    ///
    /// - Parameters:
    ///   - name: Optional custom name for the view. If nil, uses the type name.
    ///   - properties: Additional metadata to include in logs
    /// - Returns: Modified view with lifecycle tracking
    func trackLifecycle(_ name: String? = nil, properties: [String: String] = [:]) -> some View {
        let viewName = name ?? String(describing: type(of: self))
        return modifier(ViewLifecycleTracker(viewName: viewName, properties: properties))
    }
}
