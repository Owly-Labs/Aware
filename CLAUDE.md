# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Aware** is a universal SwiftUI instrumentation framework for LLM-driven UI testing. It reduces token costs by 99.3% compared to screenshots while providing full UI state access.

> 🎉 **Version 3.1.0-alpha**: Phase 4 Future Enhancements complete! New validation rules, refactoring tools, and pattern library.

**Core Value Proposition:**
- **Ghost UI Testing**: LLMs test without mouse/screenshot simulation
- **Token Efficiency**: 100-120 tokens vs 15,000 for screenshots (99.3% reduction)
- **Cross-Platform**: iOS, macOS, Web (TypeScript), Backend (Python/Node)
- **Type-Safe**: v3.0 introduces explicit action methods and hierarchical errors
- **Protocol-Based Development**: MCP-guided code generation without framework import
- **TDD-First Philosophy**: Test-driven development made affordable with 99.3% token reduction

## Core Philosophy: Test-Driven Development

**Aware is built to enable TDD at scale**. Traditional screenshot-based testing costs $45 per 1000 tests, making true TDD prohibitively expensive. Aware reduces this to $0.33—enabling teams to write tests first without budget concerns.

### Why TDD with Aware?

| Aspect | Screenshot-Based | Aware-Based | Improvement |
|--------|------------------|-------------|-------------|
| **Tokens per test** | 15,000 | 110 | 99.3% reduction |
| **Cost per test** | $0.045 | $0.00033 | 136x cheaper |
| **1000 tests cost** | $45.00 | $0.33 | $44.67 savings |
| **Monthly cost** (2000 tests) | $90.00 | $0.66 | $89.34 savings |

### The TDD Workflow

```
┌─────────────────────────────────────────────┐
│ 1. RED: Write failing test                 │
│    - Assert expected UI state               │
│    - Snapshot captures structure            │
│    ↓                                        │
│ 2. GREEN: Implement with .aware*()         │
│    - Add modifiers to views                 │
│    - Test passes immediately                │
│    ↓                                        │
│ 3. REFACTOR: Improve code safely           │
│    - Snapshots catch regressions            │
│    - Tests still pass                       │
│    ↓                                        │
│ 4. REPEAT: Next feature                    │
└─────────────────────────────────────────────┘
```

### Dogfooding: Aware Tests Aware

Aware practices what it preaches:
- **65+ iOS platform tests** - Full TDD coverage of iOS implementation
- **LLM integration tests** - Validate LLMs can "see and touch" UI
- **Token efficiency benchmarks** - Prove 99.3% reduction claim
- **Continuous validation** - Every commit runs full test suite

**See:**
- [TDD_GUIDE.md](TDD_GUIDE.md) - Comprehensive TDD tutorial
- `Tests/LLMIntegrationTests/` - LLM snapshot parsing tests
- `Tests/PerformanceBenchmarks/` - Token efficiency validation
- `AwareiOS/Tests/` - 65 production TDD examples

### Development Principles

1. **Write tests BEFORE implementation** - No new code without tests
2. **Use compact snapshots** - Default to `.compact` format for efficiency
3. **Test state, not implementation** - Assert behavior, not internal details
4. **Dogfood the framework** - Use Aware to test Aware
5. **Measure and validate** - Track token costs, prove efficiency claims

## Recent Updates (v3.1.0-alpha)

**Phase 4 Future Enhancements - ALL COMPLETE** ✅

### 1. More Modifiers (+4 new, 9 total)
- `.awareToggle()` - Toggle state tracking (on/off testing)
- `.awareNavigation()` - Navigation actions and destinations
- `.awareAnimation()` - Animation state and timing tracking
- `.awareScroll()` - Scroll position and state tracking

**Impact**: Stubs grew from 34 → 48 LOC (+41%), modifiers from 5 → 9 (+80%)

### 2. Enhanced Validation (+20 rules, 27 total)
- **WCAG Accessibility**: 7 rules (WCAG 2.1 Level AA compliance)
  - Interactive element labels (2.4.6), toggle labels (4.1.2), navigation labels (2.4.4)
  - Semantic structure (1.3.1), touch targets (2.5.5), state changes (4.1.3), form validation (3.3.1)
- **Performance Budgets**: 6 rules
  - Action execution (250ms standard), animation duration (500ms max), network timeouts
  - Scroll performance, state update frequency, computation warnings
