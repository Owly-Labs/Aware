//
//  AwareFrameModifier.swift
//  AwareiOS
//
//  Frame position tracking modifier for layout testing.
//  Provides view frame tracking with throttled updates.
//

#if os(iOS)
import SwiftUI
import AwareCore

// MARK: - Frame Tracking Modifier

public extension View {
    /// Track view frame position with throttled updates
    /// - Parameters:
    ///   - id: View identifier
    ///   - coordinateSpace: Coordinate space for frame measurement (default: .global)
    ///   - onChange: Optional callback when frame changes
    /// - Returns: Modified view with frame tracking
    func awareFrame(
        _ id: String,
        coordinateSpace: CoordinateSpace = .global,
        onChange: ((CGRect) -> Void)? = nil
    ) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: FramePreferenceKey.self,
                        value: FrameData(id: id, frame: geometry.frame(in: coordinateSpace))
                    )
            }
        )
        .onPreferenceChange(FramePreferenceKey.self) { frameData in
            guard let frameData = frameData else { return }

            let capturedId = frameData.id
            let capturedFrame = frameData.frame

            Task { @MainActor in
                // Update frame in Aware service with throttling
                await AwareFrameTracker.shared.updateFrame(capturedId, frame: capturedFrame)
                onChange?(capturedFrame)
            }
        }
    }
}

// MARK: - Frame Data

private struct FrameData: Equatable {
    let id: String
    let frame: CGRect
}

// MARK: - Frame Preference Key

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: FrameData?

    static func reduce(value: inout FrameData?, nextValue: () -> FrameData?) {
        value = nextValue() ?? value
    }
}

// MARK: - Frame Tracker

/// Throttled frame update tracker
@MainActor
public final class AwareFrameTracker {
    public static let shared = AwareFrameTracker()

    private var frameUpdateThrottle: [String: Date] = [:]
    private let frameUpdateInterval: TimeInterval = 0.1  // 100ms

    private init() {}

    /// Update frame with throttling to prevent excessive updates
    /// - Parameters:
    ///   - id: View identifier
    ///   - frame: New frame value
    public func updateFrame(_ id: String, frame: CGRect) async {
        // Throttle updates
        let now = Date()
        if let lastUpdate = frameUpdateThrottle[id],
           now.timeIntervalSince(lastUpdate) < frameUpdateInterval {
            return
        }

        frameUpdateThrottle[id] = now

        // Store frame as state in Aware service
        await Aware.shared.registerState(id, key: "frame.x", value: String(format: "%.2f", frame.origin.x))
        await Aware.shared.registerState(id, key: "frame.y", value: String(format: "%.2f", frame.origin.y))
        await Aware.shared.registerState(id, key: "frame.width", value: String(format: "%.2f", frame.width))
        await Aware.shared.registerState(id, key: "frame.height", value: String(format: "%.2f", frame.height))

        AwareLog.modifiers.debug("Updated frame for '\(id)': \(frame)")
    }

    /// Get stored frame for a view
    /// - Parameter viewId: View identifier
    /// - Returns: Reconstructed CGRect from stored state, or nil if not found
    public func getFrame(_ viewId: String) async -> CGRect? {
        guard
            let xStr = await Aware.shared.getStateString(viewId, key: "frame.x"),
            let yStr = await Aware.shared.getStateString(viewId, key: "frame.y"),
            let widthStr = await Aware.shared.getStateString(viewId, key: "frame.width"),
            let heightStr = await Aware.shared.getStateString(viewId, key: "frame.height"),
            let x = Double(xStr),
            let y = Double(yStr),
            let width = Double(widthStr),
            let height = Double(heightStr)
        else {
            return nil
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }
}

#endif // os(iOS)
