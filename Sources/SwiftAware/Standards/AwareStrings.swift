// AwareStrings.swift
// SwiftAware Standards Module
//
// Centralized string patterns for consistent messaging across SwiftAware-based apps.
// Use String(localized:) for i18n support.

import Foundation

// MARK: - Aware Strings

/// Centralized string constants for SwiftAware-based apps.
public struct AwareStrings: Sendable {

    // MARK: - Common Actions

    /// Common action button labels
    public struct Common {
        public static let ok = String(localized: "OK", comment: "Confirmation button")
        public static let cancel = String(localized: "Cancel", comment: "Cancel button")
        public static let save = String(localized: "Save", comment: "Save button")
        public static let delete = String(localized: "Delete", comment: "Delete button")
        public static let edit = String(localized: "Edit", comment: "Edit button")
        public static let done = String(localized: "Done", comment: "Done button")
        public static let close = String(localized: "Close", comment: "Close button")
        public static let retry = String(localized: "Retry", comment: "Retry button")
        public static let confirm = String(localized: "Confirm", comment: "Confirm button")
        public static let dismiss = String(localized: "Dismiss", comment: "Dismiss button")
        public static let loading = String(localized: "Loading...", comment: "Loading state")
        public static let settings = String(localized: "Settings", comment: "Settings label")
    }

    // MARK: - Status Messages

    /// Status and state messages
    public struct Status {
        public static let success = String(localized: "Success", comment: "Success status")
        public static let error = String(localized: "Error", comment: "Error status")
        public static let warning = String(localized: "Warning", comment: "Warning status")
        public static let info = String(localized: "Info", comment: "Info status")
        public static let pending = String(localized: "Pending", comment: "Pending status")
        public static let inProgress = String(localized: "In Progress", comment: "In progress status")
        public static let complete = String(localized: "Complete", comment: "Complete status")
        public static let failed = String(localized: "Failed", comment: "Failed status")
        public static let blocked = String(localized: "Blocked", comment: "Blocked status")
    }

    // MARK: - Error Messages

    /// Common error messages
    public struct Errors {
        public static let generic = String(localized: "Something went wrong. Please try again.", comment: "Generic error")
        public static let network = String(localized: "Network connection unavailable.", comment: "Network error")
        public static let timeout = String(localized: "Request timed out. Please try again.", comment: "Timeout error")
        public static let unauthorized = String(localized: "You are not authorized to perform this action.", comment: "Auth error")
        public static let notFound = String(localized: "The requested resource was not found.", comment: "Not found error")
        public static let invalidInput = String(localized: "Please check your input and try again.", comment: "Validation error")
        public static let fileNotFound = String(localized: "File not found.", comment: "File error")
        public static let permissionDenied = String(localized: "Permission denied.", comment: "Permission error")
    }

    // MARK: - Cook/Agent Messages

    /// Messages related to /cook and agent operations
    public struct Cook {
        public static let starting = String(localized: "Starting cook session...", comment: "Cook start")
        public static let running = String(localized: "Cook session running", comment: "Cook running")
        public static let completed = String(localized: "Cook session completed", comment: "Cook done")
        public static let failed = String(localized: "Cook session failed", comment: "Cook error")
        public static let paused = String(localized: "Cook session paused", comment: "Cook paused")
        public static let resumed = String(localized: "Cook session resumed", comment: "Cook resumed")

        public static let spawningAgents = String(localized: "Spawning agents...", comment: "Agent spawn")
        public static let agentWorking = String(localized: "Agent working...", comment: "Agent working")
        public static let agentComplete = String(localized: "Agent completed task", comment: "Agent done")
        public static let agentFailed = String(localized: "Agent task failed", comment: "Agent error")

        public static let buildVerifying = String(localized: "Verifying build...", comment: "Build verify")
        public static let buildSuccess = String(localized: "Build succeeded", comment: "Build success")
        public static let buildFailed = String(localized: "Build failed", comment: "Build error")
    }

    // MARK: - System Messages (Breathe)

    /// Messages for system monitoring (Breathe-specific)
    public struct System {
        public static let diskLow = String(localized: "Disk space is running low", comment: "Low disk warning")
        public static let memoryLow = String(localized: "Memory is running low", comment: "Low memory warning")
        public static let cpuHigh = String(localized: "CPU usage is high", comment: "High CPU warning")
        public static let cleanupComplete = String(localized: "Cleanup complete", comment: "Cleanup done")
        public static let cleanupFailed = String(localized: "Cleanup failed", comment: "Cleanup error")
        public static let freedSpace = String(localized: "Freed %@ of disk space", comment: "Space freed")
        public static let freedMemory = String(localized: "Freed %@ of memory", comment: "Memory freed")
    }

    // MARK: - Accessibility Labels

    /// Accessibility labels for VoiceOver support
    public struct Accessibility {
        public static let menuBarIcon = String(localized: "Breathe system monitor", comment: "Menu bar icon")
        public static let statusHealthy = String(localized: "System status: healthy", comment: "Status healthy")
        public static let statusWarning = String(localized: "System status: warning", comment: "Status warning")
        public static let statusCritical = String(localized: "System status: critical", comment: "Status critical")
        public static let closeButton = String(localized: "Close", comment: "Close button")
        public static let settingsButton = String(localized: "Open settings", comment: "Settings button")
        public static let refreshButton = String(localized: "Refresh data", comment: "Refresh button")
    }

    // MARK: - Time/Duration

    /// Time and duration formatting strings
    public struct Time {
        public static let now = String(localized: "Just now", comment: "Now")
        public static let secondsAgo = String(localized: "%d seconds ago", comment: "Seconds ago")
        public static let minutesAgo = String(localized: "%d minutes ago", comment: "Minutes ago")
        public static let hoursAgo = String(localized: "%d hours ago", comment: "Hours ago")
        public static let daysAgo = String(localized: "%d days ago", comment: "Days ago")
        public static let duration = String(localized: "%@ elapsed", comment: "Duration")
    }

    // MARK: - Confirmation Dialogs

    /// Confirmation dialog messages
    public struct Confirmation {
        public static let deleteTitle = String(localized: "Delete Item?", comment: "Delete title")
        public static let deleteMessage = String(localized: "This action cannot be undone.", comment: "Delete message")
        public static let discardTitle = String(localized: "Discard Changes?", comment: "Discard title")
        public static let discardMessage = String(localized: "Any unsaved changes will be lost.", comment: "Discard message")
        public static let quitTitle = String(localized: "Quit Application?", comment: "Quit title")
        public static let quitMessage = String(localized: "Any running operations will be stopped.", comment: "Quit message")
    }
}

// MARK: - String Formatting Helpers

extension AwareStrings {

    /// Format a file size in bytes to human readable string
    public static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Format a duration in seconds to human readable string
    public static func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: seconds) ?? "\(Int(seconds))s"
    }

    /// Format a relative time (e.g., "2 minutes ago")
    public static func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