- **State Machine**: 7 rules
  - Conflicting state detection, initialization requirements, transition tracking
  - Unidirectional data flow, dependency tracking, loading/error patterns

**Impact**: Validation rules increased from 7 → 27 (+286%), protocol size 12 KB → 28 KB

### 3. Tool Improvements (+7 MCP tools, 12 total)

**Phase 4 Tools (3):**
- **aware_refactor_code**: Automatic refactoring (minimal/standard/comprehensive strategies)
- **aware_estimate_savings**: ROI calculator ($449.95 savings per 100 tests, 10 elements)
- **aware_compare_coverage**: Before/after comparison with recommendations

**Validation Tools (4 NEW - Breathe Integration):**
- **aware_validate_code**: Run 27 validation rules (<500ms vs 30-60s rebuild)
- **aware_fix_code**: Auto-fix violations using fix patterns (>70% success rate)
- **aware_check_wcag**: WCAG 2.1 compliance checker (7 accessibility rules, A/AA/AAA)
- **aware_check_performance**: Performance budget validator (6 rules, lenient/standard/strict)

**Impact**: MCP tools increased from 5 → 12 (+140%), 2,481 LOC of new functionality
**Architecture**: Database-based bridge (Breathe owns DB, AetherMCP queries stateless)

### 4. Pattern Library (18 comprehensive patterns)
- **Authentication**: Login, Signup, Forgot Password (3 patterns)
- **Forms**: Basic, Multi-Step, Validated (3 patterns)
- **Lists**: Simple, Pull-to-Refresh, Searchable (3 patterns)
- **Navigation**: Tabs, Master-Detail, Wizard (3 patterns)
- **Settings**: Panel, Preferences (2 patterns)
- **Feedback**: Loading, Error, Empty States (3 patterns)

**Impact**: 1,185 LOC, 2,892 tokens, each pattern includes code template, best practices, common mistakes

**See:** `Tests/Phase4Testing/FUTURE_ENHANCEMENTS_SUMMARY.md` for complete details

## iOS Platform Improvements (v2.3.0-beta → v3.0.0-beta)

**Phases 1-8 Complete - Production-Ready Transformation** ✅

Comprehensive iOS platform improvements transforming AwareiOS from C+ prototype (1,476 LOC, 0 tests) to A-grade production code with 65+ tests and 6/6 feature completion.

### Code Quality Achievements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Code Quality | C+ | A | ✅ Grade transformation |
| try? instances | 2 | 0 | ✅ -100% |
| print() calls | 11+ | 0 | ✅ -100% |
| Tasks with captures | 1/25 | 25/25 | ✅ +2400% |
| Hardcoded values | 5+ | 0 | ✅ -100% |
| Features complete | 2/6 | 6/6 | ✅ +4 features |
| Code duplication | High | Low | ✅ ~40% reduction |
| Test coverage | 0 tests | 65 tests | ✅ +6500% |

### Phase 1: Infrastructure (3 NEW FILES, 444 LOC)
- **AwareIOSConfiguration.swift** (188 LOC) - Type-safe config with validation
- **ModifierRegistrationHelper.swift** (182 LOC) - Reduces duplication by 40%
- **AwareLog.swift** (74 LOC) - Structured logging (`platform`, `ipc`, `modifiers`)

### Phase 2: Error Handling
- Replaced 2 `try?` with explicit error handling + recovery strategies
- Fallback to temp directory when IPC creation fails
- 6 new error cases: `invalidURL`, `connectionTimeout`, `directoryCreationFailed`, etc.

### Phase 3: Logging Migration
- Migrated 11 `print()` calls to `AwareLog.{platform,ipc,modifiers}`
- Debug logs auto-stripped in release builds
- Production observability via Console.app integration

### Phase 4: Memory Safety
- Fixed 25+ Task blocks with proper value captures
- Fixed critical DirectActionModifier memory leak (UIConvenienceModifiers.swift:264)
- Zero retain cycles verified

### Phase 5: Feature Completion (4 NEW FEATURES)
- ✅ **Long press** - `simulateInput(.longPress)` with duration parameter
- ✅ **Swipe gestures** - 4 directions (up/down/left/right)
- ✅ **Scroll gestures** - Directional scrolling with distance
- ✅ **WebSocket IPC** - Real `URLSessionWebSocketTask` (<5ms vs 50ms file-based)
- ✅ **Frame tracking** - `.awareFrame()` modifier with 100ms throttling

