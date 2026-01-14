# TDD with Aware: Test-Driven Development Guide

**Version:** 1.0.0
**Last Updated:** 2026-01-14

> 🎯 **Philosophy**: Write tests BEFORE implementation. Aware makes this natural by capturing UI state as text, enabling rapid test → implement → verify cycles.

## Table of Contents

1. [Why TDD with Aware?](#why-tdd-with-aware)
2. [The TDD Cycle](#the-tdd-cycle)
3. [Getting Started](#getting-started)
4. [Example: Login Form TDD](#example-login-form-tdd)
5. [Token Efficiency in TDD](#token-efficiency-in-tdd)
6. [Testing Patterns](#testing-patterns)
7. [Best Practices](#best-practices)

---

## Why TDD with Aware?

Traditional UI testing with screenshots is **expensive and slow**:
- ❌ 15,000 tokens per test
- ❌ $0.045 per test run
- ❌ 1000 tests = $45

Aware enables **affordable, rapid TDD**:
- ✅ 110 tokens per test
- ✅ $0.00033 per test run
- ✅ 1000 tests = $0.33

**Result**: Run **136x more tests** for the same cost!

### Key Benefits

1. **Write Tests First** - Define expected behavior before implementation
2. **Rapid Feedback** - Snapshots in milliseconds, not seconds
3. **Token Efficient** - 99.3% reduction vs screenshots
4. **LLM-Friendly** - LLMs can read snapshots and verify behavior
5. **Confidence** - Refactor safely with comprehensive test coverage

---

## The TDD Cycle

```
┌─────────────────────────────────────────────┐
│ 1. RED: Write failing test                 │
│    ↓                                        │
│ 2. GREEN: Implement minimum code to pass   │
│    ↓                                        │
│ 3. REFACTOR: Improve code while tests pass │
│    ↓                                        │
│ 4. REPEAT                                   │
└─────────────────────────────────────────────┘
```

### Why This Works with Aware

- **Red Phase**: Test describes desired UI state
- **Green Phase**: Implement view with `.aware*()` modifiers
- **Refactor Phase**: Snapshots catch regressions instantly

---

## Getting Started

### 1. Install Aware

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/adrian-mei/Aware", from: "3.0.0")
]
```

### 2. Write Your First Test (Red Phase)

```swift
import XCTest
@testable import MyApp
import AwareCore

@MainActor
final class LoginViewTests: XCTestCase {

    func testLoginFormHasEmailAndPasswordFields() async {
        // GIVEN: LoginView is displayed
        let view = LoginView()

        // WHEN: We capture the snapshot
        let snapshot = Aware.shared.captureSnapshot(format: .compact)

        // THEN: Email and password fields exist
        XCTAssertTrue(snapshot.content.contains("email-field"))
        XCTAssertTrue(snapshot.content.contains("password-field"))
        XCTAssertTrue(snapshot.content.contains("login-btn"))
    }
}
```

**Run test** → ❌ **FAILS** (view doesn't exist yet)

### 3. Implement View (Green Phase)

```swift
import SwiftUI
import Aware

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email, label: "Email")

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password, label: "Password")

            Button("Login") { login() }
                .awareButton("login-btn", label: "Login")
        }
    }

    private func login() {
        // TODO: Implement
    }
}
```

**Run test** → ✅ **PASSES**

### 4. Refactor (Refactor Phase)

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            // Extract reusable form field style
            FormField(title: "Email", text: $email, viewId: "email-field")
            FormField(title: "Password", text: $password, viewId: "password-field", isSecure: true)

            PrimaryButton("Login", action: login)
                .awareButton("login-btn", label: "Login")
        }
        .padding()
    }
}
```

**Run test** → ✅ **STILL PASSES** (safe refactoring!)

---

## Example: Login Form TDD

Let's build a complete login form using TDD with Aware.

### Step 1: Write Test for Email Validation (Red)

```swift
func testEmailValidationShowsErrorForInvalidEmail() async {
    // GIVEN: LoginView with invalid email
    let view = LoginView()

    // WHEN: User types invalid email and attempts login
    await Aware.shared.typeText(viewId: "email-field", text: "notanemail")
    await Aware.shared.tap(viewId: "login-btn")

    // Wait for validation
    try? await Task.sleep(for: .milliseconds(100))

    // THEN: Error message appears
    let errorVisible = Aware.shared.assertExists("error-message")
    XCTAssertTrue(errorVisible.passed, "Error message should be visible")

    let errorText = Aware.shared.getStateString("error-message", key: "text")
    XCTAssertEqual(errorText, "Invalid email address")
}
```

**Run test** → ❌ **FAILS** (no validation logic yet)

### Step 2: Implement Validation (Green)

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email, label: "Email")

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password, label: "Password")

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .aware("error-message", label: "Error")
                    .awareState("error-message", key: "text", value: errorMessage)
            }

            Button("Login") { login() }
                .awareButton("login-btn", label: "Login")
        }
    }

    private func login() {
        // Validate email
        if !email.contains("@") {
            errorMessage = "Invalid email address"
            return
        }

        // TODO: Authenticate
    }
}
```

**Run test** → ✅ **PASSES**

### Step 3: Add Loading State Test (Red)

```swift
func testLoginShowsLoadingStateWhileAuthenticating() async {
    // GIVEN: LoginView with valid credentials
    await Aware.shared.typeText(viewId: "email-field", text: "user@example.com")
    await Aware.shared.typeText(viewId: "password-field", text: "password123")

    // WHEN: User taps login
    await Aware.shared.tap(viewId: "login-btn")

    // THEN: Loading state appears immediately
    let isLoading = Aware.shared.getStateBool("login-form", key: "isLoading")
    XCTAssertTrue(isLoading == true, "Should show loading state")

    // AND: Login button is disabled
    let btnEnabled = Aware.shared.getStateBool("login-btn", key: "isEnabled")
    XCTAssertFalse(btnEnabled == true, "Login button should be disabled")
}
```

**Run test** → ❌ **FAILS** (no loading state yet)

### Step 4: Implement Loading State (Green)

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email, label: "Email")
                .disabled(isLoading)

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password, label: "Password")
                .disabled(isLoading)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .aware("error-message", label: "Error")
                    .awareState("error-message", key: "text", value: errorMessage)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                }
            }
            .disabled(isLoading)
            .awareButton("login-btn", label: "Login")
            .awareState("login-btn", key: "isEnabled", value: !isLoading)
        }
        .awareContainer("login-form", label: "Login Form")
        .awareState("login-form", key: "isLoading", value: isLoading)
    }

    private func login() {
        if !email.contains("@") {
            errorMessage = "Invalid email address"
            return
        }

        isLoading = true
        errorMessage = ""

        Task { @MainActor in
            // Simulate network request
            try? await Task.sleep(for: .seconds(1))

            // TODO: Real authentication
            isLoading = false
        }
    }
}
```

