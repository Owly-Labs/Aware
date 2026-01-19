//
//  ListPatterns.swift
//  Breathe
//
//  List pattern examples extracted from CommonPatterns.swift
//  Phase 3.6 Architecture Refactoring
//

import Foundation

@MainActor
extension CommonPatternsLibrary {
    // MARK: - List Patterns

    static func simpleListPattern() -> UIPattern {
        UIPattern(
            name: "Simple List",
            category: .lists,
            description: "Basic list view with items",
            complexity: .simple,
            codeTemplate: """
struct SimpleListView: View {
    @State private var items: [String] = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        List {
            ForEach(items, id: \\.self) { item in
                Text(item)
                    .aware("list-item-\\(item.hashValue)", label: item)
            }
        }
        .awareContainer("simple-list", label: "Simple List")
        .awareState("simple-list", key: "itemCount", value: items.count)
    }
}
""",
            elements: ["List", "ForEach", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Use .aware() on list items for tracking",
                "Track item count with .awareState()",
                "Use unique IDs for list items"
            ],
            commonMistakes: [
                "Not tracking individual items",
                "Not tracking list count",
                "Using non-unique IDs"
            ],
            tokenEstimate: 90,
            exampleUseCases: ["Menu lists", "Item catalogs", "Simple displays"]
        )
    }

    static func pullToRefreshListPattern() -> UIPattern {
        UIPattern(
            name: "Pull-to-Refresh List",
            category: .lists,
            description: "List with pull-to-refresh functionality",
            complexity: .moderate,
            codeTemplate: """
struct RefreshableListView: View {
    @State private var items: [String] = []
    @State private var isRefreshing = false

    var body: some View {
        List {
            ForEach(items, id: \\.self) { item in
                Text(item)
                    .aware("list-item-\\(item.hashValue)", label: item)
            }
        }
        .refreshable {
            await refresh()
        }
        .awareContainer("refreshable-list", label: "Refreshable List")
        .awareState("refreshable-list", key: "isRefreshing", value: isRefreshing)
        .awareState("refreshable-list", key: "itemCount", value: items.count)
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        // Fetch new data
    }
}
""",
            elements: ["List", "ForEach", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Track isRefreshing state",
                "Use async/await for refresh",
                "Track item count changes"
            ],
            commonMistakes: [
                "Not tracking refresh state",
                "Not using async properly",
                "Missing count updates"
            ],
            tokenEstimate: 126,
            exampleUseCases: ["News feeds", "Social media", "Data lists"]
        )
    }

    static func searchableListPattern() -> UIPattern {
        UIPattern(
            name: "Searchable List",
            category: .lists,
            description: "List with search bar filtering",
            complexity: .moderate,
            codeTemplate: """
struct SearchableListView: View {
    @State private var items = ["Apple", "Banana", "Cherry"]
    @State private var searchText = ""

    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredItems, id: \\.self) { item in
                Text(item)
                    .aware("list-item-\\(item.hashValue)", label: item)
            }
        }
        .searchable(text: $searchText)
        .awareContainer("searchable-list", label: "Searchable List")
        .awareState("searchable-list", key: "searchText", value: searchText)
        .awareState("searchable-list", key: "filteredCount", value: filteredItems.count)
    }
}
""",
            elements: ["List", "ForEach", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Track search text state",
                "Track filtered count",
                "Use computed property for filtering"
            ],
            commonMistakes: [
                "Not tracking search text",
                "Not tracking filtered results",
                "Filtering inefficiently"
            ],
            tokenEstimate: 144,
            exampleUseCases: ["Contact lists", "Product catalogs", "Directory search"]
        )
    }

    // MARK: - Navigation Patterns
}
