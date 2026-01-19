//
//  FeedbackPatterns.swift
//  Breathe
//
//  Feedback pattern examples extracted from CommonPatterns.swift
//  Phase 3.6 Architecture Refactoring
//

import Foundation

@MainActor
extension CommonPatternsLibrary {
    // MARK: - Feedback Patterns

    static func loadingStatePattern() -> UIPattern {
        UIPattern(
            name: "Loading State",
            category: .feedback,
            description: "Loading indicator with message",
            complexity: .simple,
            codeTemplate: """
struct LoadingStateView: View {
    @State private var isLoading = true
    @State private var loadingMessage = "Loading data..."

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .aware("loading-spinner", label: "Loading Indicator")
                    .scaleEffect(1.5)

                Text(loadingMessage)
                    .aware("loading-message", label: "Loading Message")
                    .awareState("loading-message", key: "text", value: loadingMessage)
                    .font(.caption)
            } else {
                ContentView()
            }
        }
        .awareContainer("loading-state-view", label: "Loading State View")
        .awareState("loading-state-view", key: "isLoading", value: isLoading)
    }
}
""",
            elements: ["VStack", "ProgressView", "Text"],
            modifiersUsed: [".aware", ".awareState", ".awareContainer"],
            bestPractices: [
                "Track isLoading state",
                "Show descriptive message",
                "Track message text",
                "Show progress indicator"
            ],
            commonMistakes: [
                "Not tracking loading state",
                "Missing loading message",
                "No progress indicator"
            ],
            tokenEstimate: 108,
            exampleUseCases: ["Data loading", "Network requests", "Async operations"]
        )
    }

    static func errorStatePattern() -> UIPattern {
        UIPattern(
            name: "Error State",
            category: .feedback,
            description: "Error display with retry action",
            complexity: .simple,
            codeTemplate: """
struct ErrorStateView: View {
    @State private var hasError = true
    @State private var errorMessage = "Failed to load data"
    @State private var canRetry = true

    var body: some View {
        VStack(spacing: 20) {
            if hasError {
                Image(systemName: "exclamationmark.triangle")
                    .aware("error-icon", label: "Error Icon")
                    .font(.system(size: 50))
                    .foregroundColor(.red)

                Text(errorMessage)
                    .aware("error-message", label: "Error Message")
                    .awareState("error-message", key: "text", value: errorMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if canRetry {
                    Button("Retry") {
                        retry()
                    }
                    .awareButton("retry-button", label: "Retry")
                    .awareMetadata("retry-button", description: "Retries failed operation", type: "action")
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ContentView()
            }
        }
        .awareContainer("error-state-view", label: "Error State View")
        .awareState("error-state-view", key: "hasError", value: hasError)
        .awareState("error-state-view", key: "canRetry", value: canRetry)
        .padding()
    }

    func retry() {
        // Implementation
    }
}
""",
            elements: ["VStack", "Image", "Text", "Button"],
            modifiersUsed: [".aware", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Track hasError state",
                "Show descriptive error message",
                "Provide retry action",
                "Track canRetry state"
            ],
            commonMistakes: [
                "Not tracking error state",
                "Generic error messages",
                "No retry option",
                "Missing error tracking"
            ],
            tokenEstimate: 144,
            exampleUseCases: ["Network errors", "Failed operations", "Data loading errors"]
        )
    }

    static func emptyStatePattern() -> UIPattern {
        UIPattern(
            name: "Empty State",
            category: .feedback,
            description: "Empty state with call-to-action",
            complexity: .simple,
            codeTemplate: """
struct EmptyStateView: View {
    @State private var isEmpty = true
    @State private var emptyMessage = "No items yet"

    var body: some View {
        VStack(spacing: 20) {
            if isEmpty {
                Image(systemName: "tray")
                    .aware("empty-icon", label: "Empty State Icon")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)

                Text(emptyMessage)
                    .aware("empty-message", label: "Empty State Message")
                    .awareState("empty-message", key: "text", value: emptyMessage)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Button("Add Item") {
                    addItem()
                }
                .awareButton("add-item-button", label: "Add Item")
                .awareMetadata("add-item-button", description: "Creates first item", type: "action")
                .buttonStyle(.borderedProminent)
            } else {
                ContentView()
            }
        }
        .awareContainer("empty-state-view", label: "Empty State View")
        .awareState("empty-state-view", key: "isEmpty", value: isEmpty)
        .padding()
    }

    func addItem() {
        // Implementation
    }
}
""",
            elements: ["VStack", "Image", "Text", "Button"],
            modifiersUsed: [".aware", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Track isEmpty state",
                "Show helpful empty message",
                "Provide call-to-action",
                "Use descriptive icon"
            ],
            commonMistakes: [
                "Not tracking empty state",
                "Missing CTA button",
                "Unhelpful message",
                "No visual indicator"
            ],
            tokenEstimate: 126,
            exampleUseCases: ["Empty lists", "No data states", "First-time user experience"]
        )
    }
}
