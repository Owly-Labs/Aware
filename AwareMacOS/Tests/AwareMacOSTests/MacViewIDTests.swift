//
//  MacViewIDTests.swift
//  AwareMacOSTests
//
//  Tests for MacViewID enum and helper methods.
//  Verifies predefined identifiers, scoping, indexing, and classification.
//

#if os(macOS)
import XCTest
@testable import AwareMacOS

@MainActor
final class MacViewIDTests: XCTestCase {

    // MARK: - Predefined View IDs

    func testPredefinedViewIDs_Authentication() throws {
        // Shared authentication identifiers
        XCTAssertEqual(MacViewID.signInView.rawValue, "signInView")
        XCTAssertEqual(MacViewID.signUpView.rawValue, "signUpView")
        XCTAssertEqual(MacViewID.emailField.rawValue, "emailField")
        XCTAssertEqual(MacViewID.passwordField.rawValue, "passwordField")
        XCTAssertEqual(MacViewID.signInButton.rawValue, "signInButton")
        XCTAssertEqual(MacViewID.forgotPasswordButton.rawValue, "forgotPasswordButton")
    }

    func testPredefinedViewIDs_Navigation() throws {
        XCTAssertEqual(MacViewID.tabBar.rawValue, "tabBar")
        XCTAssertEqual(MacViewID.homeTab.rawValue, "homeTab")
        XCTAssertEqual(MacViewID.navigationBar.rawValue, "navigationBar")
        XCTAssertEqual(MacViewID.backButton.rawValue, "backButton")
        XCTAssertEqual(MacViewID.closeButton.rawValue, "closeButton")
    }

    func testPredefinedViewIDs_MacToolbar() throws {
        // Mac-specific toolbar identifiers
        XCTAssertEqual(MacViewID.toolbarView.rawValue, "toolbarView")
        XCTAssertEqual(MacViewID.toolbarButton.rawValue, "toolbarButton")
        XCTAssertEqual(MacViewID.toolbarSearch.rawValue, "toolbarSearch")
        XCTAssertEqual(MacViewID.toolbarShareButton.rawValue, "toolbarShareButton")
        XCTAssertEqual(MacViewID.toolbarPrintButton.rawValue, "toolbarPrintButton")
    }

    func testPredefinedViewIDs_MacSidebar() throws {
        XCTAssertEqual(MacViewID.sidebarView.rawValue, "sidebarView")
        XCTAssertEqual(MacViewID.sidebarItem.rawValue, "sidebarItem")
        XCTAssertEqual(MacViewID.sidebarToggle.rawValue, "sidebarToggle")
        XCTAssertEqual(MacViewID.sidebarHeader.rawValue, "sidebarHeader")
    }

    func testPredefinedViewIDs_MacWindow() throws {
        XCTAssertEqual(MacViewID.windowTitleBar.rawValue, "windowTitleBar")
        XCTAssertEqual(MacViewID.closeWindowButton.rawValue, "closeWindowButton")
        XCTAssertEqual(MacViewID.minimizeButton.rawValue, "minimizeButton")
        XCTAssertEqual(MacViewID.fullScreenButton.rawValue, "fullScreenButton")
    }

    func testPredefinedViewIDs_MacMenu() throws {
        XCTAssertEqual(MacViewID.menuBar.rawValue, "menuBar")
        XCTAssertEqual(MacViewID.menuItem.rawValue, "menuItem")
        XCTAssertEqual(MacViewID.contextMenu.rawValue, "contextMenu")
        XCTAssertEqual(MacViewID.submenu.rawValue, "submenu")
    }

    func testPredefinedViewIDs_MacPreferences() throws {
        XCTAssertEqual(MacViewID.preferencesWindow.rawValue, "preferencesWindow")
        XCTAssertEqual(MacViewID.generalPreferences.rawValue, "generalPreferences")
        XCTAssertEqual(MacViewID.accountsPreferences.rawValue, "accountsPreferences")
    }

    func testPredefinedViewIDs_MacDocument() throws {
        XCTAssertEqual(MacViewID.documentView.rawValue, "documentView")
        XCTAssertEqual(MacViewID.documentContent.rawValue, "documentContent")
        XCTAssertEqual(MacViewID.documentSidebar.rawValue, "documentSidebar")
    }

    // MARK: - Scoped IDs

