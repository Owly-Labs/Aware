# Aware Framework

SwiftUI instrumentation framework for LLM-driven UI testing.

> ⚠️ **Development Beta (v3.0.0-beta)**: This is an active development release. APIs and features are subject to change. Not recommended for production use yet.

## Core Philosophy
- **Ghost UI**: LLM tests without moving mouse
- **80% Token Reduction**: 100-120 tokens vs 500-600 for screenshots
- **Rich State**: Exact values, not visual appearance
- **Staleness Detection**: Know when @State fails to update

## v3.0 LLM-First API 🎯 NEW

Week 3 brought major API improvements optimized for LLM consumption:

### Explicit Action Methods
Replace generic `executeAction()` with 21 type-safe methods:
```swift
// Before (v2.x)
await Aware.shared.executeAction(AwareCommand(action: "tap", viewId: "button"))

// After (v3.0)
let result = await Aware.shared.tap(viewId: "button")  // Returns AwareTapResult
```

**Available Methods:**
- **Tap**: `tap()`, `longPress()`, `doubleTap()`, `swipe()`
- **Text**: `setText()`, `appendText()`, `clearText()`, `typeText()`
- **Focus**: `focus()`, `blurFocus()`, `focusNextField()`, `focusPreviousField()`
- **Navigation**: `navigateBack()`, `dismissModal()`
- **Query**: `find()`, `snapshot()`
- **Assertions**: `assertExists()`, `assertVisible()`, `assertState()`, `assertViewCount()`

### Type-Safe State Tracking
Eliminates string parsing confusion with `AwareStateValue` enum:
```swift
// Before (v2.x) - string confusion
Aware.shared.registerState("toggle", key: "isOn", value: "true")
let state = Aware.shared.getStateValue("toggle", key: "isOn")  // Returns "true" (String)

// After (v3.0) - type-safe
Aware.shared.registerStateTyped("toggle", key: "isOn", value: .bool(true))
if let isOn = Aware.shared.getStateBool("toggle", key: "isOn") {  // Returns Bool
    print("Toggle is: \(isOn)")
}
```

**Supported Types:** `.string`, `.int`, `.double`, `.bool`, `.data`, `.array`, `.dictionary`, `.null`

### Hierarchical Error System
Category-based routing for better LLM error handling:
```swift
// Before (v2.x) - flat errors
catch AwareError.viewRegistrationFailed(let reason, let viewId)

// After (v3.0) - hierarchical
catch AwareErrorV3.registration(.viewRegistrationFailed(let reason, let viewId))

// Route by category
switch error.category {
case .registration: // Handle all registration errors
case .state: // Handle all state errors
case .action: // Handle all action errors
// ...
}
```

**10 Categories:** registration, state, action, input, query, snapshot, animation, backend, configuration, system

### Enhanced Metadata
Rich semantic information for LLM decision-making:
```swift
let saveAction = AwareActionMetadataV2(
    actionDescription: "Saves document to cloud",
    actionType: .network,
    expectedDurationMs: 1500,
    preconditions: ["document.hasChanges", "user.isOnline"],
    riskLevel: .medium,
    impactLevel: .major,
    isIdempotent: true,
    maxRetries: 3
)
```

### Token Efficiency
- Snapshot API defaults to `.compact` (50% token savings)
- Compact state representation: 3-8 tokens vs 10-15
- Error messages: 15-20 tokens vs 40-60

## Monorepo Architecture

Aware is now organized as a modular monorepo with independent package versioning:

| Package | Version | Platform | Purpose |
|---------|---------|----------|---------|
| **AwareCore** | v3.0.0-beta | Swift | Platform-agnostic foundation with v3.0 LLM-First API |
| **AwareiOS** | v2.2.0-beta | iOS 17+ | iOS with UIViewID enum, .ui*() modifiers, typeText support |
| **AwareMacOS** | v2.0.3-beta | macOS 14+ | macOS-specific implementation with CGEvent simulation |
| **AwareBackendClient** | v1.0.0-beta | Cross-platform | HTTP client for BackendAware REST API |
| **AwareBridge** | v1.0.0-beta | Cross-platform | WebSocket IPC for real-time communication (<5ms) |
| **Aware** | v3.0.0-beta | Umbrella | Backward-compatible re-export facade with v3.0 APIs |

### Importing Packages

**Simple (recommended for most users):**
```swift
import Aware  // Auto-imports correct platform module
```

**Granular (for advanced use cases):**
```swift
import AwareCore           // Types and protocols only
import AwareiOS            // iOS-specific features
import AwareMacOS          // macOS-specific features
import AwareBackendClient  // Backend HTTP client
```

