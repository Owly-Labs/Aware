//
//  SettingsPatterns.swift
//  Breathe
//
//  Settings pattern examples extracted from CommonPatterns.swift
//  Phase 3.6 Architecture Refactoring
//

import Foundation

@MainActor
extension CommonPatternsLibrary {
    // MARK: - Settings Patterns

    static func settingsPanelPattern() -> UIPattern {
        UIPattern(
            name: "Settings Panel",
            category: .settings,
            description: "Standard settings screen with grouped options",
            complexity: .simple,
            codeTemplate: """
struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var fontSize = 14.0

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .awareToggle("notifications-toggle", isOn: $notificationsEnabled, label: "Enable Notifications")
            }
            .awareContainer("notifications-section", label: "Notifications Section")

            Section("Appearance") {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                    .awareToggle("dark-mode-toggle", isOn: $darkModeEnabled, label: "Dark Mode")

                Slider(value: $fontSize, in: 10...20, step: 1) {
                    Text("Font Size")
                }
                .awareState("font-size-slider", key: "value", value: fontSize)
            }
            .awareContainer("appearance-section", label: "Appearance Section")
        }
        .awareContainer("settings-view", label: "Settings View")
    }
}
""",
            elements: ["Form", "Section", "Toggle", "Slider", "Text"],
            modifiersUsed: [".awareToggle", ".awareState", ".awareContainer"],
            bestPractices: [
                "Group settings into sections",
                "Use .awareToggle() for boolean settings",
                "Track slider values with .awareState()",
                "Use semantic section names"
            ],
            commonMistakes: [
                "Not tracking toggle states",
                "Not tracking slider values",
                "Missing section organization"
            ],
            tokenEstimate: 180,
            exampleUseCases: ["App preferences", "User settings", "Configuration panels"]
        )
    }

    static func preferencesGroupPattern() -> UIPattern {
        UIPattern(
            name: "Preferences Group",
            category: .settings,
            description: "Grouped preferences with labels",
            complexity: .simple,
            codeTemplate: """
struct PreferencesGroupView: View {
    @State private var option1 = true
    @State private var option2 = false
    @State private var selection = 0

    var body: some View {
        Form {
            Section("Options") {
                Toggle("Option 1", isOn: $option1)
                    .awareToggle("option-1-toggle", isOn: $option1, label: "Option 1")

                Toggle("Option 2", isOn: $option2)
                    .awareToggle("option-2-toggle", isOn: $option2, label: "Option 2")
            }
            .awareContainer("options-section", label: "Options Section")

            Section("Choice") {
                Picker("Select", selection: $selection) {
                    Text("Choice A").tag(0)
                    Text("Choice B").tag(1)
                    Text("Choice C").tag(2)
                }
                .awareState("selection-picker", key: "value", value: selection)
            }
            .awareContainer("choice-section", label: "Choice Section")
        }
        .awareContainer("preferences-group", label: "Preferences Group")
    }
}
""",
            elements: ["Form", "Section", "Toggle", "Picker", "Text"],
            modifiersUsed: [".awareToggle", ".awareState", ".awareContainer"],
            bestPractices: [
                "Group related preferences",
                "Track all toggle states",
                "Track picker selections",
                "Use descriptive labels"
            ],
            commonMistakes: [
                "Not tracking picker state",
                "Missing preference labels",
                "Not grouping logically"
            ],
            tokenEstimate: 162,
            exampleUseCases: ["Settings groups", "Preference panels", "Configuration"]
        )
    }

    // MARK: - Feedback Patterns
}