**Run test** → ✅ **PASSES**

### Step 5: Complete Flow with Test Suite

```swift
final class LoginViewTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Reset Aware state between tests
        Aware.shared.reset()
    }

    func testLoginFormExists() async {
        // Test form structure
        XCTAssertTrue(Aware.shared.assertExists("login-form").passed)
        XCTAssertTrue(Aware.shared.assertExists("email-field").passed)
        XCTAssertTrue(Aware.shared.assertExists("password-field").passed)
        XCTAssertTrue(Aware.shared.assertExists("login-btn").passed)
    }

    func testEmailValidation() async {
        await Aware.shared.typeText(viewId: "email-field", text: "invalid")
        await Aware.shared.tap(viewId: "login-btn")

        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(Aware.shared.assertExists("error-message").passed)
    }

    func testLoadingState() async {
        await Aware.shared.typeText(viewId: "email-field", text: "user@example.com")
        await Aware.shared.typeText(viewId: "password-field", text: "password123")
        await Aware.shared.tap(viewId: "login-btn")

        let isLoading = Aware.shared.getStateBool("login-form", key: "isLoading")
        XCTAssertTrue(isLoading == true)
    }

    func testSuccessfulLogin() async {
        // Test complete authentication flow
        await Aware.shared.typeText(viewId: "email-field", text: "user@example.com")
        await Aware.shared.typeText(viewId: "password-field", text: "password123")
        await Aware.shared.tap(viewId: "login-btn")

        // Wait for auth
        try? await Task.sleep(for: .seconds(1.5))

        // Verify success state
        let isAuthenticated = Aware.shared.getStateBool("login-form", key: "isAuthenticated")
        XCTAssertTrue(isAuthenticated == true)
    }
}
```

---

## Token Efficiency in TDD

### Cost Comparison

**Traditional Screenshot-Based Testing:**
```
Login form test (1 screenshot):
- 2048x1536 image = 15,000 tokens
- Cost per test: $0.045 (at $3/M tokens)
- 1000 tests: $45.00
```

**Aware Compact Snapshot:**
```swift
let snapshot = Aware.shared.captureSnapshot(format: .compact)
// Example output (~110 tokens):
// login-form{email-field:email="",password-field:pwd="",login-btn:enabled=true,isLoading=false}

- Login form snapshot = 110 tokens
- Cost per test: $0.00033
- 1000 tests: $0.33
```

**Savings**: 99.3% reduction, **$44.67 saved per 1000 tests**

### Running 1000 TDD Tests

With Aware, you can afford to:
- ✅ Run full test suite on every commit
- ✅ Test edge cases exhaustively
- ✅ Use TDD for rapid iteration
- ✅ Let LLMs write and verify tests

**ROI Example:**
- Team runs 100 tests/day × 20 days/month = 2000 tests
- Screenshot cost: $90/month
- Aware cost: $0.66/month
- **Savings: $89.34/month per developer**

---

## Testing Patterns

### Pattern 1: View Structure Tests

```swift
func testViewHasExpectedElements() {
    let snapshot = Aware.shared.captureSnapshot(format: .compact)

    // Assert elements exist
    XCTAssertTrue(snapshot.content.contains("email-field"))
    XCTAssertTrue(snapshot.content.contains("password-field"))
    XCTAssertTrue(snapshot.content.contains("login-btn"))
}
```

