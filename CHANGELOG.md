# Changelog

All notable changes to the Aware framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.0] - 2026-01-12

### Added - Phase 9: AetherSing Integration Patterns

**UIViewID Enum Pattern (AwareiOS)**
- Type-safe view identifier protocol `UIViewIdentifier` for compile-time ID validation
- 60+ predefined stable identifiers to prevent ID drift:
  - Authentication: signInView, emailField, passwordField, signInButton
  - Navigation: tabBar, homeTab, searchTab, profileTab, navigationBar, backButton
  - Forms: formView, textField, submitButton, cancelButton, saveButton, deleteButton
  - Settings: settingsView, notificationsToggle, darkModeToggle, logoutButton
  - Loading/Error: loadingView, errorView, retryButton, emptyStateView
  - Media: videoPlayer, audioPlayer, playButton, pauseButton
- ID generators: `.scoped("child")`, `.indexed(0)`, `.suffixed("variant")`
- Custom ID support via `.custom("id")` for ad-hoc identifiers

**iOS Convenience Modifiers (AwareiOS)**
- `.uiLoadingState()` - Loading with optional message and progress (0.0-1.0)
- `.uiErrorState()` - Error tracking with retry capability flag
- `.uiProcessingState()` - Multi-step processing with current step and total steps
- `.uiValidationState()` - Form validation with error and warning arrays
- `.uiNetworkState()` - Network connectivity, loading state, last sync time
- `.uiSelectionState()` - List/collection selection with count and multi-select flag
- `.uiEmptyState()` - Empty state with custom message and add action capability
- `.uiAuthState()` - Authentication status, username, reauth requirement
- `.uiTappable()` - Direct action callback registration for ghost UI testing
- `.uiTextField()` - Enhanced TextField with automatic typeText binding
- `.uiSecureField()` - Enhanced SecureField with hasValue tracking
- `.uiToggle()` - Enhanced Toggle with isOn and isEnabled tracking

**TypeText Support (AwareiOS)**
- Text bindings registry for automatic TextField binding management
- `TextBindingModifier` for automatic registration on .task lifecycle
- `simulateInput()` implementation for `.type` command handling
- Public API: `registerTextBinding()`, `typeText()` methods
- `textInputViewIds` property lists all registered text input fields

### Changed
- AwareIOSPlatform now tracks both actionable views and text input views
- Direct action callbacks support automatic registration via modifiers
- Enhanced platform service with typeText capability

## [1.0.0-bridge] - 2026-01-12

### Added - Phase 8: WebSocket IPC for Real-Time Communication

**AwareBridge Package**
- WebSocket server using SwiftNIO on localhost:9999
- MCP (Model Context Protocol) for LLM-driven UI testing commands
- Real-time bidirectional communication (<5ms latency vs 50ms file polling)
- HTTP health endpoint at `/health` for monitoring
- Event broadcasting to all connected clients with 100-event buffer

**MCP Protocol Types**
- `MCPCommand` - Commands from Breathe IDE/LLM to Aware apps (tap, type, snapshot, wait, etc.)
- `MCPResult` - Results back to Breathe IDE with success/failure and data
- `MCPEvent` - Real-time events (viewAppeared, stateChanged, actionCompleted, etc.)
- `MCPBatch` - Atomic multi-command execution with rollback on failure
- `MCPConfiguration` - Server configuration with Breathe IDE defaults (port 9999)
- 15+ action types: tap, type, swipe, scroll, snapshot, find, wait, assert, focus, etc.

**BreatheMCPAdapter**
- High-level Breathe IDE integration layer with clean async/await API
- MCP tool implementations:
  - `ui_snapshot()` - Get current UI state in compact format
  - `ui_action()` - Perform actions (tap, type, swipe, scroll)
  - `ui_find()` - Find elements by label, type, or state
  - `ui_wait()` - Wait for conditions with timeout
  - `ui_test()` - Run batch tests with expectations