### Phase 6: Code Deduplication
- Refactored 6 modifiers: Button, TextField, SecureField, Toggle, Picker, Slider
- 40% code reduction via `ModifierRegistrationHelper`
- Single source of truth for registration patterns

### Phase 7: Configuration Integration
- Type-safe `AwareIOSConfiguration` with validation
- Environment variable support (`AWARE_WEBSOCKET_PORT`)
- Backward-compatible deprecated legacy API

### Phase 8: Comprehensive Testing (65 TESTS)
- **AwareIOSPlatformTests.swift** (25 tests) - Platform layer (config, actions, gestures)
- **AwareIOSBridgeTests.swift** (20 tests) - IPC functionality (heartbeat, commands)
- **AwareIOSBasicModifiersTests.swift** (20 tests) - UI modifiers (button, text, toggle)

**Result**: Production-ready iOS platform suitable for Breathe IDE integration.

## Monorepo Architecture

Aware is organized as a **modular monorepo** with independent package versioning:

| Package | Version | Platform | Purpose |
|---------|---------|----------|---------|
| **AwareCore** | v3.1.0-alpha | Swift | Platform-agnostic foundation with enhanced validation & patterns |
| **AwareiOS** | v3.0.0-beta | iOS 17+ | Production-ready iOS platform with 6/6 features, WebSocket IPC, 65+ tests |
| **AwareMacOS** | v2.1.0-beta | macOS 14+ | macOS implementation with 21 modifiers (12 ported + 9 Mac-specific) |
| **AwareBackendClient** | v1.0.0-beta | Cross-platform | HTTP client for BackendAware REST API |
| **AwareBridge** | v1.0.0-beta | Cross-platform | WebSocket IPC for real-time communication (<5ms latency) |
| **Aware** | v3.1.0-alpha | Umbrella | Backward-compatible re-export facade with new modifiers |

**Key Benefit**: Each package versions independently. Upgrade iOS without affecting macOS.

### Package Directory Structure

```
Aware/
├── AwareCore/                    # Platform-agnostic foundation
│   ├── Package.swift
│   ├── Sources/AwareCore/
│   │   ├── Documentation/       # API documentation generators
│   │   │   ├── Generators/      # AwareProtocolGenerator (27 validation rules)
│   │   │   ├── Patterns/        # CommonPatterns (18 UI templates) **NEW v3.1**
│   │   │   └── Registry/        # CoreModifiersRegistry (9 modifiers)
│   │   ├── Errors/              # Error types (hierarchical v3.0)
│   │   ├── Managers/            # Focus, Navigation, Interaction managers
│   │   ├── Performance/         # Performance monitoring & budgeting
│   │   ├── Recovery/            # Error recovery strategies
│   │   ├── Services/            # Core services (AwareService, modifiers)
│   │   │   └── AwareModifiersAdvanced.swift  # New modifiers v3.1
│   │   ├── Testing/             # Accessibility, coverage, mocking
│   │   └── Types/               # Protocols, commands, state types
│   └── Tests/AwareCoreTests/
│
├── AwareiOS/                     # iOS-specific implementation
│   ├── Package.swift
│   ├── Sources/AwareiOS/
│   │   ├── Modifiers/           # .ui*() modifiers (iOS-specific)
│   │   ├── Platform/            # AwareIOSPlatform, IPC bridge
│   │   ├── Testing/             # iOS-specific test utilities
│   │   └── Types/               # UIViewID enum
│   └── Tests/AwareiOSTests/
│
├── AwareMacOS/                   # macOS-specific implementation
│   ├── Package.swift
│   ├── Sources/AwareMacOS/
│   │   ├── Modifiers/           # macOS-specific modifiers
│   │   ├── Platform/            # AwareMacOSPlatform, CGEvent simulation
│   │   ├── Testing/             # macOS-specific test utilities
│   │   └── Types/               # macOS-specific types
│   └── Tests/AwareMacOSTests/
│
├── AwareBridge/                  # WebSocket IPC
│   ├── Package.swift
│   ├── Sources/AwareBridge/
│   └── Tests/AwareBridgeTests/
│
├── AwareBackendClient/           # Backend HTTP client
│   └── swift/
│       ├── Package.swift
│       ├── Sources/AwareBackendClient/
│       └── Tests/AwareBackendClientTests/
│
├── Aware/                        # Umbrella package (backward compatibility)
│   └── Sources/Aware/
│       └── Aware.swift          # Re-exports platform modules
│
├── Tests/AwareTests/             # Integration tests
├── Package.swift                 # Root package manifest
└── README.md
```