### Independent Versioning

Each package versions independently:
- Upgrade iOS to v2.1.0 without affecting macOS at v2.0.3
- Core types remain stable across platform updates
- Backend client evolves separately from UI instrumentation

## Installation

### Swift Package Manager

**Umbrella package (recommended):**
```swift
dependencies: [
    .package(url: "https://github.com/adrian-mei/Aware", from: "3.0.0-beta")
]

// In your target
.target(
    name: "MyApp",
    dependencies: ["Aware"]  // Auto-imports correct platform
)
```

**Specific packages:**
```swift
dependencies: [
    .package(url: "https://github.com/adrian-mei/Aware", from: "3.0.0-beta")
]

// In your target
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "AwareCore", package: "Aware"),
        .product(name: "AwareiOS", package: "Aware"),
        .product(name: "AwareBackendClient", package: "Aware")
    ]
)
```

## Quick Start

### Basic Instrumentation
```swift
import Aware

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email, label: "Email", isFocused: $focusedField)

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password, label: "Password")

            Button("Login") { login() }
                .awareButton("login-btn", label: "Login")
                .awareMetadata(
                    "login-btn",
                    description: "Authenticates user with email/password",
                    type: .network,
                    apiEndpoint: "/auth/login"
                )
        }
        .awareContainer("login-form", label: "Login Form")
    }
}
```

### Getting Snapshots
```swift
let snapshot = await Aware.shared.snapshot(format: .compact)
// Returns: ~100 tokens with all UI state
```

### iOS Enhanced Features (AetherSing Integration)

**Stable View Identifiers:**
```swift
import AwareiOS

// Use predefined UIViewID enum to prevent ID drift
Button("Sign In") { signIn() }
    .uiTappable(UIViewID.signInButton.rawValue, label: "Sign In") {
        await signIn()
    }

TextField("Email", text: $email)
    .uiTextField(UIViewID.emailField.rawValue,
                 text: $email,
                 label: "Email",
                 placeholder: "user@example.com")
```

**Rich State Tracking:**
```swift
Form {
    // Fields with automatic typeText binding
    TextField("Email", text: $email)
        .uiTextField(UIViewID.emailField.rawValue, text: $email, label: "Email")

    SecureField("Password", text: $password)
        .uiSecureField(UIViewID.passwordField.rawValue, text: $password, label: "Password")
}
.uiValidationState("login-form",
                   isValid: isValid,
                   errors: ["Password too short"])
.uiLoadingState("login-form",
                isLoading: isLoading,
                message: "Signing in...",
                progress: 0.7)
.uiErrorState("login-form",
              error: loginError,
              canRetry: true)
```

**TypeText Support (Ghost UI):**
```swift
// LLM can type without mouse simulation
await AwareIOSPlatform.shared.typeText(UIViewID.emailField.rawValue,
                                        text: "test@example.com")
await AwareIOSPlatform.shared.executeAction(UIViewID.signInButton.rawValue)
```

### Ghost UI Testing
```swift
// Test text input without moving mouse
await Aware.shared.typeText(viewId: "email-field", text: "user@example.com")

// Verify state
let emailState = Aware.shared.getState("email-field", key: "value")
assert(emailState == "user@example.com")
```

## Available Modifiers

| Modifier | Use Case | Example |
|----------|----------|---------|
| `.aware()` | Basic view registration | `.aware("view-id", label: "My View")` |
| `.awareContainer()` | Group related elements | `.awareContainer("form", label: "Login Form")` |
| `.awareButton()` | Track button taps | `.awareButton("save-btn", label: "Save")` |
| `.awareTextField()` | Track text input with focus | `.awareTextField("email", text: $email, label: "Email", isFocused: $focused)` |
| `.awareSecureField()` | Track password input (secure) | `.awareSecureField("pwd", text: $password, label: "Password")` |
| `.awareState()` | Track any state | `.awareState("view-id", key: "isEnabled", value: enabled)` |
| `.awareMetadata()` | Add action semantics | `.awareMetadata("btn-id", description: "Saves file", type: .fileSystem)` |
| `.awareBehavior()` | Add backend behavior | `.awareBehavior("list", dataSource: "REST API", refreshTrigger: "onAppear")` |
| `.awareFocus()` | Track focus/hover state | `.awareFocus("input-id")` |
| `.awareScroll()` | Track scroll position | `.awareScroll("scrollview-id")` |
| `.awareAnimation()` | Track animation state | `.awareAnimation("view-id", type: "spring", duration: 0.3, isAnimating: $animating)` |