    func testScopedIDs() throws {
        // Test scoped ID generation
        let scoped1 = MacViewID.homeView.scoped("header")
        XCTAssertEqual(scoped1, "homeView.header", "Scoped ID should combine parent and child with dot")

        let scoped2 = MacViewID.sidebarView.scoped("items")
        XCTAssertEqual(scoped2, "sidebarView.items")

        let scoped3 = MacViewID.toolbarView.scoped("buttons")
        XCTAssertEqual(scoped3, "toolbarView.buttons")
    }

    func testNestedScopedIDs() throws {
        // Test multiple levels of scoping
        let baseId = MacViewID.documentView
        let level1 = baseId.scoped("content")
        // Note: scoped() returns String, so we can't chain on MacViewID
        // This demonstrates the pattern for nested scoping
        XCTAssertEqual(level1, "documentView.content")

        let manualNested = "documentView.content.section"
        XCTAssertTrue(manualNested.contains("documentView"))
        XCTAssertTrue(manualNested.contains("content"))
        XCTAssertTrue(manualNested.contains("section"))
    }

    // MARK: - Indexed IDs

    func testIndexedIDs() throws {
        // Test indexed ID generation for collections
        let indexed1 = MacViewID.listView.indexed(0)
        XCTAssertEqual(indexed1, "listView[0]", "Indexed ID should use array-style notation")

        let indexed2 = MacViewID.sidebarItem.indexed(5)
        XCTAssertEqual(indexed2, "sidebarItem[5]")

        let indexed3 = MacViewID.menuItem.indexed(10)
        XCTAssertEqual(indexed3, "menuItem[10]")
    }

    func testIndexedIDsWithNegativeIndex() throws {
        // Test that negative indices work (though not typically used)
        let indexed = MacViewID.listView.indexed(-1)
        XCTAssertEqual(indexed, "listView[-1]")
    }

    // MARK: - Suffixed IDs

    func testSuffixedIDs() throws {
        // Test suffixed ID generation for variations
        let suffixed1 = MacViewID.signInButton.suffixed("primary")
        XCTAssertEqual(suffixed1, "signInButton-primary", "Suffixed ID should use hyphen separator")

        let suffixed2 = MacViewID.toolbarButton.suffixed("save")
        XCTAssertEqual(suffixed2, "toolbarButton-save")

        let suffixed3 = MacViewID.actionButton.suffixed("danger")
        XCTAssertEqual(suffixed3, "actionButton-danger")
    }

    // MARK: - Custom IDs

    func testCustomIDs() throws {
        // Test custom ID creation
        let customId = MacViewID.custom("myCustomView")
        XCTAssertEqual(customId, "myCustomView", "Custom IDs should be passed through unchanged")

        let customComplex = MacViewID.custom("app.feature.component")
        XCTAssertEqual(customComplex, "app.feature.component")
    }

    // MARK: - Mac-Specific Classification

    func testIsMacSpecific_Toolbar() throws {
        // Toolbar identifiers should be Mac-specific
        XCTAssertTrue(MacViewID.toolbarView.isMacSpecific)
        XCTAssertTrue(MacViewID.toolbarButton.isMacSpecific)
        XCTAssertTrue(MacViewID.toolbarSearch.isMacSpecific)
        XCTAssertTrue(MacViewID.toolbarShareButton.isMacSpecific)
    }

    func testIsMacSpecific_Sidebar() throws {
        XCTAssertTrue(MacViewID.sidebarView.isMacSpecific)
        XCTAssertTrue(MacViewID.sidebarItem.isMacSpecific)
        XCTAssertTrue(MacViewID.sidebarToggle.isMacSpecific)
    }

    func testIsMacSpecific_Window() throws {
        XCTAssertTrue(MacViewID.windowTitleBar.isMacSpecific)
        XCTAssertTrue(MacViewID.closeWindowButton.isMacSpecific)
        XCTAssertTrue(MacViewID.minimizeButton.isMacSpecific)
        XCTAssertTrue(MacViewID.fullScreenButton.isMacSpecific)
    }

    func testIsMacSpecific_Menu() throws {
        XCTAssertTrue(MacViewID.menuBar.isMacSpecific)
        XCTAssertTrue(MacViewID.menuItem.isMacSpecific)
        XCTAssertTrue(MacViewID.contextMenu.isMacSpecific)
    }