### Pattern 2: State Validation Tests

```swift
func testLoadingStateDisablesInputs() async {
    // Trigger loading
    await Aware.shared.tap(viewId: "login-btn")

    // Verify state
    XCTAssertTrue(Aware.shared.getStateBool("login-form", key: "isLoading") == true)
    XCTAssertFalse(Aware.shared.getStateBool("email-field", key: "isEnabled") == true)
    XCTAssertFalse(Aware.shared.getStateBool("login-btn", key: "isEnabled") == true)
}
```

### Pattern 3: User Flow Tests

```swift
func testCompleteLoginFlow() async {
    // Step 1: Enter credentials
    await Aware.shared.typeText(viewId: "email-field", text: "user@example.com")
    await Aware.shared.typeText(viewId: "password-field", text: "password123")

    // Step 2: Submit
    await Aware.shared.tap(viewId: "login-btn")

    // Step 3: Wait for loading
    try? await Task.sleep(for: .seconds(1.5))

    // Step 4: Verify success
    XCTAssertTrue(Aware.shared.getStateBool("login-form", key: "isAuthenticated") == true)
}
```

### Pattern 4: Error Handling Tests

```swift
func testNetworkErrorShowsRetryOption() async {
    // Simulate network failure
    NetworkMock.shared.shouldFail = true

    await Aware.shared.tap(viewId: "login-btn")
    try? await Task.sleep(for: .seconds(1))

    // Verify error UI
    XCTAssertTrue(Aware.shared.assertExists("error-message").passed)
    XCTAssertTrue(Aware.shared.assertExists("retry-btn").passed)
}
```

### Pattern 5: Performance Tests

```swift
func testLoginActionCompletesWithinBudget() async {
    let startTime = Date()

    await Aware.shared.tap(viewId: "login-btn")

    let duration = Date().timeIntervalSince(startTime)
    XCTAssertLessThan(duration, 0.25, "Login action should complete in <250ms")
}
```

---

## Best Practices

### 1. Write Tests First

❌ **Don't:**
```swift
// Implement view first, then add tests
struct MyView: View { ... }
// Later: Write tests
```

✅ **Do:**
```swift
// Write test first
func testMyViewShowsTitle() {
    XCTAssertTrue(Aware.shared.assertExists("title").passed)
}
// Then: Implement view to pass test
```

### 2. Use Descriptive View IDs

❌ **Don't:**
```swift
.aware("btn1", label: "Button")
.aware("txt", label: "Text")
```

✅ **Do:**
```swift
.awareButton("login-submit-btn", label: "Login")
.awareTextField("user-email-field", text: $email, label: "Email")
```

### 3. Test State, Not Implementation

❌ **Don't:**
```swift
func testButtonCallsLoginFunction() {
    // Testing implementation details
}
```

✅ **Do:**
```swift
func testButtonTriggersLoadingState() async {
    await Aware.shared.tap(viewId: "login-btn")
    XCTAssertTrue(Aware.shared.getStateBool("form", key: "isLoading") == true)
}
```

### 4. Keep Tests Isolated

❌ **Don't:**
```swift
func testLoginAndNavigationAndProfile() {
    // Testing too much at once
}
```

✅ **Do:**
```swift
func testLoginShowsLoadingState() { ... }
func testLoginNavigatesToDashboard() { ... }
func testDashboardLoadsProfile() { ... }
```

### 5. Use Setup/Teardown

```swift
class MyViewTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        Aware.shared.reset()  // Clean slate for each test
    }

    override func tearDown() async throws {
        // Cleanup if needed
        try await super.tearDown()
    }
}
```

---

## Real-World Example: iOS Platform Tests

See `AwareiOS/Tests/AwareiOSTests/` for 65+ production tests demonstrating TDD:

```swift
// AwareIOSPlatformTests.swift - 25 tests
func testConfigurationWithDefaultSettings() { ... }
func testRegisterActionCallback() async { ... }
func testExecuteUnregisteredAction() async { ... }

// AwareIOSBridgeTests.swift - 20 tests
func testBridgeInitializesWithValidConfig() { ... }
func testHeartbeatWritesTimestamp() async { ... }
func testCommandFileCreation() async { ... }

// AwareIOSBasicModifiersTests.swift - 20 tests
func testButtonModifierRegistersView() { ... }
func testTextFieldTracksValue() async { ... }
func testToggleTracksState() async { ... }
```

**Result:** 65 tests validating iOS platform, all written TDD-style.

---

## Summary

**TDD with Aware in 3 steps:**

1. **RED**: Write test describing expected UI state
2. **GREEN**: Implement view with `.aware*()` modifiers
3. **REFACTOR**: Improve code, snapshots catch regressions

**Benefits:**
- 99.3% token reduction vs screenshots
- $89/month savings per developer
- Rapid feedback loops
- Safe refactoring with confidence
- LLM-friendly test validation

**Get Started:**
```bash
# 1. Install Aware
# 2. Write your first test
# 3. Make it pass
# 4. Refactor with confidence
```

Happy TDD-ing! 🧪✨

---

**Questions?** See [CLAUDE.md](CLAUDE.md) for full framework documentation.
