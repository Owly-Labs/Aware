#!/usr/bin/swift

import Foundation

// Current snapshot from demo
let currentSnapshot = """
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

// Optimized version - remove null fields, shorten keys, omit defaults
let optimizedSnapshot = """
{
  "view": {
    "id": "login",
    "intent": "Authenticate user with email and password",
    "state": "ready",
    "elements": [
      {
        "id": "email",
        "type": "textField",
        "label": "Email",
        "state": "empty",
        "next": "Enter email address",
        "example": "test@example.com",
        "validation": "Must be valid email format"
      },
      {
        "id": "password",
        "type": "secureField",
        "label": "Password",
        "state": "empty",
        "next": "Enter password",
        "example": "••••••••"
      },
      {
        "id": "submit",
        "type": "button",
        "label": "Sign In",
        "state": "filled",
        "next": "Tap to submit",
        "action": "Authenticate user"
      }
    ],
    "tests": [
      "Fill Email with 'test@example.com'",
      "Fill Password field",
      "Tap 'Sign In' button",
      "Expect navigation or state change",
      "Test with invalid input",
      "Test with empty fields",
      "Test error handling (network failure)"
    ],
    "errors": [
      "User enters invalid email format",
      "User enters incorrect password",
      "Network timeout during authentication"
    ]
  }
}
"""

print("📊 Token Usage Analysis")
print(String(repeating: "=", count: 60))
print()

let currentTokens = currentSnapshot.count / 4
let optimizedTokens = optimizedSnapshot.count / 4
let reduction = currentTokens - optimizedTokens
let reductionPercent = Double(reduction) / Double(currentTokens) * 100

print("Current Snapshot:")
print("  Characters: \(currentSnapshot.count)")
print("  Estimated Tokens: ~\(currentTokens)")
print()

print("Optimized Snapshot:")
print("  Characters: \(optimizedSnapshot.count)")
print("  Estimated Tokens: ~\(optimizedTokens)")
print()

print(String(repeating: "=", count: 60))
print("Token Reduction:")
print("  Removed: \(reduction) tokens (\(String(format: "%.1f", reductionPercent))%)")
print("  New vs Screenshot: \(String(format: "%.1f", Double(15000 - optimizedTokens) / 15000 * 100))% reduction")
print(String(repeating: "=", count: 60))
print()

print("✨ Optimizations Applied:")
print("  1. Removed null fields (accessibilityHint, frame, etc.)")
print("  2. Removed default boolean values (enabled: true, visible: true)")
print("  3. Removed empty string values (value: \"\")")
print("  4. Shortened field names:")
print("     - nextAction → next")
print("     - exampleValue → example")
print("     - testSuggestions → tests")
print("     - commonErrors → errors")
print("  5. Removed verbose meta object")
print("  6. Removed redundant view metadata (modalPresentation, previousView)")
print()

print("🎯 Target Achievement:")
if optimizedTokens >= 150 && optimizedTokens <= 250 {
    print("  ✅ Within ideal range (150-250 tokens)")
} else if optimizedTokens < 200 {
    print("  ✅ Below 200 token target!")
} else {
    print("  ⚠️  Still above 200 tokens, more optimization needed")
}