    func testIsMacSpecific_StatusBar() throws {
        XCTAssertTrue(MacViewID.statusBar.isMacSpecific)
        XCTAssertTrue(MacViewID.statusBarItem.isMacSpecific)
        XCTAssertTrue(MacViewID.statusBarMenu.isMacSpecific)
    }

    func testIsMacSpecific_Preferences() throws {
        XCTAssertTrue(MacViewID.preferencesWindow.isMacSpecific)
        XCTAssertTrue(MacViewID.generalPreferences.isMacSpecific)
        XCTAssertTrue(MacViewID.accountsPreferences.isMacSpecific)
    }

    func testIsMacSpecific_Document() throws {
        XCTAssertTrue(MacViewID.documentView.isMacSpecific)
        XCTAssertTrue(MacViewID.documentContent.isMacSpecific)
        XCTAssertTrue(MacViewID.documentSidebar.isMacSpecific)
    }

    // MARK: - Shared Classification

    func testIsShared_Authentication() throws {
        // Authentication identifiers should be shared
        XCTAssertFalse(MacViewID.signInView.isMacSpecific)
        XCTAssertTrue(MacViewID.signInView.isShared)

        XCTAssertFalse(MacViewID.emailField.isMacSpecific)
        XCTAssertTrue(MacViewID.emailField.isShared)

        XCTAssertFalse(MacViewID.signInButton.isMacSpecific)
        XCTAssertTrue(MacViewID.signInButton.isShared)
    }

    func testIsShared_Navigation() throws {
        XCTAssertFalse(MacViewID.tabBar.isMacSpecific)
        XCTAssertTrue(MacViewID.tabBar.isShared)

        XCTAssertFalse(MacViewID.navigationBar.isMacSpecific)
        XCTAssertTrue(MacViewID.navigationBar.isShared)
    }

    func testIsShared_Forms() throws {
        XCTAssertFalse(MacViewID.formView.isMacSpecific)
        XCTAssertTrue(MacViewID.formView.isShared)

        XCTAssertFalse(MacViewID.textField.isMacSpecific)
        XCTAssertTrue(MacViewID.textField.isShared)
    }

    // MARK: - Category Queries

    func testCategory_Authentication() throws {
        XCTAssertEqual(MacViewID.signInView.category, "Authentication")
        XCTAssertEqual(MacViewID.emailField.category, "Authentication")
        XCTAssertEqual(MacViewID.passwordField.category, "Authentication")
    }

    func testCategory_Navigation() throws {
        XCTAssertEqual(MacViewID.tabBar.category, "Navigation")
        XCTAssertEqual(MacViewID.navigationBar.category, "Navigation")
        XCTAssertEqual(MacViewID.backButton.category, "Navigation")
    }

    func testCategory_MacToolbar() throws {
        XCTAssertEqual(MacViewID.toolbarView.category, "Toolbar (Mac)")
        XCTAssertEqual(MacViewID.toolbarButton.category, "Toolbar (Mac)")
        XCTAssertEqual(MacViewID.toolbarSearch.category, "Toolbar (Mac)")
    }

    func testCategory_MacSidebar() throws {
        XCTAssertEqual(MacViewID.sidebarView.category, "Sidebar (Mac)")
        XCTAssertEqual(MacViewID.sidebarItem.category, "Sidebar (Mac)")
    }

    func testCategory_MacWindow() throws {
        XCTAssertEqual(MacViewID.windowTitleBar.category, "Window Management (Mac)")
        XCTAssertEqual(MacViewID.closeWindowButton.category, "Window Management (Mac)")
    }

    func testCategory_MacMenu() throws {
        XCTAssertEqual(MacViewID.menuBar.category, "Menu (Mac)")
        XCTAssertEqual(MacViewID.menuItem.category, "Menu (Mac)")
    }

    func testCategory_MacPreferences() throws {
        XCTAssertEqual(MacViewID.preferencesWindow.category, "Preferences (Mac)")
        XCTAssertEqual(MacViewID.generalPreferences.category, "Preferences (Mac)")
    }

    func testCategory_MacDocument() throws {
        XCTAssertEqual(MacViewID.documentView.category, "Document-Based (Mac)")
        XCTAssertEqual(MacViewID.documentContent.category, "Document-Based (Mac)")
    }

    // MARK: - Statistics

    func testStatistics_TotalCount() throws {
        XCTAssertEqual(MacViewID.totalCount, 109, "Total count should be 109 (60 shared + 49 Mac-specific)")
    }