## Build Commands

### Building All Packages

```bash
# Build all packages (umbrella + sub-packages)
swift build

# Build specific package
swift build --package-path AwareCore/
swift build --package-path AwareiOS/
swift build --package-path AwareMacOS/
swift build --package-path AwareBridge/

# Build in release mode
swift build -c release

# Clean build artifacts
rm -rf .build
swift package clean
```

### Running Tests

```bash
# Run all tests
swift test

# Run tests for specific package
swift test --package-path AwareCore/
swift test --package-path AwareiOS/

# Run specific test target
swift test --filter AwareCoreTests

# Run specific test case
swift test --filter AwareCoreTests.AwareServiceTests/testSnapshot

# Verbose test output
swift test --verbose

# Parallel testing (faster)
swift test --parallel
```

**CRITICAL**: Always verify `swift build` succeeds before running tests. Failed builds waste time and tokens.

### Package Management

```bash
# Update dependencies
swift package update

# Show dependency tree
swift package show-dependencies

# Resolve dependencies
swift package resolve

# Dump package manifest
swift package dump-package

# Reset package cache (if issues)
swift package reset

# Clean SPM cache completely (nuclear option)
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
rm -rf Package.resolved
swift package reset
```

## Development Workflow

### 1. Making Changes to Core (AwareCore)

```bash
# 1. Navigate to package
cd AwareCore/

# 2. Make changes to Swift files
# ... edit files ...

# 3. Build to verify
swift build

# 4. Run tests
swift test

# 5. Return to root and test integration
cd ..
swift build
swift test
```

### 2. Making Changes to Platform Packages (iOS/macOS)

```bash
# 1. Navigate to platform package
cd AwareiOS/

# 2. Make changes
# ... edit files ...

# 3. Build locally
swift build

# 4. Test locally
swift test

# 5. Test integration with core
cd ..
swift build --package-path AwareiOS/
swift test --package-path AwareiOS/

# 6. Test full integration
swift build
swift test
```

### 3. Adding New Swift Files

**No special steps required** - SPM automatically detects new `.swift` files in `Sources/` directories.

```bash
# Just create the file
touch AwareCore/Sources/AwareCore/Services/NewService.swift

# Build will pick it up automatically
swift build
```

### 4. Adding New Dependencies

Edit the appropriate `Package.swift`:

```swift
// Example: Adding a dependency to AwareCore
dependencies: [
    .package(url: "https://github.com/example/package", from: "1.0.0")
],
targets: [
    .target(
        name: "AwareCore",
        dependencies: [
            .product(name: "ExamplePackage", package: "package")
        ]
    )
]
```

Then resolve:
```bash
swift package resolve
swift build
```

## Testing Strategy

### Test Organization

| Test Target | Location | Purpose |
|-------------|----------|---------|
| **AwareCoreTests** | `AwareCore/Tests/` | Core functionality (services, managers, types) |
| **AwareiOSTests** | `AwareiOS/Tests/` | iOS-specific features (UIViewID, .ui*() modifiers) |
| **AwareMacOSTests** | `AwareMacOS/Tests/` | macOS-specific features (CGEvent simulation) |
| **AwareBridgeTests** | `AwareBridge/Tests/` | WebSocket IPC functionality |
| **AwareTests** | `Tests/AwareTests/` | Integration tests across all packages |

### Test Dependencies

- **ViewInspector** (0.9.0+): SwiftUI introspection
- **SnapshotTesting** (1.15.0+): Visual regression testing
- **Mockingbird** (0.20.0+): Mock generation

### Running Specific Test Categories

```bash
# Core services
swift test --filter AwareCoreTests

# iOS platform
swift test --filter AwareiOSTests

# Performance tests
swift test --filter PerformanceTests

# Accessibility tests
swift test --filter AccessibilityTests

# Integration tests only
swift test --filter AwareTests
```