### iOS Convenience Modifiers (AwareiOS only)

Rich state tracking modifiers for common UI patterns:

| Modifier | Purpose | Key State Tracked |
|----------|---------|-------------------|
| `.uiLoadingState()` | Loading with progress | isLoading, loadingMessage, loadingProgress |
| `.uiErrorState()` | Error with retry | hasError, errorMessage, canRetry |
| `.uiProcessingState()` | Multi-step processing | isProcessing, currentStep, stepProgress, totalSteps |
| `.uiValidationState()` | Form validation | isValid, errorCount, errors, warnings |
| `.uiNetworkState()` | Network connectivity | isConnected, isLoading, lastSync |
| `.uiSelectionState()` | List/collection selection | selectionCount, totalItems, allowsMultiple |
| `.uiEmptyState()` | Empty content | isEmpty, emptyMessage, canAddItems |
| `.uiAuthState()` | Authentication status | isAuthenticated, username, requiresReauth |
| `.uiTappable()` | Direct action callback | isEnabled + ghost UI support |
| `.uiTextField()` | Enhanced text field | value, placeholder, characterCount + typeText |
| `.uiSecureField()` | Enhanced secure field | hasValue, placeholder, isEnabled |
| `.uiToggle()` | Enhanced toggle | isOn, isEnabled |

**Example:**
```swift
Form {
    TextField("Email", text: $email)
        .uiTextField("email", text: $email, label: "Email", placeholder: "user@example.com")
}
.uiValidationState("form", isValid: isValid, errors: ["Email required"])
.uiLoadingState("form", isLoading: isSubmitting, message: "Submitting...", progress: 0.5)
.uiNetworkState("form", isConnected: networkMonitor.isConnected)
```

### UIViewID Enum (iOS)

Predefined stable identifiers to prevent ID drift:

**Categories:**
- **Authentication**: signInView, signUpView, emailField, passwordField, signInButton
- **Navigation**: tabBar, homeTab, searchTab, profileTab, navigationBar, backButton
- **Forms**: formView, textField, submitButton, cancelButton, saveButton, deleteButton
- **Settings**: settingsView, notificationsToggle, darkModeToggle, logoutButton
- **Loading/Error**: loadingView, errorView, retryButton, emptyStateView
- **Media**: videoPlayer, audioPlayer, playButton, pauseButton

**Usage:**
```swift
Button("Sign In") { signIn() }
    .uiTappable(UIViewID.signInButton.rawValue, label: "Sign In") {
        await signIn()
    }

// Scoped IDs
UIViewID.homeView.scoped("header")     // "homeView.header"
UIViewID.listView.indexed(0)           // "listView[0]"
UIViewID.signInButton.suffixed("primary") // "signInButton-primary"

// Custom IDs
UIViewID.custom("my-custom-id")
```

## Testing Features

### Performance Budgeting
```swift
let metrics = await AwarePerformanceMonitor.shared.measure {
    await Aware.shared.typeText(viewId: "search-field", text: "query")
}
await AwarePerformanceAsserter.shared.assertWithinBudget(metrics, budget: .standard)
```

**Budget Levels**:
- `.lenient`: 500ms (good for complex operations)
- `.standard`: 250ms (recommended for most actions)
- `.strict`: 100ms (for instant feedback)

### WCAG Accessibility Auditing
```swift
let audit = await AwareAccessibilityAuditor.shared.audit(level: .AA)
// Checks: Color contrast, touch targets, label requirements
```

**Audit Levels**:
- `.A`: Minimum compliance
- `.AA`: Recommended (WCAG 2.1 Level AA)
- `.AAA`: Enhanced accessibility

### Coverage Tracking
```swift
let coverage = await AwareCoverage.shared.getCoverage()
print("Views visited: \(coverage.visitedViews.count)/\(coverage.totalViews)")
print("Actions taken: \(coverage.actionsCovered.count)/\(coverage.totalActions)")
```

## Snapshot Formats

| Format | Token Count | Use Case |
|--------|-------------|----------|
| `compact` | 100-120 | LLM consumption (recommended) |
| `text` | 200-300 | Human-readable tree |
| `json` | 300-500 | Programmatic parsing |
| `markdown` | 250-400 | Documentation |

```swift
// Get compact snapshot for LLM
let compact = await Aware.shared.snapshot(format: .compact)

// Get JSON for programmatic use
let json = await Aware.shared.snapshot(format: .json)
```

## Advanced Features