    func testStatistics_SharedCount() throws {
        XCTAssertEqual(MacViewID.sharedCount, 60, "Shared count should be 60")
    }

    func testStatistics_MacSpecificCount() throws {
        XCTAssertEqual(MacViewID.macSpecificCount, 49, "Mac-specific count should be 49")
    }

    func testStatistics_AllMacSpecific() throws {
        let allMacSpecific = MacViewID.allMacSpecific
        XCTAssertEqual(allMacSpecific.count, 49, "Should have 49 Mac-specific identifiers")

        // Verify all returned items are actually Mac-specific
        for id in allMacSpecific {
            XCTAssertTrue(id.isMacSpecific, "\(id.rawValue) should be Mac-specific")
        }

        // Spot check some expected Mac-specific IDs
        XCTAssertTrue(allMacSpecific.contains(.toolbarView))
        XCTAssertTrue(allMacSpecific.contains(.sidebarView))
        XCTAssertTrue(allMacSpecific.contains(.menuBar))
        XCTAssertTrue(allMacSpecific.contains(.statusBar))
    }

    func testStatistics_AllShared() throws {
        let allShared = MacViewID.allShared
        XCTAssertEqual(allShared.count, 60, "Should have 60 shared identifiers")

        // Verify all returned items are actually shared
        for id in allShared {
            XCTAssertTrue(id.isShared, "\(id.rawValue) should be shared")
        }

        // Spot check some expected shared IDs
        XCTAssertTrue(allShared.contains(.signInView))
        XCTAssertTrue(allShared.contains(.tabBar))
        XCTAssertTrue(allShared.contains(.formView))
        XCTAssertTrue(allShared.contains(.settingsView))
    }

    // MARK: - CaseIterable Conformance

    func testCaseIterable() throws {
        let allCases = MacViewID.allCases
        XCTAssertEqual(allCases.count, 109, "Should have 109 cases via CaseIterable")

        // Verify some expected cases are present
        XCTAssertTrue(allCases.contains(.signInView))
        XCTAssertTrue(allCases.contains(.toolbarView))
        XCTAssertTrue(allCases.contains(.sidebarView))
        XCTAssertTrue(allCases.contains(.menuBar))
    }

    func testCaseIterableConsistency() throws {
        // Verify CaseIterable count matches static count
        let allCases = MacViewID.allCases
        let macSpecificCount = allCases.filter { $0.isMacSpecific }.count
        let sharedCount = allCases.filter { $0.isShared }.count

        XCTAssertEqual(macSpecificCount, MacViewID.macSpecificCount, "Mac-specific count should match")
        XCTAssertEqual(sharedCount, MacViewID.sharedCount, "Shared count should match")
        XCTAssertEqual(macSpecificCount + sharedCount, MacViewID.totalCount, "Counts should sum correctly")
    }

    // MARK: - Combined Helper Methods

    func testCombinedHelpers() throws {
        // Test combining multiple helper methods
        let base = MacViewID.sidebarItem
        let indexed = base.indexed(3)
        XCTAssertEqual(indexed, "sidebarItem[3]")

        // Manual combination (since helpers return String, not MacViewID)
        let scopedBase = MacViewID.documentView.scoped("toolbar")
        XCTAssertEqual(scopedBase, "documentView.toolbar")

        let suffixedBase = MacViewID.actionButton.suffixed("primary")
        XCTAssertEqual(suffixedBase, "actionButton-primary")
    }

    // MARK: - Edge Cases

    func testEmptyStrings() throws {
        // Test helpers with empty strings
        let scopedEmpty = MacViewID.homeView.scoped("")
        XCTAssertEqual(scopedEmpty, "homeView.", "Should still append dot")

        let suffixedEmpty = MacViewID.homeView.suffixed("")
        XCTAssertEqual(suffixedEmpty, "homeView-", "Should still append hyphen")
    }

    func testSpecialCharacters() throws {
        // Test helpers with special characters
        let scopedSpecial = MacViewID.homeView.scoped("sub.view")
        XCTAssertEqual(scopedSpecial, "homeView.sub.view")

        let suffixedSpecial = MacViewID.actionButton.suffixed("danger-zone")
        XCTAssertEqual(suffixedSpecial, "actionButton-danger-zone")

        let customSpecial = MacViewID.custom("my_custom-view.123")
        XCTAssertEqual(customSpecial, "my_custom-view.123")
    }
}

#endif // os(macOS)
