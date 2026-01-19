//
//  NavigationPatterns.swift
//  Breathe
//
//  Navigation pattern examples extracted from CommonPatterns.swift
//  Phase 3.6 Architecture Refactoring
//

import Foundation

@MainActor
extension CommonPatternsLibrary {
    // MARK: - Navigation Patterns

    static func tabbedInterfacePattern() -> UIPattern {
        UIPattern(
            name: "Tabbed Interface",
            category: .navigation,
            description: "Tab bar navigation with multiple views",
            complexity: .simple,
            codeTemplate: """
struct TabbedAppView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)
        }
        .awareContainer("tabbed-interface", label: "Tabbed Interface")
        .awareState("tabbed-interface", key: "selectedTab", value: selectedTab)
    }
}
""",
            elements: ["TabView", "Label"],
            modifiersUsed: [".awareContainer", ".awareState"],
            bestPractices: [
                "Track selected tab index",
                "Use semantic tab names",
                "Use SF Symbols for icons"
            ],
            commonMistakes: [
                "Not tracking selected tab",
                "Missing tab labels",
                "Not using proper tags"
            ],
            tokenEstimate: 108,
            exampleUseCases: ["App navigation", "Multi-section apps", "Tab interfaces"]
        )
    }

    static func masterDetailPattern() -> UIPattern {
        UIPattern(
            name: "Master-Detail",
            category: .navigation,
            description: "Two-column layout with list and detail view",
            complexity: .moderate,
            codeTemplate: """
struct MasterDetailView: View {
    @State private var items = ["Item 1", "Item 2"]
    @State private var selectedItem: String?

    var body: some View {
        NavigationSplitView {
            List(items, id: \\.self, selection: $selectedItem) { item in
                Text(item)
                    .aware("master-item-\\(item.hashValue)", label: item)
            }
            .awareContainer("master-list", label: "Master List")
            .awareState("master-list", key: "itemCount", value: items.count)
            .navigationTitle("Items")
        } detail: {
            if let item = selectedItem {
                DetailView(item: item)
                    .awareContainer("detail-view", label: "Detail View")
                    .awareState("detail-view", key: "selectedItem", value: item)
            } else {
                Text("Select an item")
                    .aware("no-selection", label: "No Selection Placeholder")
            }
        }
        .awareState("master-detail", key: "hasSelection", value: selectedItem != nil)
    }
}
""",
            elements: ["NavigationSplitView", "List", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Track selected item",
                "Show placeholder when nothing selected",
                "Track item count in master list"
            ],
            commonMistakes: [
                "Not tracking selection",
                "No placeholder for empty selection",
                "Missing navigation titles"
            ],
            tokenEstimate: 162,
            exampleUseCases: ["Email clients", "File browsers", "Settings panels"]
        )
    }

    static func wizardPattern() -> UIPattern {
        UIPattern(
            name: "Wizard/Stepper",
            category: .navigation,
            description: "Step-by-step guided flow",
            complexity: .complex,
            codeTemplate: """
// See multiStepFormPattern() for full implementation
""",
            elements: ["VStack", "TabView", "Button"],
            modifiersUsed: [".aware", ".awareButton", ".awareState", ".awareContainer"],
            bestPractices: [
                "Show progress clearly",
                "Allow backward navigation",
                "Track current step",
                "Validate before advancing"
            ],
            commonMistakes: [
                "No visual progress indicator",
                "Can't go back",
                "Missing step validation"
            ],
            tokenEstimate: 324,
            exampleUseCases: ["Onboarding", "Setup flows", "Configuration"]
        )
    }

    // MARK: - Settings Patterns
}