## Git Workflow

**CRITICAL: This repository uses the `breathe` branch for all development.**

### Branch Strategy

| Branch | Purpose | Usage |
|--------|---------|-------|
| `breathe` | **Development branch** | **ALL LLM commits go here** |
| `main` | **Production branch** | **NEVER commit here - user merges manually** |

### Before Every Commit

```bash
# 1. ALWAYS verify current branch
git branch --show-current  # Should output: breathe

# 2. If NOT on breathe, switch immediately
git checkout breathe

# 3. Verify build succeeds
swift build

# 4. Verify tests pass
swift test
```

### Commit Protocol

Use conventional commit format:

```bash
# Stage changes
git add .

# Commit with proper format
git commit -m "$(cat <<'EOF'
feat: Add new capability

Description of changes and rationale.

- Specific change 1
- Specific change 2
- Testing notes

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"

# Verify commit
git log -1 --oneline
```

**Commit Types**:
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `test:` - Test additions/updates
- `docs:` - Documentation
- `perf:` - Performance improvements
- `chore:` - Maintenance (dependencies, build)

### When to Commit

✅ **DO commit after**:
1. Feature implementation (new modifiers, services)
2. Bug fixes
3. Test additions
4. Documentation updates (README, CLAUDE.md, CHANGELOG)
5. Build configuration changes (Package.swift)

❌ **DON'T commit**:
1. In the middle of multi-file refactoring
2. Before verifying build succeeds
3. Before verifying tests pass
4. Broken code or failing tests

## Code Architecture

### Core Service: AwareService

Central singleton for UI state capture and snapshot generation.

**Location**: `AwareCore/Sources/AwareCore/Services/AwareService.swift`

**Key Responsibilities**:
- View registration and hierarchy tracking
- State management (type-safe in v3.0)
- Snapshot generation (compact/text/json/markdown formats)
- Staleness detection (prop-state consistency)
- IPC file writing (`~/.aware/ui-snapshot.json`)

**Main API** (v3.0):
```swift
// Explicit action methods (replaces generic executeAction)
await Aware.shared.tap(viewId: "button")
await Aware.shared.typeText(viewId: "field", text: "value")
await Aware.shared.focus(viewId: "input")

// Type-safe state
Aware.shared.registerStateTyped("view", key: "isOn", value: .bool(true))
let isOn = Aware.shared.getStateBool("view", key: "isOn")  // Returns Bool?

// Snapshots
let snapshot = await Aware.shared.snapshot(format: .compact)  // ~100 tokens
```

### Platform Abstraction: AwarePlatform Protocol

**Location**: `AwareCore/Sources/AwareCore/Types/AwareProtocols.swift`

Enables platform-specific behavior (iOS gestures, macOS CGEvent simulation):

```swift
@MainActor
public protocol AwarePlatform: Sendable {
    var platformName: String { get }
    func configure(options: [String: Any])
    func registerAction(_ viewId: String, callback: @escaping @Sendable @MainActor () async -> Void)
    func executeAction(_ viewId: String) async -> Bool
    func simulateInput(_ command: AwareInputCommand) async -> AwareInputResult
    func enhanceSnapshot(_ snapshot: AwareSnapshot) -> AwareSnapshot
}
```

**Implementations**:
- `AwareIOSPlatform` (`AwareiOS/Sources/AwareiOS/Platform/AwareIOSPlatform.swift`)
- `AwareMacOSPlatform` (`AwareMacOS/Sources/AwareMacOS/Platform/AwareMacOSPlatform.swift`)

### Error Handling (v3.0 Hierarchical)

**Location**: `AwareCore/Sources/AwareCore/Errors/AwareErrorHierarchical.swift`

10 error categories for better LLM error routing:

```swift
public enum AwareErrorV3: Error {
    case registration(RegistrationError)
    case state(StateError)
    case action(ActionError)
    case input(InputError)
    case query(QueryError)
    case snapshot(SnapshotError)
    case animation(AnimationError)
    case backend(BackendError)
    case configuration(ConfigurationError)
    case system(SystemError)

    public var category: ErrorCategory { ... }
}
```

**Benefits**: LLMs can route errors by category instead of parsing flat error messages.

### Modifiers System

