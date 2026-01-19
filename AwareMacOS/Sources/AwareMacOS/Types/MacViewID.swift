//
//  MacViewID.swift
//  AwareMacOS
//
//  Stable view identifiers to prevent ID drift across macOS codebase.
//  Includes shared iOS identifiers + Mac-specific UI elements.
//

#if os(macOS)
import Foundation
import AwareCore

// MARK: - MacViewID Protocol

/// Protocol for type-safe view identifiers
public protocol MacViewIdentifier: RawRepresentable, Hashable, Sendable where RawValue == String {
    var rawValue: String { get }
}

// MARK: - Default MacViewID Enum

/// Common view identifiers used across typical macOS apps
/// Includes 60+ shared iOS identifiers + 40+ Mac-specific identifiers
public enum MacViewID: String, MacViewIdentifier {
    // MARK: - Authentication (Shared with iOS)
    case signInView = "signInView"
    case signUpView = "signUpView"
    case emailField = "emailField"
    case passwordField = "passwordField"
    case confirmPasswordField = "confirmPasswordField"
    case signInButton = "signInButton"
    case signUpButton = "signUpButton"
    case forgotPasswordButton = "forgotPasswordButton"
    case socialSignInButton = "socialSignInButton"

    // MARK: - Navigation (Shared with iOS)
    case tabBar = "tabBar"
    case homeTab = "homeTab"
    case searchTab = "searchTab"
    case profileTab = "profileTab"
    case settingsTab = "settingsTab"
    case navigationBar = "navigationBar"
    case backButton = "backButton"
    case closeButton = "closeButton"

    // MARK: - Home/Dashboard (Shared with iOS)
    case homeView = "homeView"
    case dashboardView = "dashboardView"
    case mainContent = "mainContent"
    case headerView = "headerView"
    case footerView = "footerView"

    // MARK: - Lists and Collections (Shared with iOS)
    case listView = "listView"
    case collectionView = "collectionView"
    case tableView = "tableView"
    case searchBar = "searchBar"
    case filterButton = "filterButton"
    case sortButton = "sortButton"
    case refreshControl = "refreshControl"

    // MARK: - Detail Views (Shared with iOS)
    case detailView = "detailView"
    case titleLabel = "titleLabel"
    case subtitleLabel = "subtitleLabel"
    case descriptionText = "descriptionText"
    case imageView = "imageView"
    case actionButton = "actionButton"

    // MARK: - Forms (Shared with iOS)
    case formView = "formView"
    case textField = "textField"
    case textArea = "textArea"
    case submitButton = "submitButton"
    case cancelButton = "cancelButton"
    case saveButton = "saveButton"
    case deleteButton = "deleteButton"

    // MARK: - Settings (Shared with iOS)
    case settingsView = "settingsView"
    case profileSection = "profileSection"
    case preferencesSection = "preferencesSection"
    case notificationsToggle = "notificationsToggle"
    case darkModeToggle = "darkModeToggle"
    case logoutButton = "logoutButton"

    // MARK: - Modals and Alerts (Shared with iOS)
    case modalView = "modalView"
    case alertView = "alertView"
    case confirmButton = "confirmButton"
    case dismissButton = "dismissButton"

    // MARK: - Loading and Error States (Shared with iOS)
    case loadingView = "loadingView"
    case errorView = "errorView"
    case retryButton = "retryButton"
    case emptyStateView = "emptyStateView"

    // MARK: - Media (Shared with iOS)
    case videoPlayer = "videoPlayer"
    case audioPlayer = "audioPlayer"
    case playButton = "playButton"
    case pauseButton = "pauseButton"
    case volumeSlider = "volumeSlider"

    // MARK: - Search (Shared with iOS)
    case searchView = "searchView"
    case searchResultsList = "searchResultsList"
    case filterView = "filterView"
    case clearSearchButton = "clearSearchButton"

    // MARK: - Toolbar (Mac-Specific)
    case toolbarView = "toolbarView"
    case toolbarButton = "toolbarButton"
    case toolbarSearch = "toolbarSearch"
    case toolbarSegmentedControl = "toolbarSegmentedControl"
    case toolbarSpacer = "toolbarSpacer"
    case toolbarPopupButton = "toolbarPopupButton"
    case toolbarShareButton = "toolbarShareButton"
    case toolbarPrintButton = "toolbarPrintButton"
    case toolbarCustomizeButton = "toolbarCustomizeButton"

    // MARK: - Sidebar (Mac-Specific)
    case sidebarView = "sidebarView"
    case sidebarItem = "sidebarItem"
    case sidebarToggle = "sidebarToggle"
    case sidebarHeader = "sidebarHeader"
    case sidebarSection = "sidebarSection"
    case sidebarFooter = "sidebarFooter"
    case sidebarAddButton = "sidebarAddButton"
    case sidebarRemoveButton = "sidebarRemoveButton"

