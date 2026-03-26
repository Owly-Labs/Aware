import SwiftUI

/// Property wrapper that automatically logs state changes
///
/// Usage:
/// ```swift
/// struct MyView: View {
///     @TrackedState("selectedTab") var selectedTab: Tab = .home
///
///     var body: some View {
///         TabView(selection: $selectedTab) { ... }
///     }
/// }
/// ```
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
@propertyWrapper
public struct TrackedState<Value: Equatable>: DynamicProperty {
    @State private var storage: Value
    private let name: String
    private let viewName: String?

    public init(wrappedValue: Value, _ name: String, in viewName: String? = nil) {
        self._storage = State(wrappedValue: wrappedValue)
        self.name = name
        self.viewName = viewName
    }

    public var wrappedValue: Value {
        get { storage }
        nonmutating set {
            let oldValue = storage
            storage = newValue
            if oldValue != newValue {
                var metadata: [String: String] = [
                    "property": name,
                    "from": String(describing: oldValue),
                    "to": String(describing: newValue)
                ]
                if let view = viewName {
                    metadata["view"] = view
                }
                SwiftAware.logger.trace("🔄 stateChanged: \(name)", metadata: metadata)
            }
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

/// Observable state change tracking for @Observable classes
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
public actor StateChangeTracker {
    public static let shared = StateChangeTracker()

    private var trackedObjects: Set<ObjectIdentifier> = []

    /// Track changes to an @Observable object
    ///
    /// - Parameters:
    ///   - object: The observable object to track
    ///   - name: Name for logging purposes
    public func track<T: AnyObject>(_ object: T, name: String) {
        let id = ObjectIdentifier(object)
        guard !trackedObjects.contains(id) else { return }
        trackedObjects.insert(id)

        SwiftAware.logger.trace("🔗 Tracking object: \(name)", metadata: ["type": String(describing: type(of: object))])
    }

    /// Log a state change manually
    ///
    /// - Parameters:
    ///   - viewName: Name of the view/object
    ///   - property: Name of the property that changed
    ///   - from: Old value
    ///   - to: New value
    public func logChange(
        _ viewName: String,
        property: String,
        from: String,
        to: String
    ) {
        SwiftAware.logger.trace("🔄 stateChanged: \(property)", metadata: [
            "view": viewName,
            "from": from,
            "to": to
        ])
    }
}
