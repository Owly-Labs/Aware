// AwareTheme.swift
// SwiftAware Standards Module
//
// Centralized design tokens for consistent UI across SwiftAware-based apps.

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Aware Theme

/// Centralized design tokens for Swift and iOS apps.
public struct AwareTheme: Sendable {

    // MARK: - Colors

    /// Semantic color palette
    public struct Colors {
        /// Primary brand color
        #if canImport(SwiftUI)
        public static let primary = Color.blue
        public static let secondary = Color.gray
        #if os(macOS)
        public static let background = Color(nsColor: .windowBackgroundColor)
        public static let surface = Color(nsColor: .controlBackgroundColor)
        #else
        public static let background = Color(.systemBackground)
        public static let surface = Color(.secondarySystemBackground)
        #endif
        #endif

        /// Status colors
        #if canImport(SwiftUI)
        public static let success = Color.green
        public static let warning = Color.orange
        public static let error = Color.red
        public static let info = Color.blue
        #endif

        /// Text colors
        #if canImport(SwiftUI)
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        #if os(macOS)
        public static let textTertiary = Color(nsColor: .tertiaryLabelColor)
        #else
        public static let textTertiary = Color(.tertiaryLabel)
        #endif
        #endif

        /// Hex values for programmatic use
        public static let primaryHex = "#007AFF"
        public static let secondaryHex = "#8E8E93"
        public static let successHex = "#34C759"
        public static let warningHex = "#FF9500"
        public static let errorHex = "#FF3B30"
        public static let infoHex = "#5AC8FA"
    }

    // MARK: - Spacing

    /// Consistent spacing scale (4px base unit)
    public struct Spacing {
        /// 4pt - Extra small spacing
        public static let xs: CGFloat = 4

        /// 8pt - Small spacing
        public static let sm: CGFloat = 8

        /// 16pt - Medium spacing (default)
        public static let md: CGFloat = 16

        /// 24pt - Large spacing
        public static let lg: CGFloat = 24

        /// 32pt - Extra large spacing
        public static let xl: CGFloat = 32

        /// 48pt - 2x extra large spacing
        public static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    /// Consistent corner radius scale
    public struct CornerRadius {
        /// 4pt - Small radius for chips/tags
        public static let sm: CGFloat = 4

        /// 8pt - Medium radius for cards
        public static let md: CGFloat = 8

        /// 12pt - Large radius for modals
        public static let lg: CGFloat = 12

        /// 16pt - Extra large radius
        public static let xl: CGFloat = 16

        /// Fully rounded (use with height/2)
        public static let full: CGFloat = 9999
    }

    // MARK: - Typography

    /// Font sizes for consistent text hierarchy
    public struct Typography {
        /// 10pt - Caption text
        public static let caption: CGFloat = 10

        /// 11pt - Small text
        public static let small: CGFloat = 11

        /// 13pt - Body text (default)
        public static let body: CGFloat = 13

        /// 15pt - Large body text
        public static let bodyLarge: CGFloat = 15

        /// 17pt - Title text
        public static let title: CGFloat = 17

        /// 20pt - Large title
        public static let titleLarge: CGFloat = 20

        /// 24pt - Headline
        public static let headline: CGFloat = 24

        /// 28pt - Display text
        public static let display: CGFloat = 28
    }

    // MARK: - Animation

    /// Consistent animation durations
    public struct Animation {
        /// 0.15s - Quick micro-interactions
        public static let fast: Double = 0.15

        /// 0.25s - Standard transitions
        public static let normal: Double = 0.25

        /// 0.35s - Deliberate animations
        public static let slow: Double = 0.35

        /// 0.5s - Emphasis animations
        public static let emphasis: Double = 0.5
    }

    // MARK: - Shadows

    /// Shadow definitions for elevation
    public struct Shadow {
        /// Light shadow for subtle elevation
        public static let light = ShadowStyle(
            color: "rgba(0,0,0,0.08)",
            offsetX: 0,
            offsetY: 2,
            blur: 8
        )

        /// Medium shadow for cards
        public static let medium = ShadowStyle(
            color: "rgba(0,0,0,0.12)",
            offsetX: 0,
            offsetY: 4,
            blur: 16
        )

        /// Heavy shadow for modals
        public static let heavy = ShadowStyle(
            color: "rgba(0,0,0,0.16)",
            offsetX: 0,
            offsetY: 8,
            blur: 24
        )
    }

    /// Shadow style definition
    public struct ShadowStyle: Sendable {
        public let color: String
        public let offsetX: CGFloat
        public let offsetY: CGFloat
        public let blur: CGFloat

        public init(color: String, offsetX: CGFloat, offsetY: CGFloat, blur: CGFloat) {
            self.color = color
            self.offsetX = offsetX
            self.offsetY = offsetY
            self.blur = blur
        }
    }

    // MARK: - Status Indicator Colors

    /// System health status colors (used by Breathe)
    public struct StatusColors {
        #if canImport(SwiftUI)
        /// System healthy (< 70% usage)
        public static let healthy = Color.green

        /// Warning state (70-85% usage)
        public static let warning = Color.yellow

        /// Critical state (85-95% usage)
        public static let critical = Color.orange

        /// Danger state (> 95% usage)
        public static let danger = Color.red
        #endif

        /// Hex values for programmatic use
        public static let healthyHex = "#34C759"
        public static let warningHex = "#FFCC00"
        public static let criticalHex = "#FF9500"
        public static let dangerHex = "#FF3B30"
    }
}

// MARK: - Theme Preset

/// Pre-defined theme presets for different contexts
public enum ThemePreset: String, Sendable, CaseIterable {
    case light
    case dark
    case system

    /// Get the appropriate color scheme
    #if canImport(SwiftUI)
    public var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    #endif
}
