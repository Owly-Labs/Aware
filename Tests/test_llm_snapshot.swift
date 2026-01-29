#!/usr/bin/env swift

import Foundation

// Add path to Aware framework
#if os(macOS)
import AwareCore
#endif

@MainActor
func testLLMSnapshot() async {
    print("🧪 Testing LLM Snapshot Format\n")
    print("=" * 60)

    // Register a simple login view
    print("\n📝 Registering test views...")

    Aware.shared.registerView("login-view", label: "Login")

    Aware.shared.registerView("email-field", label: "Email", parentId: "login-view")
    Aware.shared.registerState("email-field", key: "placeholder", value: "your@email.com")
    Aware.shared.registerState("email-field", key: "required", value: "true")
    Aware.shared.registerState("email-field", key: "validation", value: "email")

    Aware.shared.registerView("password-field", label: "Password", parentId: "login-view")
    Aware.shared.registerState("password-field", key: "placeholder", value: "Enter password")
    Aware.shared.registerState("password-field", key: "required", value: "true")

    Aware.shared.registerView("submit-button", label: "Sign In", parentId: "login-view")
    Aware.shared.registerState("submit-button", key: "enabled", value: "true")
    Aware.shared.registerState("submit-button", key: "action", value: "authenticate")

    print("✅ Registered 4 views (1 parent + 3 children)")

    // Generate LLM snapshot
    print("\n🤖 Generating LLM-optimized snapshot...")
    let json = await Aware.shared.generateLLMSnapshot()

    // Calculate token count
    let tokenCount = json.count / 4
    print("\n📊 Snapshot Statistics:")
    print("   Characters: \(json.count)")
    print("   Estimated Tokens: ~\(tokenCount)")
    print("   Target Range: 200-500 tokens")

    if tokenCount >= 200 && tokenCount <= 500 {
        print("   ✅ Within target range!")
    } else if tokenCount < 200 {
        print("   ⚠️  Below target (may be missing features)")
    } else {
        print("   ⚠️  Above target (could be optimized)")
    }

    // Parse and display
    print("\n📄 Snapshot Content:")
    print("=" * 60)

    if let data = json.data(using: .utf8),
       let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

        // Pretty print with indentation
        if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {

            // Show first 2000 characters
            let preview = prettyString.prefix(2000)
            print(preview)

            if prettyString.count > 2000 {
                print("\n... (\(prettyString.count - 2000) more characters)")
            }
        }

        // Extract key information
        if let view = jsonObject["view"] as? [String: Any] {
            print("\n" + "=" * 60)
            print("📋 Key Information:")
            print("=" * 60)

            if let intent = view["intent"] as? String {
                print("🎯 Intent: \(intent)")
            }

            if let state = view["state"] as? String {
                print("🔄 State: \(state)")
            }

            if let suggestions = view["testSuggestions"] as? [String] {
                print("💡 Test Suggestions (\(suggestions.count)):")
                for (i, suggestion) in suggestions.enumerated() {
                    print("   \(i + 1). \(suggestion)")
                }
            }

            if let errors = view["commonErrors"] as? [String] {
                print("⚠️  Common Errors (\(errors.count)):")
                for (i, error) in errors.enumerated() {
                    print("   \(i + 1). \(error)")
                }
            }

            if let elements = view["elements"] as? [[String: Any]] {
                print("🧩 Elements (\(elements.count)):")
                for element in elements {
                    if let id = element["id"] as? String,
                       let label = element["label"] as? String,
                       let nextAction = element["nextAction"] as? String {
                        print("   • \(label) (\(id))")
                        print("     → \(nextAction)")
                        if let example = element["exampleValue"] as? String {
                            print("     📝 Example: \(example)")
                        }
                    }
                }
            }
        }
    } else {
        print("❌ Failed to parse JSON")
        print(json)
    }

    print("\n" + "=" * 60)
    print("✅ Test Complete!")
}

// Run the test
await testLLMSnapshot()
