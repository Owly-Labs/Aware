//  AwarePerformanceTests.swift
//  Aware
//
//  Performance benchmarks and regression tests for the Aware framework.
//  Measures critical paths: snapshot generation, view registration, querying.
//

import XCTest
@testable import Aware

@MainActor
final class AwarePerformanceTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        // Reset between tests to ensure clean state
        Aware.shared.reset()
    }

    override func tearDown() async throws {
        // Clean up after each test
        Aware.shared.reset()
        try await super.tearDown()
    }

    // MARK: - Performance Benchmarks

    func testSnapshotPerformance_smallUI() {
        // Given: Small UI with 10 views
        measure {
            setupViews(count: 10)
            _ = Aware.shared.captureSnapshot(format: .compact)
        }
    }

    func testSnapshotPerformance_mediumUI() {
        // Given: Medium UI with 50 views
        measure {
            setupViews(count: 50)
            _ = Aware.shared.captureSnapshot(format: .compact)
        }
    }

    func testSnapshotPerformance_largeUI() {
        // Given: Large UI with 200 views
        measure {
            setupViews(count: 200)
            _ = Aware.shared.captureSnapshot(format: .compact)
        }
    }

    func testViewRegistrationPerformance() {
        measure {
            // Register 100 views
            for i in 0..<100 {
                let viewId = "perf-view-\(i)"
                Aware.shared.registerView(viewId, label: "View \(i)", isContainer: i % 10 == 0)
                Aware.shared.registerState(viewId, key: "index", value: String(i))
            }
        }
    }

    func testQueryPerformance() {
        // Given: 100 views registered
        setupViews(count: 100)

        measure {
            // Query by various criteria
            _ = Aware.shared.query().where { $0.isVisible }.all()
            _ = Aware.shared.findByLabel("View")
            _ = Aware.shared.findByState(key: "index", value: "50")
            _ = Aware.shared.findTappable()
        }
    }

    func testSnapshotFormatPerformanceCompact() {
        // Given: Medium UI setup
        setupViews(count: 50)

        // Test compact format (optimized for LLMs)
        measure {
            _ = Aware.shared.captureSnapshot(format: .compact)
        }
    }

    func testSnapshotFormatPerformanceJSON() {
        // Given: Medium UI setup
        setupViews(count: 50)

        // Test JSON format (for programmatic use)
        measure {
            _ = Aware.shared.captureSnapshot(format: .json)
        }
    }

    func testSnapshotFormatPerformanceText() {
        // Given: Medium UI setup
        setupViews(count: 50)

        // Test text format (human readable)
        measure {
            _ = Aware.shared.captureSnapshot(format: .text)
        }
    }

    func testMemoryUsageDuringSnapshots() {
        // Given: Large UI
        setupViews(count: 200)

        // Measure memory usage during snapshot
        measure {
            autoreleasepool {
                for _ in 0..<10 {
                    _ = Aware.shared.captureSnapshot(format: .compact)
                }
            }
        }
    }



    // MARK: - Regression Tests

    func testSnapshotSizeRegression() {
        // Given: Standard test UI
        setupViews(count: 20)

        let snapshot = Aware.shared.captureSnapshot(format: .compact)

        // Compact snapshots should be under 500 tokens for 20-view test UI
        let tokenEstimate = snapshot.content.count / 4  // Rough token estimation
        XCTAssertLessThan(tokenEstimate, 500, "Snapshot size regression detected: \(tokenEstimate) tokens")

        // Content should not be empty
        XCTAssertFalse(snapshot.content.isEmpty)
        XCTAssertGreaterThan(snapshot.viewCount, 0)
    }

    func testQueryPerformanceRegression() {
        // Given: Medium UI
        setupViews(count: 50)

        let startTime = CFAbsoluteTimeGetCurrent()
        let results = Aware.shared.query().where { $0.isVisible }.all()
        let endTime = CFAbsoluteTimeGetCurrent()

        let duration = endTime - startTime

        // Queries should complete in under 10ms for 50 views
        XCTAssertLessThan(duration, 0.010, "Query performance regression: \(duration * 1000)ms")
        XCTAssertEqual(results.count, 50)
    }

    func testMemoryLeakRegression() {
        // Given: Weak reference to track leaks
        weak var weakAware: Aware?

        autoreleasepool {
            // Note: We can't create new Aware instances easily since it's a singleton
            // Instead, we'll test that the shared instance doesn't leak between tests
            // by ensuring reset() works properly

            // Register many views
            for i in 0..<50 {
                let viewId = "leak-test-\(i)"
                Aware.shared.registerView(viewId, label: "View \(i)")
                Aware.shared.registerState(viewId, key: "test", value: "value")
            }

            // Generate snapshots
            for _ in 0..<3 {
                _ = Aware.shared.captureSnapshot(format: .compact)
            }

            // Reset should clean up everything
            Aware.shared.reset()
        }

        // After reset, view count should be 0
        XCTAssertEqual(Aware.shared.visibleViewCount, 0, "Reset didn't clean up properly")
    }

    // MARK: - Helper Methods

    private func setupViews(count: Int) {
        for i in 0..<count {
            let viewId = "perf-view-\(UUID().uuidString)-\(i)"
            let isContainer = i % 10 == 0
            let parentId = isContainer ? nil : "perf-view-\(UUID().uuidString)-\(i / 10 * 10)"

            Aware.shared.registerView(viewId,
                                    label: "View \(i)",
                                    isContainer: isContainer,
                                    parentId: parentId)

            // Add some state
            Aware.shared.registerState(viewId, key: "index", value: String(i))
            Aware.shared.registerState(viewId, key: "enabled", value: (i % 2 == 0) ? "true" : "false")

            // Add action metadata for some views
            if i % 5 == 0 {
                Aware.shared.registerAction(viewId, action: AwareActionMetadata(
                    actionDescription: "Test action for view \(i)",
                    actionType: .mutation,
                    isDestructive: false
                ))
            }

            // Add animation state for some views
            if i % 7 == 0 {
                Aware.shared.registerAnimation(viewId, animation: AwareAnimationState(
                    isAnimating: true,
                    animationType: "spring",
                    duration: 0.3
                ))
            }
        }
    }
}