**Core Modifiers** (`AwareCore/Sources/AwareCore/Services/AwareModifiers.swift`):
- `.aware()` - Basic view registration
- `.awareContainer()` - Group related views
- `.awareButton()` - Track button taps
- `.awareTextField()` - Track text input with focus
- `.awareSecureField()` - Track password input
- `.awareState()` - Track any state value
- `.awareMetadata()` - Add action semantics
- `.awareBehavior()` - Add backend behavior metadata

**iOS-Specific Modifiers** (`AwareiOS/Sources/AwareiOS/Modifiers/UIConvenienceModifiers.swift`):
- `.uiTappable()` - Direct action callback (ghost UI)
- `.uiTextField()` - Enhanced text field with typeText support
- `.uiLoadingState()` - Loading with progress
- `.uiErrorState()` - Error with retry capability
- `.uiValidationState()` - Form validation state
- `.uiNetworkState()` - Network connectivity
- And 8 more convenience modifiers

### UIViewID Enum (iOS Stability)

**Location**: `AwareiOS/Sources/AwareiOS/Types/UIViewID.swift`

Predefined stable identifiers prevent ID drift:

```swift
public enum UIViewID: String, CaseIterable {
    // Authentication
    case signInView = "signInView"
    case emailField = "emailField"
    case passwordField = "passwordField"
    case signInButton = "signInButton"

    // Navigation
    case tabBar = "tabBar"
    case homeTab = "homeTab"

    // ... 30+ predefined IDs

    // Scoping helpers
    public func scoped(_ suffix: String) -> String
    public func indexed(_ index: Int) -> String
    public func suffixed(_ suffix: String) -> String

    // Custom IDs
    public static func custom(_ id: String) -> String
}
```

### Documentation System

**Location**: `AwareCore/Sources/AwareCore/Documentation/`

Self-documenting API with 5 export formats:

| Format | Tokens | Use Case |
|--------|--------|----------|
| `compact` | 1000-1200 | LLM planning |
| `jsonSchema` | 1400-1600 | Validation, queries |
| `mermaid` | 400-600 | Breathe IDE visualization |
| `markdown` | 2500-3500 | Human-readable docs |
| `openapi` | 2000-3000 | External tool integration |

**Key Files**:
- `AwareAPIRegistry.swift` - Method/modifier/type metadata registry
- `AwareDocumentationService.swift` - Documentation export orchestration
- `Generators/` - Format-specific generators (Markdown, JSON Schema, Mermaid, OpenAPI, Compact)

### Performance Monitoring

**Location**: `AwareCore/Sources/AwareCore/Performance/`

Built-in performance budgeting for action speeds:

```swift
// Measure action performance
let metrics = await AwarePerformanceMonitor.shared.measure {
    await Aware.shared.typeText(viewId: "search", text: "query")
}

// Assert within budget
await AwarePerformanceAsserter.shared.assertWithinBudget(
    metrics,
    budget: .standard  // .lenient (500ms), .standard (250ms), .strict (100ms)
)
```

**Budget Presets** (`AwareCore/Sources/AwareCore/Performance/AwarePerformanceBudget.swift`):
- `.lenient`: 500ms (complex operations)
- `.standard`: 250ms (recommended default)
- `.strict`: 100ms (instant feedback)

## Common Development Tasks

### Adding a New Modifier

```bash
# 1. Add to AwareCore (cross-platform)
touch AwareCore/Sources/AwareCore/Services/AwareMyModifier.swift

# 2. Implement modifier
# ... see existing modifiers for pattern ...

# 3. Build
swift build --package-path AwareCore/

# 4. Add tests
touch AwareCore/Tests/AwareCoreTests/AwareMyModifierTests.swift

# 5. Test
swift test --package-path AwareCore/

# 6. Document in registry
# Edit: AwareCore/Sources/AwareCore/Documentation/Registry/CoreModifiersRegistry.swift
```

### Adding iOS-Specific Feature

```bash
# 1. Navigate to iOS package
cd AwareiOS/

# 2. Add implementation
touch Sources/AwareiOS/Modifiers/MyIOSFeature.swift

# 3. Build
swift build

# 4. Test
swift test

# 5. Test integration
cd ..
swift build
swift test --filter AwareiOSTests
```

### Updating Documentation