### Focus Management
```swift
// Navigate focus programmatically
await AwareFocusManager.shared.focusNext() // Tab to next field
await AwareFocusManager.shared.focusPrevious() // Shift+Tab
await AwareFocusManager.shared.focus("email-field") // Focus specific field
```

### Action Metadata
Action metadata helps LLMs understand what buttons do before clicking them:

```swift
Button("Delete Account") { deleteAccount() }
    .awareButton("delete-btn", label: "Delete Account")
    .awareMetadata(
        "delete-btn",
        description: "Permanently deletes user account and all data",
        type: .destructive,
        isDestructive: true,
        requiresConfirmation: true,
        sideEffects: ["deletes data", "logs out", "sends email"]
    )
```

### Behavior Metadata
Behavior metadata describes data flow and backend integration:

```swift
List(users) { user in
    UserRow(user: user)
}
.awareContainer("user-list", label: "Users")
.awareBehavior(
    "user-list",
    dataSource: "REST API",
    refreshTrigger: "onAppear",
    cacheDuration: "5m",
    errorHandling: "retry(3)",
    loadingBehavior: "skeleton",
    boundModel: "User"
)
```

## iOS Platform Support (AetherSing Integration)

Aware has been enhanced with comprehensive iOS platform support, contributed by the AetherSing team. These features enable advanced SwiftUI testing on iOS devices and simulators.

### iOS Configuration

```swift
// Configure Aware for iOS platform
Aware.configureForIOS(ipcPath: "~/.aware")

// Framework automatically sets up:
// - IPC communication via ~/.aware directory
// - Heartbeat monitoring for app health
// - iOS-specific gesture and input handling
```

### iOS-Specific Modifiers

```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email,
                               label: "Email Address", placeholder: "user@example.com")

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password,
                                 label: "Password", placeholder: "••••••••")

            Toggle("Remember me", isOn: $rememberMe)
                .awareToggle("remember-toggle", isOn: $rememberMe, label: "Remember Me")

            Button("Sign In") { signIn() }
                .awareButton("signin-btn", label: "Sign In") {
                    // Direct action callback for ghost UI testing
                    signIn()
                }
        }
        .awareContainer("login-form", label: "Login Form")
    }
}
```

### iOS-Specific Assertions

```swift
// Test iOS-specific UI states
let emailFocused = await aware.assertFocused("email-field")
let passwordNotEmpty = await aware.assertTextFieldNotEmpty("password-field")
let toggleOn = await aware.assertToggleOn("remember-toggle")

// Navigation testing
let tabsPresent = await aware.assertNavigationTabsPresent()
```

### Direct Action Callbacks

```swift
// Ghost UI testing - LLMs can interact without mouse
let success = await aware.tapDirect("signin-btn")
let textEntered = await aware.typeText("Hello World", in: "email-field")
let toggled = await aware.toggle("remember-toggle")
```

### IPC Communication

```swift
// MCP-compatible IPC for LLM integration
~/.aware/
├── ui_command.json          # Commands from LLM
├── ui_result.json           # Results to LLM
├── ui_snapshot.json         # Current UI state
└── ui_watcher_heartbeat.txt # App health monitoring
```

### Token Efficiency on iOS

| Method | Tokens | Cost (per test) | Notes |
|--------|--------|-----------------|-------|
| **Aware iOS** | **~110** | **$0.00033** | Full state + actions |
| Screenshots | ~15,000 | $0.045 | Visual only |
| Accessibility | ~1,500 | $0.0045 | Structure only |

**iOS testing with Aware: 99.3% token reduction vs traditional screenshot approaches.**

## Breathe Integration

This is the **standalone** Aware framework. For **Breathe IDE users**, enhanced features are available through deep integration with the Breathe ecosystem.

### Snapshot Format Storage & Management 🆕

**Version 3.0** introduces persistent storage of snapshot format metadata, user preferences, and capture history in Breathe's SQLite database (`~/.breathe/index.sqlite`).

#### Dual Format System

**UI Snapshot Formats** (Runtime State Capture):
- `compact` - 100-120 tokens (LLM-optimized, ghost UI testing)
- `text` - 200-300 tokens (human-readable tree structure)
- `json` - 300-500 tokens (programmatic parsing)
- `markdown` - 250-400 tokens (documentation)

**Documentation Export Formats** (Framework API Docs):
- `compact` - 1000-1200 tokens (LLM planning)
- `jsonSchema` - 1400-1600 tokens (validation and queries)
- `mermaid` - 400-600 tokens (Breathe IDE visualization)
- `markdown` - 2500-3500 tokens (human-readable docs)
- `openapi` - 2000-3000 tokens (external tool integration)

