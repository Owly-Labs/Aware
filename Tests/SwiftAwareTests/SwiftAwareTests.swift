import XCTest
@testable import SwiftAware

final class SwiftAwareTests: XCTestCase {

    func testLoggerLevels() async {
        let logger = Logger()
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warn("Warning message")
        logger.error("Error message")
        // Should not crash
    }

    func testConfigDefaults() {
        let config = AwareConfig()
        XCTAssertEqual(config.version, "1.0")
        XCTAssertEqual(config.project.platform, "swift")
        XCTAssertEqual(config.logging.level, .info)
        XCTAssertEqual(config.testing.tiers, [.smoke, .structure])
    }

    func testPresets() {
        let minimal = Preset.minimal.config
        XCTAssertEqual(minimal.tiers, [.smoke])
        XCTAssertTrue(minimal.stopOnFirstFailure)

        let verbose = Preset.verbose.config
        XCTAssertEqual(verbose.tiers, [.smoke, .structure, .integration])
        XCTAssertFalse(verbose.stopOnFirstFailure)

        let ci = Preset.ci.config
        XCTAssertTrue(ci.parallel)
    }

    func testTestTierDurations() {
        XCTAssertEqual(TestTier.smoke.targetDuration, 3)
        XCTAssertEqual(TestTier.structure.targetDuration, 30)
        XCTAssertEqual(TestTier.integration.targetDuration, 120)
    }
}