- Focus management: `focus()`, `focusNext()`, `focusPrevious()`
- Batch test execution with atomic rollback support
- Health check and connection monitoring

**iOS WebSocket Support (AwareiOS)**
- `IPCTransportMode` enum: fileBased, webSocket, auto (auto-detect preferred)
- Auto-detection with automatic fallback to file-based IPC for compatibility
- `WebSocketIPCClient` wrapper for simplified WebSocket communication
- `sendCommandViaWebSocket()` with MCP protocol translation
- `sendCommandViaFiles()` fallback for legacy compatibility
- Backward compatible with existing `AwareCommand`/`AwareResult` types

**Root Package Integration**
- Added swift-nio (2.62.0+) and swift-nio-ssl (2.25.0+) dependencies
- New `AwareBridge` library target in root Package.swift
- Independent versioning ready (v1.0.0)
- StrictConcurrency enabled across all targets

### Performance
- **10x latency reduction**: <5ms WebSocket vs 50ms file polling
- Real-time event streaming to multiple clients simultaneously
- Configurable event buffer size (default: 100 events)
- Connection pooling and automatic reconnection
- Zero-copy frame handling with NIO ByteBuffer

### Documentation
- Added WebSocket IPC section to README.md with usage examples
- MCP protocol JSON examples for command/result format
- Performance comparison table (WebSocket vs file polling)
- Updated package version table with AwareBridge v1.0.0
- Architecture diagrams showing Breathe IDE ↔ WebSocket ↔ Aware apps

## [2.0.0] - 2026-01-12

### Added

- **SwiftUI Modifiers**:
  - `.awareSecureField()` - Password field instrumentation with secure value handling
  - `.awareMetadata()` - Rich action semantics (description, type, shortcuts, API endpoints, side effects)
  - `.awareBehavior()` - Backend behavior metadata (data sources, refresh triggers, caching, error handling)
  - `.awareFocus()` - Focus and hover state tracking for interactive elements
  - `.awareScroll()` - Scroll position tracking for scrollable containers
  - `.awareAnimation()` - Animation state tracking with type and duration

- **Testing Infrastructure**:
  - `AwarePerformance.swift` - Performance monitoring and budget assertions
    - Budget levels: lenient (500ms), standard (250ms), strict (100ms)
  - `AwareAccessibility.swift` - WCAG compliance auditing (Level A, AA, AAA)
    - Color contrast checking
    - Touch target size validation
    - Label requirement verification
  - `AwareVisualTest.swift` - Visual regression testing with baseline capture
  - `AwareCoverage.swift` - UI coverage tracking (views visited, actions taken)
  - `AwareRegression.swift` - Regression detection between test runs

- **Documentation**:
  - CLAUDE.md - Comprehensive technical documentation for LLM consumption
  - README.md - Marketing-focused overview with cost savings analysis
  - Build troubleshooting guide with SPM cache clearing procedures
  - Token efficiency comparison tables
  - Example use cases for all testing features

- **Package Features**:
  - Test dependencies properly configured (ViewInspector, SnapshotTesting, Mockingbird)
  - All testing modules exported as package products
  - Platform requirements explicitly declared (iOS 17+, macOS 14+)

### Changed

- **Type System**:
  - `AwareElement` now includes `metadata: [String: String]` field
  - `AwareActionMetadata` expanded with full action semantics
  - `AwareBehaviorMetadata` added for backend integration patterns

- **Snapshot System**:
  - `AwareService.snapshot()` now includes metadata in output
  - Compact format includes action descriptions and behavior hints
  - Token count remains ~100-120 despite additional context

- **Service Methods**:
  - `AwareService.registerAction()` - Register action metadata for views
  - `AwareService.registerBehavior()` - Register behavior metadata for views
  - `AwareService.attachMetadata()` - Attach arbitrary metadata to elements

### Fixed