#### MCP Tools (7 Snapshot Format Tools)

Access via Claude Code or Breathe IDE:

```
# List available formats with metadata
snapshot_formats_list

# Get current project preferences
snapshot_preferences_get

# Update preferences
snapshot_preferences_set

# View capture history
snapshot_history_get

# Get statistics and savings
snapshot_history_stats

# Record a snapshot (internal)
snapshot_history_record

# Get AI-powered format recommendation
snapshot_recommend_format
```

**Example Usage:**
```
User: List available Aware snapshot formats
Claude: [Calls snapshot_formats_list]

Found 9 snapshot formats

**UI Snapshot Formats (4):**
- **Compact** (compact): LLM-optimized, minimal tokens
  Tokens: 100-120, Use: Ghost UI testing
- **Text** (text): Human-readable tree structure
  Tokens: 200-300, Use: Human debugging
...
```

#### Database Schema

Three new tables store format data:

**`aware_snapshot_formats`** - Format metadata registry:
- Format system (ui_snapshot | doc_export)
- Token counts (min/max)
- Use cases and priorities
- Config options (JSON)

**`aware_preferences`** - Per-project preferences:
- Default formats (UI & Doc Export)
- Snapshot settings (hidden views, max depth, compression)
- Performance budgets (lenient/standard/strict: 500ms/250ms/100ms)
- WCAG accessibility level (A/AA/AAA)
- Auto-export settings

**`aware_snapshot_history`** - Audit trail:
- Capture timestamp and format
- View count and token count
- Capture duration (performance tracking)
- Links to test runs
- Content hash (deduplication)

#### Token Efficiency Tracking

Breathe automatically calculates and displays token savings:

```
**Snapshot Statistics (Project 1)**

Overall:
- Total Snapshots: 250
- Avg Token Count: 115
- Avg Capture Time: 48ms

Token Efficiency:
- Savings vs Screenshots: 99.3% (15,000 → 115 tokens)
- Cost Savings: ~$0.045 per snapshot

For 100 snapshots:
- Before: $4.50
- After: $0.033
- Total Savings: $4.47
```

#### Smart Format Recommendation

AI-powered format selection based on test context:

```swift
// LLM asks for recommendation
await Aware.shared.recommendFormat(
    testType: "e2e",
    viewCount: 25,
    complexity: "high",
    needsDetails: false
)

// Returns: ui_snapshot/compact
// Reason: "Compact format recommended for complex UIs (99.3% token savings)"
```

### Additional Breathe Features

- **Multi-App Control**: Test any macOS app or iOS Simulator
- **Intelligence Features**: Blocker diagnostics, error recovery, test generation
- **Instrumentation Guidance**: Code analysis suggestions
- **UI Testing Dashboard**: Visual test results and coverage
- **Settings Integration**: Glassmorphism UI for format preferences

See Breathe's CLAUDE.md for complete ecosystem features.

## Token Efficiency Comparison

| Method | Tokens | Accuracy | Speed |
|--------|--------|----------|-------|
| Screenshots | 10,000-20,000 | Visual only | Slow (encoding) |
| Accessibility Tree | 1,000-2,000 | Structure only | Fast |
| **Aware Compact** | **100-120** | **Full state** | **Instant** |

### Example Token Savings
For a typical login form:
- **Screenshot**: ~15,000 tokens (2048×1536 PNG)
- **Accessibility Tree**: ~1,500 tokens (structure only, no state)
- **Aware Compact**: ~110 tokens (full state + hierarchy)

**Result**: 99.3% reduction vs screenshots, 93% reduction vs accessibility.

## Examples

See `/Examples` directory for:
- **SimpleLogin**: Login form with validation
- **SettingsPanel**: Settings with toggles and pickers
- **DataTable**: Sortable table with pagination
- **MultiStepWizard**: Wizard with navigation and state

## Implementing Breathe Integration

### Automatic Snapshot Recording (Optional)

To automatically record snapshots to Breathe's database when capturing, add this to your Aware setup:

