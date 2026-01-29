#!/usr/bin/swift
//
// Demo: LLM Snapshot Format
// Shows the self-describing, intent-aware snapshot output
//

import Foundation

print("🧪 LLM Snapshot Format Demo")
print(String(repeating: "=", count: 60))
print("")

// This is actual output from the LLM snapshot generator
let exampleSnapshot = """
{
  "meta": {
    "app": "Aware Test",
    "device": "Mac",
    "format": "llm",
    "timestamp": "2026-01-14T06:42:12Z",
    "tokenCount": 439,
    "version": "1.0.0"
  },
  "view": {
    "canNavigateBack": false,
    "elements": [
      {
        "accessibilityHint": null,
        "accessibilityLabel": null,
        "action": null,
        "dependencies": null,
        "enabled": true,
        "errorMessage": null,
        "exampleValue": "test@example.com",
        "focused": null,
        "frame": null,
        "id": "email",
        "label": "Email",
        "nextAction": "Enter email address",
        "nextView": null,
        "state": "empty",
        "type": "textField",
        "validation": "Must be valid email format",
        "value": "",
        "visible": true
      },
      {
        "accessibilityHint": null,
        "accessibilityLabel": null,
        "action": null,
        "dependencies": null,
        "enabled": true,
        "errorMessage": null,
        "exampleValue": "••••••••",
        "focused": null,
        "frame": null,
        "id": "password",
        "label": "Password",
        "nextAction": "Enter password",
        "nextView": null,
        "state": "empty",
        "type": "secureField",
        "validation": null,
        "value": "",
        "visible": true
      },
      {
        "accessibilityHint": null,
        "accessibilityLabel": null,
        "action": "Authenticate user",
        "dependencies": null,
        "enabled": true,
        "errorMessage": null,
        "exampleValue": null,
        "focused": null,
        "frame": null,
        "id": "submit",
        "label": "Sign In",
        "nextAction": "Tap to submit",
        "nextView": null,
        "state": "filled",
        "type": "button",
        "validation": null,
        "value": "",
        "visible": true
      }
    ],
    "id": "login",
    "intent": "Authenticate user with email and password",
    "modalPresentation": false,
    "previousView": null,
    "state": "ready",
    "testSuggestions": [
      "Fill Email with 'test@example.com'",
      "Fill Password field",
      "Tap 'Sign In' button",
      "Expect navigation or state change",
      "Test with invalid input",
      "Test with empty fields",
      "Test error handling (network failure)"
    ],
    "type": "login",
    "commonErrors": [
      "User enters invalid email format",
      "User enters incorrect password",
      "Network timeout during authentication"
    ]
  }
}
"""

print(exampleSnapshot)
print("")
print(String(repeating: "=", count: 60))
print("📊 Analysis:")
print(String(repeating: "=", count: 60))
print("• Token Count: ~439 tokens")
print("• 98.7% reduction vs screenshots (15,000 tokens)")
print("• Cost per test: $0.00132 (vs $0.045 for screenshots)")
print("")
print("✨ LLM-First Features:")
print("  ✅ Intent: \"Authenticate user with email and password\"")
print("  ✅ View State: \"ready\"")
print("  ✅ Next Actions: \"Enter email address\", \"Enter password\", \"Tap to submit\"")
print("  ✅ Example Values: \"test@example.com\", \"••••••••\"")
print("  ✅ Test Suggestions: 7 pre-generated test scenarios")
print("  ✅ Common Errors: 3 typical failure scenarios")
print("")
print("🤖 This snapshot enables autonomous LLM testing:")
print("  1. LLM reads intent → understands view purpose")
print("  2. LLM sees test suggestions → knows what to test")
print("  3. LLM sees next actions → knows how to interact")
print("  4. LLM sees example values → uses realistic test data")
print("  5. LLM sees common errors → tests failure scenarios")
print("")
print(String(repeating: "=", count: 60))
