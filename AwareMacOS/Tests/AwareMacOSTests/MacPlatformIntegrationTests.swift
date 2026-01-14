//
//  MacPlatformIntegrationTests.swift
//  AwareMacOSTests
//
//  Integration tests for end-to-end workflows with macOS modifiers.
//  Tests realistic scenarios combining multiple modifiers.
//

#if os(macOS)
import XCTest
import SwiftUI
@testable import AwareMacOS
@testable import AwareCore

@MainActor
final class MacPlatformIntegrationTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        Aware.shared.reset()

        #if DEBUG
        print("\n=== Starting test: \(self.name) ===")
        #endif
    }

    override func tearDown() async throws {
        #if DEBUG
        print("=== Finished test: \(self.name) ===\n")
        #endif

        try await super.tearDown()
    }

    // MARK: - Document Workflow

    func testMacDocumentWorkflow() async throws {
        // Given - Document editor view with state tracking
        let docId = "test-document-\(UUID().uuidString)"
        let saveButtonId = "save-button-\(UUID().uuidString)"

        struct DocumentView: View {
            let docId: String
            let saveButtonId: String
            @State var hasUnsavedChanges = false
            @State var canUndo = false
            var saveAction: () -> Void

            var body: some View {
                VStack {
                    Text("Document Content")
                        .macDocumentState(
                            docId,
                            hasUnsavedChanges: hasUnsavedChanges,
                            documentPath: "/tmp/test.txt",
                            isReadOnly: false,
                            canUndo: canUndo,
                            canRedo: false,
                            autosavesInPlace: true
                        )

                    Button("Save") { saveAction() }
                        .uiTappable(saveButtonId, label: "Save", action: saveAction)
                }
            }
        }

        var saved = false
        _ = DocumentView(docId: docId, saveButtonId: saveButtonId, saveAction: { saved = true })
        try await Task.sleep(nanoseconds: 20_000_000)

        // When - Capture initial state
        let docNode = Aware.shared.query().where { $0.id == docId }.first()
        XCTAssertNotNil(docNode, "Document view should be registered")

        let hasChanges = Aware.shared.getStateBool(docId, key: "hasUnsavedChanges")
        XCTAssertEqual(hasChanges, false, "Initial state should be saved")

        // Execute save action
        let success = await AwareMacOSPlatform.shared.executeAction(saveButtonId)
        XCTAssertTrue(success, "Save action should execute")
        XCTAssertTrue(saved, "Save callback should be invoked")

        // Then - Verify document metadata type
        XCTAssertEqual(docNode?.action?.actionType, .fileSystem, "Document should use .fileSystem type")
    }

    func testMacDocumentWithToolbar() async throws {
        // Test document with toolbar controls
        let docId = "doc-\(UUID().uuidString)"
        let toolbarId = "toolbar-\(UUID().uuidString)"

        struct DocumentWithToolbar: View {
            let docId: String
            let toolbarId: String

            var body: some View {
                VStack {
                    Text("Toolbar")
                        .macToolbarState(toolbarId, isVisible: true, itemCount: 5, isCustomizable: true)

                    Text("Document")
                        .macDocumentState(
                            docId,
                            hasUnsavedChanges: true,
                            documentPath: "/path/doc.txt",
                            isReadOnly: false,
                            canUndo: true,
                            canRedo: true
                        )
                }
            }
        }

        _ = DocumentWithToolbar(docId: docId, toolbarId: toolbarId)
        try await Task.sleep(nanoseconds: 20_000_000)

        // Verify both registered
        let docNode = Aware.shared.query().where { $0.id == docId }.first()
        let toolbarNode = Aware.shared.query().where { $0.id == toolbarId }.first()

        XCTAssertNotNil(docNode, "Document should be registered")
        XCTAssertNotNil(toolbarNode, "Toolbar should be registered")

        XCTAssertEqual(docNode?.action?.actionType, .fileSystem, "Document type should be correct")
        XCTAssertEqual(toolbarNode?.action?.actionType, .mutation, "Toolbar type should be correct")
    }

    // MARK: - Preferences Workflow

    func testMacPreferencesWorkflow() async throws {
        // Given - Preferences window with multiple tabs
        let prefsId = "prefs-\(UUID().uuidString)"

        struct PreferencesView: View {
            let prefsId: String
            @State var selectedTab = "General"

            var body: some View {
                VStack {
                    Text("Preferences Window")
                        .macPreferencesState(
                            prefsId,
                            isPresented: true,
                            selectedTab: selectedTab,
                            tabCount: 4,
                            canDismiss: true
                        )
                }
            }
        }

        _ = PreferencesView(prefsId: prefsId)
        try await Task.sleep(nanoseconds: 20_000_000)

        // When - Query preferences state
        let prefsNode = Aware.shared.query().where { $0.id == prefsId }.first()
        XCTAssertNotNil(prefsNode, "Preferences should be registered")

        let selectedTab = Aware.shared.getStateString(prefsId, key: "selectedTab")
        XCTAssertEqual(selectedTab, "General", "Selected tab should be tracked")

        // Then - Verify navigation type
        XCTAssertEqual(prefsNode?.action?.actionType, .navigation, "Preferences should use .navigation type")
    }

    // MARK: - Menu Workflow

    func testMacMenuWorkflow() async throws {
        // Given - Menu with context menu and submenu
        let menuId = "menu-\(UUID().uuidString)"
        let contextMenuId = "context-menu-\(UUID().uuidString)"

        struct MenuView: View {
            let menuId: String
            let contextMenuId: String

            var body: some View {
                VStack {
                    Text("Main Menu")
                        .macMenuState(
                            menuId,
                            isOpen: true,
                            selectedItem: "File",
                            itemCount: 6,
                            isContextMenu: false,
                            isSubmenu: false
                        )

                    Text("Context Menu")
                        .macMenuState(
                            contextMenuId,
                            isOpen: false,
                            selectedItem: nil,
                            itemCount: 3,
                            isContextMenu: true,
                            isSubmenu: false
                        )
                }
            }
        }

        _ = MenuView(menuId: menuId, contextMenuId: contextMenuId)
        try await Task.sleep(nanoseconds: 20_000_000)

        // When - Check menu states
        let isMainMenuOpen = Aware.shared.getStateBool(menuId, key: "isOpen")
        XCTAssertEqual(isMainMenuOpen, true, "Main menu should be open")

        let isContextMenuOpen = Aware.shared.getStateBool(contextMenuId, key: "isOpen")
        XCTAssertEqual(isContextMenuOpen, false, "Context menu should be closed")

        let isContextMenu = Aware.shared.getStateBool(contextMenuId, key: "isContextMenu")
        XCTAssertEqual(isContextMenu, true, "Should be marked as context menu")

        // Then - Verify both use system type
        let mainNode = Aware.shared.query().where { $0.id == menuId }.first()
        let contextNode = Aware.shared.query().where { $0.id == contextMenuId }.first()

        XCTAssertEqual(mainNode?.action?.actionType, .system, "Main menu should use .system type")
        XCTAssertEqual(contextNode?.action?.actionType, .system, "Context menu should use .system type")
    }

    // MARK: - Popover Workflow

    func testMacPopoverWorkflow() async throws {
        // Given - Popover with different behaviors
        let popoverId = "popover-\(UUID().uuidString)"

        struct PopoverView: View {
            let popoverId: String
            @State var isPresented = false

            var body: some View {
                Text("Trigger Button")
                    .macPopoverState(
                        popoverId,
                        isPresented: isPresented,
                        edge: "bottom",
                        contentSize: "300x200",
                        behavior: "transient"
                    )
            }
        }

        _ = PopoverView(popoverId: popoverId)
        try await Task.sleep(nanoseconds: 20_000_000)

        // When - Check popover state
        let isPresented = Aware.shared.getStateBool(popoverId, key: "isPresented")
        XCTAssertEqual(isPresented, false, "Popover should not be presented initially")

        let edge = Aware.shared.getStateString(popoverId, key: "edge")
        XCTAssertEqual(edge, "bottom", "Edge should be tracked")

        // Then - Verify navigation type
        let node = Aware.shared.query().where { $0.id == popoverId }.first()
        XCTAssertEqual(node?.action?.actionType, .navigation, "Popover should use .navigation type")
    }

    // MARK: - Status Bar Workflow

    func testMacStatusBarWorkflow() async throws {
        // Given - Status bar item with menu
        let statusBarId = "statusbar-\(UUID().uuidString)"
        let menuId = "statusbar-menu-\(UUID().uuidString)"

        struct StatusBarView: View {
            let statusBarId: String
            let menuId: String

            var body: some View {
                VStack {
                    Text("Status Bar Item")
                        .macStatusBarState(
                            statusBarId,
                            isVisible: true,
                            isActive: true,
                            iconName: "cloud.fill",
                            hasMenu: true
                        )

                    Text("Status Bar Menu")
                        .macMenuState(
                            menuId,
                            isOpen: false,
                            selectedItem: nil,
                            itemCount: 4,
                            isContextMenu: false,
                            isSubmenu: false
                        )
                }
            }
        }

        _ = StatusBarView(statusBarId: statusBarId, menuId: menuId)
        try await Task.sleep(nanoseconds: 20_000_000)

        // When - Check status bar state
        let isVisible = Aware.shared.getStateBool(statusBarId, key: "isVisible")
        XCTAssertEqual(isVisible, true, "Status bar should be visible")

        let isActive = Aware.shared.getStateBool(statusBarId, key: "isActive")
        XCTAssertEqual(isActive, true, "Status bar should be active")

        let hasMenu = Aware.shared.getStateBool(statusBarId, key: "hasMenu")
        XCTAssertEqual(hasMenu, true, "Should have menu")

        // Then - Verify both registered with correct types
        let statusNode = Aware.shared.query().where { $0.id == statusBarId }.first()
        let menuNode = Aware.shared.query().where { $0.id == menuId }.first()

        XCTAssertNotNil(statusNode, "Status bar should be registered")
        XCTAssertNotNil(menuNode, "Menu should be registered")

        XCTAssertEqual(statusNode?.action?.actionType, .system, "Status bar should use .system type")
        XCTAssertEqual(menuNode?.action?.actionType, .system, "Menu should use .system type")
    }

    // MARK: - Window with Sidebar Workflow

    func testMacWindowWithSidebarWorkflow() async throws {
        // Given - Window with sidebar and split view
        let windowId = "window-\(UUID().uuidString)"
        let sidebarId = "sidebar-\(UUID().uuidString)"
        let splitViewId = "splitview-\(UUID().uuidString)"

        struct WindowWithSidebar: View {
            let windowId: String
            let sidebarId: String
            let splitViewId: String

            var body: some View {
                VStack {
                    Text("Window")
                        .macWindowState(
                            windowId,
                            isFullScreen: false,
                            isKeyWindow: true,
                            title: "Main Window"
                        )

                    Text("Sidebar")
                        .macSidebarState(
                            sidebarId,
                            isExpanded: true,
                            selectedItem: "Documents",
                            itemCount: 5
                        )

                    Text("Split View")
                        .macSplitViewState(
                            splitViewId,
                            dividerPosition: 0.25,
                            isCollapsed: false
                        )
                }
            }
        }

        _ = WindowWithSidebar(windowId: windowId, sidebarId: sidebarId, splitViewId: splitViewId)
        try await Task.sleep(nanoseconds: 30_000_000)  // 30ms for multiple registrations

        // When - Verify all components registered
        let windowNode = Aware.shared.query().where { $0.id == windowId }.first()
        let sidebarNode = Aware.shared.query().where { $0.id == sidebarId }.first()
        let splitViewNode = Aware.shared.query().where { $0.id == splitViewId }.first()

        XCTAssertNotNil(windowNode, "Window should be registered")
        XCTAssertNotNil(sidebarNode, "Sidebar should be registered")
        XCTAssertNotNil(splitViewNode, "Split view should be registered")

        // Verify sidebar state
        let isExpanded = Aware.shared.getStateBool(sidebarId, key: "isExpanded")
        XCTAssertEqual(isExpanded, true, "Sidebar should be expanded")

        let selectedItem = Aware.shared.getStateString(sidebarId, key: "selectedItem")
        XCTAssertEqual(selectedItem, "Documents", "Selected item should be tracked")

        // Then - Verify metadata types
        XCTAssertEqual(windowNode?.action?.actionType, .system, "Window should use .system type")
        XCTAssertEqual(sidebarNode?.action?.actionType, .mutation, "Sidebar should use .mutation type")
        XCTAssertEqual(splitViewNode?.action?.actionType, .mutation, "Split view should use .mutation type")
    }

    // MARK: - Form with Validation Workflow

    func testMacFormWithValidationWorkflow() async throws {
        // Given - Form with validation, loading, and error states
        let validationId = "validation-\(UUID().uuidString)"
        let loadingId = "loading-\(UUID().uuidString)"
        let errorId = "error-\(UUID().uuidString)"

        struct FormView: View {
            let validationId: String
            let loadingId: String
            let errorId: String
            @State var isValid = false
            @State var isLoading = false

            var body: some View {
                VStack {
                    Text("Form")
                        .uiValidationState(
                            validationId,
                            isValid: isValid,
                            errors: ["Email required", "Password too short"],
                            warnings: ["Weak password"]
                        )

                    Text("Loading")
                        .uiLoadingState(loadingId, isLoading: isLoading, message: "Submitting form")

                    Text("Error")
                        .uiErrorState(errorId, error: nil, canRetry: true)
                }
            }
        }

        _ = FormView(validationId: validationId, loadingId: loadingId, errorId: errorId)
        try await Task.sleep(nanoseconds: 30_000_000)

        // When - Check validation state
        let isValid = Aware.shared.getStateBool(validationId, key: "isValid")
        XCTAssertEqual(isValid, false, "Form should not be valid")

        let errorCount = Aware.shared.getStateString(validationId, key: "errorCount")
        XCTAssertEqual(errorCount, "2", "Should have 2 errors")

        let warningCount = Aware.shared.getStateString(validationId, key: "warningCount")
        XCTAssertEqual(warningCount, "1", "Should have 1 warning")

        // Then - Verify all components registered
        let validationNode = Aware.shared.query().where { $0.id == validationId }.first()
        let loadingNode = Aware.shared.query().where { $0.id == loadingId }.first()
        let errorNode = Aware.shared.query().where { $0.id == errorId }.first()

        XCTAssertNotNil(validationNode, "Validation should be registered")
        XCTAssertNotNil(loadingNode, "Loading should be registered")
        XCTAssertNotNil(errorNode, "Error should be registered")

        XCTAssertEqual(validationNode?.action?.actionType, .mutation, "Validation should use .mutation type")
        XCTAssertEqual(loadingNode?.action?.actionType, .mutation, "Loading should use .mutation type")
        XCTAssertEqual(errorNode?.action?.actionType, .mutation, "Error should use .mutation type")
    }

    // MARK: - Network Sync Workflow

    func testMacNetworkSyncWorkflow() async throws {
        // Given - Network sync with loading and error handling
        let networkId = "network-\(UUID().uuidString)"
        let loadingId = "sync-loading-\(UUID().uuidString)"

        struct NetworkSyncView: View {
            let networkId: String
            let loadingId: String
            @State var isOnline = true
            @State var isSyncing = true

            var body: some View {
                VStack {
                    Text("Network Status")
                        .uiNetworkState(
                            networkId,
                            isConnected: isOnline,
                            isLoading: isSyncing,
                            lastSync: Date()
                        )

                    Text("Syncing")
                        .uiLoadingState(
                            loadingId,
                            isLoading: isSyncing,
                            message: "Syncing data",
                            progress: 0.5
                        )
                }
            }
        }

        _ = NetworkSyncView(networkId: networkId, loadingId: loadingId)
        try await Task.sleep(nanoseconds: 20_000_000)

        // When - Check network state
        let isOnline = Aware.shared.getStateBool(networkId, key: "isOnline")
        XCTAssertEqual(isOnline, true, "Should be online")

        let isSyncing = Aware.shared.getStateBool(networkId, key: "isSyncing")
        XCTAssertEqual(isSyncing, true, "Should be syncing")

        let isLoading = Aware.shared.getStateBool(loadingId, key: "isLoading")
        XCTAssertEqual(isLoading, true, "Loading indicator should be active")

        // Then - Verify network type
        let networkNode = Aware.shared.query().where { $0.id == networkId }.first()
        XCTAssertEqual(networkNode?.action?.actionType, .network, "Network should use .network type")
    }

    // MARK: - Snapshot Capture

    func testSnapshotCaptureWithMacModifiers() async throws {
        // Given - View with multiple Mac-specific modifiers
        let docId = "doc-\(UUID().uuidString)"
        let menuId = "menu-\(UUID().uuidString)"
        let statusBarId = "status-\(UUID().uuidString)"

        struct ComplexMacView: View {
            let docId: String
            let menuId: String
            let statusBarId: String

            var body: some View {
                VStack {
                    Text("Document")
                        .macDocumentState(docId, hasUnsavedChanges: true, documentPath: "/path/doc.txt")

                    Text("Menu")
                        .macMenuState(menuId, isOpen: false, itemCount: 5)

                    Text("Status")
                        .macStatusBarState(statusBarId, isVisible: true, isActive: true)
                }
            }
        }

        _ = ComplexMacView(docId: docId, menuId: menuId, statusBarId: statusBarId)
        try await Task.sleep(nanoseconds: 30_000_000)

        // When - Capture snapshot
        let _ = await Aware.shared.snapshot(format: .compact)

        // Then - Verify all views appear in snapshot
        let allNodes = Aware.shared.query().all()
        XCTAssertGreaterThan(allNodes.count, 0, "Should have registered views")

        let docNode = allNodes.first { $0.id == docId }
        let menuNode = allNodes.first { $0.id == menuId }
        let statusNode = allNodes.first { $0.id == statusBarId }

        XCTAssertNotNil(docNode, "Document should appear in query results")
        XCTAssertNotNil(menuNode, "Menu should appear in query results")
        XCTAssertNotNil(statusNode, "Status bar should appear in query results")
    }
}

#endif // os(macOS)