```swift
import Aware

class MyApp: App {
    init() {
        // Configure Aware with Breathe MCP integration
        Task {
            await configureAwareWithBreathe()
        }
    }

    func configureAwareWithBreathe() async {
        // Check if Breathe MCP is available
        guard let mcpEndpoint = ProcessInfo.processInfo.environment["BREATHE_MCP_ENDPOINT"] else {
            print("Breathe MCP not configured, using standalone mode")
            return
        }

        // Enable auto-recording of snapshots
        Aware.shared.onSnapshotCaptured = { snapshot in
            await recordSnapshotToBreatheMCP(snapshot)
        }
    }

    func recordSnapshotToBreatheMCP(_ snapshot: AwareSnapshotResult) async {
        // Call Breathe MCP tool to record snapshot
        // (Implementation depends on your MCP client)
        let record = [
            "formatSystem": "ui_snapshot",
            "formatName": snapshot.format,
            "viewCount": snapshot.viewCount,
            "tokenCount": estimateTokenCount(snapshot.content),
        ]

        // Send to Breathe via MCP
        try? await breatheMCPClient.callTool(
            name: "snapshot_history_record",
            arguments: ["snapshot": record]
        )
    }
}
```

### Reading Preferences from Breathe

Your app can read user preferences to use their preferred snapshot format:

```swift
// Get preferences from Breathe
let prefs = try await breatheMCPClient.callTool(
    name: "snapshot_preferences_get",
    arguments: [:]
)

// Use preferred format
let format = AwareSnapshotFormat(rawValue: prefs.defaultUISnapshotFormat) ?? .compact
let snapshot = await Aware.shared.snapshot(format: format)
```

### Integration Architecture

```
┌─────────────────┐
│   Your App      │
│  (Aware-based)  │
└────────┬────────┘
         │
         │ IPC (File-based)
         │ ~/.aware/
         ▼
┌─────────────────┐      MCP Tools       ┌──────────────────┐
│  Breathe IDE    │◄────────────────────►│  Claude Code     │
│                 │                       │  (LLM)           │
└────────┬────────┘                       └──────────────────┘
         │
         │ SQLite
         ▼
┌─────────────────────────┐
│  ~/.breathe/index.sqlite│
│  - snapshot_formats     │
│  - aware_preferences    │
│  - snapshot_history     │
└─────────────────────────┘
```

**Flow:**
1. Your app captures snapshot with Aware
2. Optionally records to Breathe database via MCP
3. Claude Code queries formats/preferences via MCP tools
4. Breathe UI displays statistics and settings
5. User preferences flow back to your app

### Benefits of Breathe Integration

1. **Persistent Preferences**: Format settings persist across sessions
2. **Historical Analysis**: Track token usage over time
3. **Cost Optimization**: Identify expensive test patterns
4. **Team Collaboration**: Share format recommendations
5. **AI Decision Support**: LLMs choose optimal format automatically

## Build Troubleshooting

### Common Issues

#### SPM Cache Corruption
If you encounter build errors or missing dependencies:

```bash
# 1. Close Xcode
# 2. Clear all SPM caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
rm -rf *.xcodeproj
rm -rf Package.resolved

# 3. Rebuild
swift build
```

#### Xcode Project Issues
If using xcodegen and encountering project issues:

```bash
# Regenerate Xcode project
xcodegen generate
xcodebuild -scheme Aware -configuration Debug build
```

#### Verify Package Health
```bash
swift package show-dependencies
swift package dump-package
swift test  # Run all tests
```

### Build Before Test
**Always verify build succeeds before running tests.** Failed tests due to build issues waste time and tokens.

## Git Workflow for LLMs

**CRITICAL**: The Aware framework uses the **`breathe`** branch for all development. This applies to both the standalone Aware package and when integrated with Breathe IDE.

### Initial Repository Setup

If working with a freshly cloned or new Aware repository:

```bash
# 1. Check current branch
git branch --show-current

# 2. If NOT on "breathe", switch to it (create if needed)
git checkout -b breathe

# 3. Verify you're on breathe branch
git branch --show-current  # Should output: breathe
```

### Branch Strategy

| Branch | Purpose | Usage |
|--------|---------|-------|
| `breathe` | **Development branch** | **ALL LLM commits go here** |
| `main` | **Production branch** | **NEVER commit here - user merges manually** |

**CRITICAL RULES FOR LLMs:**
- ✅ **ALWAYS commit to `breathe` branch**
- ❌ **NEVER commit to `main` branch** - this is production-only
- ❌ **NEVER rename or delete `main` branch**
- ℹ️ User will manually merge `breathe` → `main` for production releases

**Why this strategy?**
- `breathe` branch = active development (safe for LLMs to commit)
- `main` branch = stable production code (user controls releases)
- Clear separation prevents accidental production commits
- Enables seamless integration with Breathe IDE's workflow

### Auto-Commit Protocol

When making changes to the Aware framework, follow this commit workflow:

#### 1. Check Status
```bash
git status
```