    // MARK: - Split View (Mac-Specific)
    case splitView = "splitView"
    case splitDivider = "splitDivider"
    case primaryPane = "primaryPane"
    case secondaryPane = "secondaryPane"
    case tertiaryPane = "tertiaryPane"
    case splitViewToggle = "splitViewToggle"

    // MARK: - Inspector (Mac-Specific)
    case inspectorView = "inspectorView"
    case inspectorSection = "inspectorSection"
    case inspectorToggle = "inspectorToggle"
    case inspectorHeader = "inspectorHeader"
    case inspectorFooter = "inspectorFooter"
    case inspectorDisclosureButton = "inspectorDisclosureButton"

    // MARK: - Window Management (Mac-Specific)
    case windowTitleBar = "windowTitleBar"
    case windowTitle = "windowTitle"
    case windowSubtitle = "windowSubtitle"
    case closeWindowButton = "closeWindowButton"
    case minimizeButton = "minimizeButton"
    case zoomButton = "zoomButton"
    case fullScreenButton = "fullScreenButton"
    case windowToolbar = "windowToolbar"

    // MARK: - Menu (Mac-Specific)
    case menuBar = "menuBar"
    case menuItem = "menuItem"
    case contextMenu = "contextMenu"
    case menuSeparator = "menuSeparator"
    case submenu = "submenu"

    // MARK: - Status Bar (Mac-Specific)
    case statusBar = "statusBar"
    case statusBarItem = "statusBarItem"
    case statusBarMenu = "statusBarMenu"

    // MARK: - Popover (Mac-Specific)
    case popoverView = "popoverView"
    case popoverContent = "popoverContent"
    case popoverHeader = "popoverHeader"
    case popoverFooter = "popoverFooter"
    case popoverCloseButton = "popoverCloseButton"

    // MARK: - Preferences (Mac-Specific)
    case preferencesWindow = "preferencesWindow"
    case preferencesToolbar = "preferencesToolbar"
    case generalPreferences = "generalPreferences"
    case accountsPreferences = "accountsPreferences"
    case advancedPreferences = "advancedPreferences"

    // MARK: - Document-Based (Mac-Specific)
    case documentView = "documentView"
    case documentTitleBar = "documentTitleBar"
    case documentContent = "documentContent"
    case documentSidebar = "documentSidebar"
    case documentInspector = "documentInspector"
    case documentToolbar = "documentToolbar"
}

// MARK: - Custom ViewID Support

/// Extension to allow custom view IDs beyond the predefined enum
extension MacViewIdentifier {
    /// Create a custom view ID from a string
    public static func custom(_ id: String) -> String {
        return id
    }
}

// MARK: - Convenience Extensions

extension MacViewIdentifier {
    /// Generate a scoped ID by combining parent and child
    /// Example: MacViewID.homeView.scoped("header") -> "homeView.header"
    public func scoped(_ child: String) -> String {
        return "\(rawValue).\(child)"
    }

    /// Generate an indexed ID for items in collections
    /// Example: MacViewID.listView.indexed(0) -> "listView[0]"
    public func indexed(_ index: Int) -> String {
        return "\(rawValue)[\(index)]"
    }

    /// Generate a suffixed ID for variations
    /// Example: MacViewID.signInButton.suffixed("primary") -> "signInButton-primary"
    public func suffixed(_ suffix: String) -> String {
        return "\(rawValue)-\(suffix)"
    }
}

// MARK: - Category Queries

extension MacViewID {
    /// Check if this is a Mac-specific identifier (not shared with iOS)
    public var isMacSpecific: Bool {
        switch self {
        // Mac-Specific categories
        case .toolbarView, .toolbarButton, .toolbarSearch, .toolbarSegmentedControl,
             .toolbarSpacer, .toolbarPopupButton, .toolbarShareButton, .toolbarPrintButton,
             .toolbarCustomizeButton,
             .sidebarView, .sidebarItem, .sidebarToggle, .sidebarHeader, .sidebarSection,
             .sidebarFooter, .sidebarAddButton, .sidebarRemoveButton,
             .splitView, .splitDivider, .primaryPane, .secondaryPane, .tertiaryPane,
             .splitViewToggle,
             .inspectorView, .inspectorSection, .inspectorToggle, .inspectorHeader,
             .inspectorFooter, .inspectorDisclosureButton,
             .windowTitleBar, .windowTitle, .windowSubtitle, .closeWindowButton,
             .minimizeButton, .zoomButton, .fullScreenButton, .windowToolbar,
             .menuBar, .menuItem, .contextMenu, .menuSeparator, .submenu,
             .statusBar, .statusBarItem, .statusBarMenu,
             .popoverView, .popoverContent, .popoverHeader, .popoverFooter, .popoverCloseButton,
             .preferencesWindow, .preferencesToolbar, .generalPreferences, .accountsPreferences,
             .advancedPreferences,
             .documentView, .documentTitleBar, .documentContent, .documentSidebar,
             .documentInspector, .documentToolbar:
            return true
        default:
            return false
        }
    }

