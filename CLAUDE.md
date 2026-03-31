# GhostUI

> Ghost UI toolkit for LLM-assisted Swift and iOS development
>
> Swift 6.0 | iOS 17+ | macOS 14+ | SPM

## Commands

```bash
swift build       # Build the package
swift test        # Run all tests (11 tests)
```

## Structure

```
Sources/
  GhostUI/               Main library (33 files)
    SwiftUI/                Ghost UI layer
      UIActionDispatcher    Action dispatch, view tracking, state queries, plan-vs-actual
      ActionTracker         TrackedButton, .trackTap() modifier
      StateChangeTracker    @TrackedState property wrapper, manual change logging
      ViewLifecycleTracker  .trackLifecycle() modifier (appear/disappear + duration)
    Logging/                Structured logging
      Logger                Actor-based, 5 levels (trace/debug/info/warn/error), os.log bridge
      LogCollector          Log aggregation, file rotation, analytics
      AutoLogConfig         Per-function logging configuration
    Testing/                Test framework
      TestRunner            Tiered execution with retries and parallel support
      AwareTestCase         Protocol with setup/runTest/teardown + assertion helpers
      TestPlan              Step-by-step plans with expected outcomes, result builder DSL
      TestResult            Structured results with timing and failure details
      TestTier              smoke (3s) / structure (30s) / integration (120s)
    Standards/              Design system
      AwareTheme            Colors, spacing, typography, corner radius, shadows, animations
      AwareFeatureFlags     Typed registry (bool/string/int/double), env var fallback
      AwareStrings          Localized string constants (common, status, errors, cook, a11y)
      AwareStandards        Development standards registry (logging, testing, performance)
    MCP/                    Model Context Protocol
      MCPServer             Actor-based JSON-RPC server with tool registry
      MCPTool               Tool protocol + schema builder
      MCPProtocol           JSON-RPC 2.0 message types
      MCPTransport          Stdio, HTTP, WebSocket, Unix socket transports
    Cook/                   Multi-agent orchestration
      CookAgent             7 agent types (pm, architect, explorer, developer, validator, observer, context)
      CookTask              Task lifecycle (pending → running → completed/failed/blocked)
      CookBlocking          Task dependency and blocking patterns
      CookStorageProtocol   Persistent task storage abstraction
      CookSystemProtocol    System coordination protocol
    Config/                 Configuration
      AwareConfig           Project, logging, testing config structs
      ConfigLoader          Loads .ghostui.json from disk or bundle
      Preset                minimal / verbose / ci presets
    Storage/                Persistence
      StorageProtocol       AwareStorage protocol + NamespacedStorage wrapper
      MemoryStorage         In-memory (for tests)
      SQLiteStorage         SQLite key-value store (local persistence)
    Integration/            External bridges
      BreatheIntegration    AwareLogBridge protocol for forwarding logs to Breathe app
  GhostUIMacros/         Macro declarations
    AutoLog                 @AutoLog, @AutoLogAll, @NoLog macro definitions
    AutoLogVerbosity        .minimal / .standard / .verbose enum
  GhostUIMacrosPlugin/   Compiler plugin
    AutoLogMacro            Peer macro implementation (generates _logged_ wrapper functions)
    CodeGenerator           Log statement string generation
    FunctionAnalyzer        Swift syntax analysis for function signatures
    Plugin                  GhostUIMacrosPlugin entry point
Tests/
  GhostUITests/          4 tests — logger, config, presets, tiers
  GhostUIMacrosTests/    7 tests — macro expansion, category inference, @NoLog exclusion
```

## Ghost UI APIs (SwiftUI/)

The invisible observation layer — core of the toolkit:

| API | Type | Purpose |
|-----|------|---------|
| `.ghostID("id")` | View modifier | Register view for LLM visibility |
| `.ghostTrackState("key", value:)` | View modifier | Track value changes |
| `.trackLifecycle("Name")` | View modifier | Log appear/disappear with duration |
| `.trackTap("name") { }` | View modifier | Log taps on any view |
| `@TrackedState("name")` | Property wrapper | Auto-logged state with binding |
| `TrackedButton` | SwiftUI view | Button with invisible tap logging |
| `Aware.dispatcher` | Singleton | Dispatch actions, query state, plan-vs-actual |

### UIActionDispatcher actions

`tap`, `doubleTap`, `longPress`, `swipe`, `type`, `scroll`, `selectTab`, `selectSubTab`, `wait`, `waitForView`, `expectVisible`, `expectHidden`, `expectState`, `custom`, `log`

### UIActionDispatcher queries

`isViewVisible(_:)`, `getState(_:)`, `waitForView(_:timeout:)`, `waitForState(_:equals:timeout:)`, `visibleViews`, `state`, `executionLog`, `getPlanVsActualReport()`

## Key Entry Points

| API | Purpose |
|-----|---------|
| `Aware.logger` | Structured logging singleton |
| `Aware.dispatcher` | Ghost UI action dispatcher (MainActor) |
| `Aware.run(preset:)` | Run tests with preset (minimal/verbose/ci) |
| `Aware.runOnLaunchIfNeeded()` | Build-change-aware launch tests |
| `Aware.runPlan(_:)` | Execute TestPlan with plan-vs-actual comparison |
| `Aware.validate()` | Validate .ghostui.json configuration |
| `Aware.initialize(configPath:)` | Load config from custom path |
| `Aware.getTestRunner()` | Get TestRunner for registering AwareTestCase instances |

## Config

Apps configure via `.ghostui.json` (project root or app bundle). Searched filenames: `.ghostui.json`, `ghostui.json`, `.ghostui.config.json`.