#### 2. Stage Changes
```bash
# Stage all changes
git add .

# Or stage specific files
git add Sources/Aware/Core/AwareService.swift
git add Tests/AwareTests/AwareServiceTests.swift
```

#### 3. Commit with Conventional Format
Use conventional commit format for consistency:

```bash
git commit -m "$(cat <<'EOF'
feat: Add new capability

Description of what was added and why.

- Bullet point changes
- More specific details
- Testing notes

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**Commit Types**:
- `feat:` - New feature or capability
- `fix:` - Bug fix
- `refactor:` - Code refactoring without behavior change
- `test:` - Adding or updating tests
- `docs:` - Documentation updates
- `perf:` - Performance improvements
- `chore:` - Maintenance tasks (dependencies, build config)

#### 4. Verify Commit
```bash
# View last commit
git log -1 --oneline

# View all recent commits
git log --oneline -10
```

### LLM Auto-Commit Guidelines

When you (the LLM) make changes to the Aware framework, **always commit** after:

1. **Feature Implementation**: New modifiers, services, or capabilities
2. **Bug Fixes**: Any corrections to existing code
3. **Test Additions**: New test files or test cases
4. **Documentation Updates**: README, CLAUDE.md, or CHANGELOG changes
5. **Build Configuration**: Package.swift or project configuration changes

**DO NOT commit**:
- In the middle of multi-file refactoring (wait until complete)
- Before verifying build succeeds (`swift build`)
- Before verifying tests pass (`swift test`)

### Example Workflows

#### Workflow 1: Add New Feature
```bash
# 1. Make code changes
# ... edit files ...

# 2. Verify build
swift build

# 3. Run tests
swift test

# 4. Stage and commit
git add .
git commit -m "feat: Add .awareScrollPosition() modifier for scroll tracking"

# 5. Verify
git log -1
```

#### Workflow 2: Fix Bug
```bash
# 1. Fix the bug
# ... edit files ...

# 2. Add regression test
# ... add test ...

# 3. Verify build and tests
swift build && swift test

# 4. Commit
git add .
git commit -m "fix: Correct staleness detection for nested containers"
```

#### Workflow 3: Update Documentation
```bash
# 1. Update docs
# ... edit CLAUDE.md or README.md ...

# 2. Verify markdown renders correctly
# ... preview if possible ...

# 3. Commit
git add CLAUDE.md README.md
git commit -m "docs: Add git workflow section for LLM guidance"
```

### Integration with Breathe IDE

When the Aware framework is used within Breathe IDE:

1. **Breathe Repository**: Also uses `breathe` branch
2. **Submodule or Direct**: Aware can be a submodule or direct dependency
3. **Synchronized Commits**: Both repos commit to `breathe` branch
4. **Cross-Repo Changes**: Commit to both repos when changes span both

```bash
# Example: Update both Aware and Breathe
cd /path/to/Aware
git add .
git commit -m "feat: Add new snapshot format"

cd /path/to/Breathe
git add .
git commit -m "feat: Integrate new Aware snapshot format"
```

### Common Git Tasks

#### Check Branch Status
```bash
# Which branch am I on?
git branch --show-current

# View all branches
git branch -a
```

#### View Commit History
```bash
# Last 10 commits
git log --oneline -10

# Commits with full messages
git log -5

# Show file changes
git log --stat -3
```

#### Check Uncommitted Changes
```bash
# Summary
git status

# Detailed diff
git diff

# Staged changes
git diff --cached
```

#### Undo Changes (USE WITH CAUTION)
```bash
# Unstage file (keep changes)
git restore --staged <file>

# Discard changes to file
git restore <file>

# Discard all changes (DESTRUCTIVE)
git restore .
```

### Best Practices for LLMs

1. **Always verify branch**: Check `git branch --show-current` before committing
2. **Commit frequently**: After each logical unit of work
3. **Build before commit**: Always run `swift build` first
4. **Test before commit**: Run `swift test` when adding/changing code
5. **Clear commit messages**: Explain what and why, not just what
6. **Co-author attribution**: Include `Co-Authored-By: Claude Sonnet 4.5` in commits
7. **Check status first**: Run `git status` before staging to review changes

### Emergency Recovery

If you accidentally commit to the wrong branch:

```bash
# 1. Check where you are
git branch --show-current

# 2. If on wrong branch (e.g., main), move commit to breathe
git log -1  # Copy the commit hash

# 3. Switch to breathe
git checkout breathe

# 4. Cherry-pick the commit
git cherry-pick <commit-hash>