```bash
# 1. Update README.md for user-facing changes
vim README.md

# 2. Update CLAUDE.md for LLM guidance
vim CLAUDE.md

# 3. Update CHANGELOG.md
vim CHANGELOG.md

# 4. Commit
git add README.md CLAUDE.md CHANGELOG.md
git commit -m "docs: Update documentation for new feature"
```

## Build Troubleshooting

### SPM Cache Corruption

If build errors or missing dependencies:

```bash
# 1. Close Xcode (if open)

# 2. Clear all SPM caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
rm -rf Package.resolved

# 3. Rebuild from scratch
swift package reset
swift build
```

### Dependency Resolution Issues

```bash
# Update all dependencies
swift package update

# Resolve specific dependency conflicts
swift package resolve

# Verify dependency tree
swift package show-dependencies
```

### Platform-Specific Build Issues

```bash
# Build only iOS
swift build --package-path AwareiOS/

# Build only macOS
swift build --package-path AwareMacOS/

# Check for platform-specific issues
swift build --triple arm64-apple-ios17.0
swift build --triple arm64-apple-macosx14.0
```

### Test Failures

```bash
# Run tests with verbose output
swift test --verbose

# Run specific failing test
swift test --filter FailingTestName

# Check for concurrency issues (v3.0 uses StrictConcurrency)
swift build -Xswiftc -strict-concurrency=complete
```

## Breathe Integration

This is the **standalone** Aware framework. For **Breathe IDE users**, enhanced features are available:

**Breathe-Specific Features**:
- **MCP Tools**: 18+ tools for Claude Code integration
- **Validation & Auto-Fix**: 27 rules with <500ms validation, >70% auto-fix success
- **Snapshot Format Storage**: SQLite persistence in `~/.breathe/index.sqlite`
- **Multi-App Testing**: Test any macOS app or iOS Simulator
- **Intelligence**: Auto-diagnosis, error recovery, test generation
- **Cost Tracking**: Monitor AI development token costs
- **Overnight Execution**: Queue multi-day work sprints

**Database Tables** (when used with Breathe):
- `aware_snapshot_formats` - Format metadata (token counts, use cases)
- `aware_preferences` - Per-project snapshot preferences
- `aware_snapshot_history` - Audit trail of captures
- `aware_validation_rules` - 27 validation rules (completeness, consistency, performance, accessibility, state-machine)
- `aware_fix_patterns` - Auto-fix templates with success_rate tracking
- `aware_validation_history` - Validation audit trail with improvement metrics

**MCP Tools** (when used with Breathe):
```
# Snapshot Format Management (7 tools)
snapshot_formats_list         # List available formats with metadata
snapshot_preferences_get       # Get current project preferences
snapshot_preferences_set       # Update preferences
snapshot_history_get           # View capture history
snapshot_history_stats         # Get statistics and savings
snapshot_history_record        # Record snapshot (internal)
snapshot_recommend_format      # AI-powered format recommendation

# Code Validation & Auto-Fix (4 tools) - NEW
aware_validate_code           # Run 27 validation rules (<500ms)
aware_fix_code                # Auto-fix violations (>70% success)
aware_check_wcag              # WCAG 2.1 compliance (A/AA/AAA)
aware_check_performance       # Performance budget validation
```

See `/Users/adrian/Developer/cogito/Cook/CLAUDE.md` for full Breathe ecosystem context.

## Key Design Patterns

### 1. Platform Abstraction

Core framework (`AwareCore`) defines protocols. Platform packages (`AwareiOS`, `AwareMacOS`) implement them:

```swift
// Core protocol (AwareCore)
public protocol AwarePlatform: Sendable {
    func executeAction(_ viewId: String) async -> Bool
}

// iOS implementation (AwareiOS)
public final class AwareIOSPlatform: AwarePlatform {
    public func executeAction(_ viewId: String) async -> Bool {
        // iOS-specific direct action callback
    }
}

// macOS implementation (AwareMacOS)
public final class AwareMacOSPlatform: AwarePlatform {
    public func executeAction(_ viewId: String) async -> Bool {
        // macOS-specific CGEvent simulation
    }
}
```

### 2. Type-Safe State (v3.0)

Replace string-based state with typed enum:

```swift
// Before (v2.x)
registerState("view", key: "isOn", value: "true")  // String confusion

// After (v3.0)
registerStateTyped("view", key: "isOn", value: .bool(true))
let isOn = getStateBool("view", key: "isOn")  // Returns Bool?
```

### 3. Hierarchical Errors (v3.0)

Category-based error routing for LLMs:

```swift
do {
    try await Aware.shared.tap(viewId: "button")
} catch AwareErrorV3.action(let actionError) {
    // Handle all action-related errors
} catch AwareErrorV3.state(let stateError) {
    // Handle all state-related errors
}
```

### 4. Modifiers as Registration

SwiftUI modifiers trigger framework registration:

```swift
Button("Save") { save() }
    .awareButton("save-btn", label: "Save")
    // ↑ Registers button in viewRegistry, sets up tap callback
```

### 5. Staleness Detection

Automatically detect when props change but state doesn't follow:

```swift
// Framework tracks prop → state bindings
registerPropStateBinding("view", propKey: "value", stateKey: "text", ...)

// If prop updates but state doesn't within 300ms → warning
stalenessWarnings.append(...)
```

## v3.0 LLM-First API Changes

Week 3 introduced major improvements for LLM consumption:

### 1. Explicit Action Methods

**Before (v2.x)**: Generic `executeAction()` with string parameters
**After (v3.0)**: 21 type-safe methods

```swift
// Tap actions
await Aware.shared.tap(viewId: "button")
await Aware.shared.longPress(viewId: "button", duration: 1.0)
await Aware.shared.doubleTap(viewId: "button")

// Text actions
await Aware.shared.setText(viewId: "field", text: "value")
await Aware.shared.appendText(viewId: "field", text: " more")
await Aware.shared.typeText(viewId: "field", text: "value")

// Focus actions
await Aware.shared.focus(viewId: "input")
await Aware.shared.focusNextField()

// Navigation actions
await Aware.shared.navigateBack()
await Aware.shared.dismissModal()

// Query actions
let elements = await Aware.shared.find(label: "Login")
let snapshot = await Aware.shared.snapshot(format: .compact)

// Assertions
let exists = await Aware.shared.assertExists(viewId: "button")
let visible = await Aware.shared.assertVisible(viewId: "button")
```

### 2. Token Efficiency Improvements

- **Snapshot API**: Defaults to `.compact` (50% token savings)
- **State Representation**: 3-8 tokens vs 10-15 for verbose
- **Error Messages**: 15-20 tokens vs 40-60 for flat errors

### 3. Enhanced Metadata

Rich semantic information for LLM decision-making:

```swift
.awareMetadata(
    "action-id",
    actionDescription: "Saves document to cloud",
    actionType: .network,
    expectedDurationMs: 1500,
    preconditions: ["document.hasChanges", "user.isOnline"],
    riskLevel: .medium,           // .low, .medium, .high
    impactLevel: .major,          // .minor, .moderate, .major
    isIdempotent: true,
    maxRetries: 3
)
```

## Installation (for External Projects)

If using Aware in your own Swift projects:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/adrian-mei/Aware", from: "3.0.0-beta")
]

// In your target
.target(
    name: "MyApp",
    dependencies: [
        "Aware"  // Auto-imports correct platform (iOS/macOS)
    ]
)
```

## Quick Reference

### Essential Build Commands

```bash
swift build                      # Build all packages
swift test                       # Run all tests
swift test --filter NameTests    # Run specific test target
swift package clean              # Clean build artifacts
swift package reset              # Reset package cache
```

### Essential Git Commands

```bash
git branch --show-current        # Verify on "breathe" branch
git checkout breathe             # Switch to breathe branch
git status                       # Check uncommitted changes
git add .                        # Stage all changes
git commit -m "type: message"    # Commit with conventional format
git log --oneline -10            # View recent commits
```

### Quick Debugging

```bash
# Check package health
swift package show-dependencies
swift package dump-package

# Verify builds
swift build --verbose

# Run specific test
swift test --filter TestName --verbose

# Clear all caches (nuclear option)
rm -rf .build ~/Library/Developer/Xcode/DerivedData ~/Library/Caches/org.swift.swiftpm
swift package reset
```

---

**Version**: 3.0.0-beta
**Last Updated**: 2025-01-13
**Minimum Requirements**: Swift 5.9+, iOS 17+, macOS 14+