    /// Check if this is a shared identifier (common between iOS and macOS)
    public var isShared: Bool {
        return !isMacSpecific
    }

    /// Get the category name for this identifier
    public var category: String {
        switch self {
        case .signInView, .signUpView, .emailField, .passwordField, .confirmPasswordField,
             .signInButton, .signUpButton, .forgotPasswordButton, .socialSignInButton:
            return "Authentication"
        case .tabBar, .homeTab, .searchTab, .profileTab, .settingsTab, .navigationBar,
             .backButton, .closeButton:
            return "Navigation"
        case .homeView, .dashboardView, .mainContent, .headerView, .footerView:
            return "Home/Dashboard"
        case .listView, .collectionView, .tableView, .searchBar, .filterButton,
             .sortButton, .refreshControl:
            return "Lists and Collections"
        case .detailView, .titleLabel, .subtitleLabel, .descriptionText, .imageView,
             .actionButton:
            return "Detail Views"
        case .formView, .textField, .textArea, .submitButton, .cancelButton,
             .saveButton, .deleteButton:
            return "Forms"
        case .settingsView, .profileSection, .preferencesSection, .notificationsToggle,
             .darkModeToggle, .logoutButton:
            return "Settings"
        case .modalView, .alertView, .confirmButton, .dismissButton:
            return "Modals and Alerts"
        case .loadingView, .errorView, .retryButton, .emptyStateView:
            return "Loading and Error States"
        case .videoPlayer, .audioPlayer, .playButton, .pauseButton, .volumeSlider:
            return "Media"
        case .searchView, .searchResultsList, .filterView, .clearSearchButton:
            return "Search"
        case .toolbarView, .toolbarButton, .toolbarSearch, .toolbarSegmentedControl,
             .toolbarSpacer, .toolbarPopupButton, .toolbarShareButton, .toolbarPrintButton,
             .toolbarCustomizeButton:
            return "Toolbar (Mac)"
        case .sidebarView, .sidebarItem, .sidebarToggle, .sidebarHeader, .sidebarSection,
             .sidebarFooter, .sidebarAddButton, .sidebarRemoveButton:
            return "Sidebar (Mac)"
        case .splitView, .splitDivider, .primaryPane, .secondaryPane, .tertiaryPane,
             .splitViewToggle:
            return "Split View (Mac)"
        case .inspectorView, .inspectorSection, .inspectorToggle, .inspectorHeader,
             .inspectorFooter, .inspectorDisclosureButton:
            return "Inspector (Mac)"
        case .windowTitleBar, .windowTitle, .windowSubtitle, .closeWindowButton,
             .minimizeButton, .zoomButton, .fullScreenButton, .windowToolbar:
            return "Window Management (Mac)"
        case .menuBar, .menuItem, .contextMenu, .menuSeparator, .submenu:
            return "Menu (Mac)"
        case .statusBar, .statusBarItem, .statusBarMenu:
            return "Status Bar (Mac)"
        case .popoverView, .popoverContent, .popoverHeader, .popoverFooter, .popoverCloseButton:
            return "Popover (Mac)"
        case .preferencesWindow, .preferencesToolbar, .generalPreferences, .accountsPreferences,
             .advancedPreferences:
            return "Preferences (Mac)"
        case .documentView, .documentTitleBar, .documentContent, .documentSidebar,
             .documentInspector, .documentToolbar:
            return "Document-Based (Mac)"
        }
    }
}

// MARK: - Statistics

extension MacViewID {
    /// Total number of predefined identifiers
    public static var totalCount: Int {
        return 109 // 60 shared + 49 Mac-specific
    }

    /// Number of shared identifiers (iOS + macOS)
    public static var sharedCount: Int {
        return 60
    }

    /// Number of Mac-specific identifiers
    public static var macSpecificCount: Int {
        return 49
    }

    /// Get all Mac-specific identifiers
    public static var allMacSpecific: [MacViewID] {
        return MacViewID.allCases.filter { $0.isMacSpecific }
    }

    /// Get all shared identifiers
    public static var allShared: [MacViewID] {
        return MacViewID.allCases.filter { $0.isShared }
    }
}

// MARK: - CaseIterable Conformance

extension MacViewID: CaseIterable {}

#endif // os(macOS)