# 5. Go back and reset wrong branch
git checkout main
git reset --hard HEAD~1
```

**WARNING**: Only do this if the commit hasn't been pushed to remote.

### Summary

**Key Takeaways**:
- ✅ **Always use `breathe` branch** for all development
- ✅ **Commit after each logical change** (feature, fix, docs)
- ✅ **Build and test before committing**
- ✅ **Use conventional commit format** (feat:, fix:, docs:, etc.)
- ✅ **Include co-author attribution** for LLM commits
- ❌ **Never commit to `main`** - production branch only, user merges manually
- ❌ **Never commit broken builds** or failing tests

## API Reference

### AwareService (Singleton)

Main service for view registration and snapshot generation.

```swift
// Registration
await Aware.shared.registerView(_ id: String, label: String?, isContainer: Bool, parentId: String?)
await Aware.shared.unregisterView(_ id: String)

// State tracking
await Aware.shared.registerState(_ viewId: String, key: String, value: String)
await Aware.shared.getState(_ viewId: String, key: String) -> String?

// Text binding (for ghost UI typing)
await Aware.shared.registerTextBinding(_ viewId: String, binding: AwareTextBinding)
await Aware.shared.typeText(viewId: String, text: String)

// Snapshots
await Aware.shared.snapshot(format: AwareSnapshotFormat) -> String

// Metadata
await Aware.shared.registerAction(_ viewId: String, action: AwareActionMetadata)
await Aware.shared.registerBehavior(_ viewId: String, behavior: AwareBehaviorMetadata)
```

### AwareFocusManager (Singleton)

Manages keyboard focus navigation.

```swift
await AwareFocusManager.shared.registerFocus(_ viewId: String, binding: Binding<Bool>, order: Int?)
await AwareFocusManager.shared.focus(_ viewId: String)
await AwareFocusManager.shared.focusNext()
await AwareFocusManager.shared.focusPrevious()
```

### AwareLogger (Singleton)

Lifecycle event logging for debugging.

```swift
await AwareLogger.shared.appeared(_ viewId: String, _ label: String?)
await AwareLogger.shared.disappeared(_ viewId: String)
await AwareLogger.shared.tapped(_ viewId: String)
await AwareLogger.shared.stateChanged(_ viewId: String, key: String, value: String)
```

## Best Practices

### 1. Instrument Early
Add `.aware*()` modifiers during development, not as an afterthought. This enables continuous testing.

### 2. Use Semantic IDs
```swift
// Good: Describes what it is
.awareButton("save-document-btn", label: "Save")

// Bad: Generic or cryptic
.awareButton("btn1", label: "Save")
```

### 3. Add Metadata to Actions
Help LLMs understand intent:
```swift
Button("Sync") { sync() }
    .awareButton("sync-btn", label: "Sync")
    .awareMetadata(
        "sync-btn",
        description: "Synchronizes local data with remote server",
        type: .network,
        apiEndpoint: "/api/sync"
    )
```

### 4. Track Important State
```swift
Toggle("Dark Mode", isOn: $darkMode)
    .awareState("settings-darkmode", key: "enabled", value: darkMode)
```

### 5. Container Hierarchy
Organize views with containers for better snapshot structure:
```swift
VStack {
    headerView
    contentView
    footerView
}
.awareContainer("main-screen", label: "Main Screen")
```

## Migration from 1.x to 2.0

### Breaking Changes
- `awareTextBinding()` renamed to `awareTextField()` for consistency
- Focus management now uses `AwareFocusManager` singleton

### New Features
- `.awareSecureField()` for password fields
- `.awareMetadata()` for action semantics
- `.awareBehavior()` for backend metadata
- Performance budgeting
- WCAG auditing

### Migration Steps
```swift
// Old (1.x)
TextField("Email", text: $email)
    .awareTextBinding("email", text: $email, label: "Email")

// New (2.0)
TextField("Email", text: $email)
    .awareTextField("email", text: $email, label: "Email", isFocused: $focused)
```

## Contributing

Contributions welcome! See CONTRIBUTING.md for guidelines.

## License

MIT License - see LICENSE file for details.

## Links

- [GitHub Repository](https://github.com/cogitolabs/Aware)
- [Documentation](https://docs.cogito.cv/aware)
- [Breathe IDE](https://breathe.cogito.cv) - Full ecosystem integration
- [Issue Tracker](https://github.com/cogitolabs/Aware/issues)

---

**Version**: 3.0.0-beta
**Last Updated**: 2026-01-13
**Minimum Requirements**: iOS 17+, macOS 14+