- Performance module properly exported in Package.swift
- Visual testing module accessible from Swift Package Manager
- Focus management works correctly with focus/hover tracking
- Secure field value properly obfuscated in snapshots (shows `hasValue` boolean, not actual text)

### Documentation

- Clear separation of standalone vs Breathe-only features
  - Standalone: Core instrumentation, testing, snapshots
  - Breathe-only: MCP integration, multi-app control, intelligence features
- Token efficiency comparison with concrete examples
  - Screenshots: 15,000 tokens ($0.045 per test)
  - Accessibility Tree: 1,500 tokens ($0.0045 per test)
  - Aware Compact: 110 tokens ($0.00033 per test)
- Build verification protocol for ensuring build success before testing
- API reference with all public methods documented
- Best practices for instrumentation and testing

### Migration Guide from 1.x

#### Breaking Changes

- `awareTextBinding()` has been renamed to `awareTextField()` for consistency
- Focus management now uses `AwareFocusManager` singleton instead of local state

#### New Patterns

```swift
// Old (1.x) - Basic text field
TextField("Email", text: $email)
    .awareTextBinding("email", text: $email, label: "Email")

// New (2.0) - Enhanced with focus tracking
TextField("Email", text: $email)
    .awareTextField("email", text: $email, label: "Email", isFocused: $focused)

// New (2.0) - Secure field support
SecureField("Password", text: $password)
    .awareSecureField("password", text: $password, label: "Password")

// New (2.0) - Rich metadata
Button("Save") { save() }
    .awareButton("save-btn", label: "Save")
    .awareMetadata(
        "save-btn",
        description: "Saves document to disk",
        type: .fileSystem,
        requiresConfirmation: true
    )

// New (2.0) - Backend behavior
List(items) { item in
    ItemRow(item: item)
}
.awareContainer("item-list", label: "Items")
.awareBehavior(
    "item-list",
    dataSource: "REST API",
    refreshTrigger: "onAppear",
    cacheDuration: "5m"
)
```

#### Upgrade Steps

1. Update package dependency to 2.0.0
2. Replace `awareTextBinding()` calls with `awareTextField()`
3. Add focus bindings if using focus navigation
4. Consider adding metadata to important actions
5. Add behavior metadata to data-driven views
6. Run tests to verify compatibility

### Dependencies

- **ViewInspector** (0.9.0+) - SwiftUI view introspection for testing
- **SnapshotTesting** (1.15.0+) - Visual regression baselines
- **Mockingbird** (0.20.0+) - Mock generation for test isolation

All dependencies are test-only and do not affect client applications using Aware.

### Platform Support

- iOS 17.0+
- macOS 14.0+
- Swift 5.9+
- Xcode 15.2+

### Token Efficiency

Aware 2.0 maintains the core value proposition of massive token reduction:

- **99.3% reduction** vs screenshot-based testing (15,000 → 110 tokens)
- **93% reduction** vs accessibility tree methods (1,500 → 110 tokens)
- **Cost savings**: Run 10,000 tests for $3.30 instead of $450

### Known Issues

- SPM cache corruption can cause build failures. Solution: Clear caches as documented in CLAUDE.md
- SourceKit may show false "Cannot find" diagnostics after editing Package.swift. These resolve on rebuild.

### Future Roadmap

Potential features under consideration for future releases:

- Flow DSL for common testing patterns (currently Breathe-only)
- Enhanced query system for element finding
- Snapshot diffing for regression details
- Test generation from specifications
- Integration examples with popular testing frameworks

---

## [1.0.0] - 2025-12-15

### Initial Release

- Core SwiftUI instrumentation modifiers
- Ghost UI interaction support
- Text-based snapshot rendering
- Basic state tracking
- Container hierarchy support
- Focus management
- Lifecycle logging

---

For detailed usage instructions, see [CLAUDE.md](CLAUDE.md).

For marketing overview and quick start, see [README.md](README.md).

For issues and feature requests, visit [GitHub Issues](https://github.com/cogitolabs/Aware/issues).
