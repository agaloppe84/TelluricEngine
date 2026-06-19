import XCTest
@testable import EngineCore

final class WorldResidencyConfigTests: XCTestCase {
    func testValidConfigIsAccepted() {
        let config = WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        )

        XCTAssertNoThrow(try config.validate())
    }

    func testEqualRadiiAreAccepted() {
        let config = WorldResidencyConfig(
            activeRadiusChunks: 2,
            residentRadiusChunks: 2,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 2,
            evictionRadiusChunks: 2
        )

        XCTAssertNoThrow(try config.validate())
    }

    func testNegativeRadiusIsRejected() {
        let config = WorldResidencyConfig(
            activeRadiusChunks: -1,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        )

        XCTAssertThrowsError(try config.validate())
    }

    func testInconsistentRadiiAreRejected() {
        let config = WorldResidencyConfig(
            activeRadiusChunks: 2,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        )

        XCTAssertThrowsError(try config.validate())
    }

    func testInvalidMaxChunksPerPlanIsRejected() {
        let config = WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4,
            maxChunksPerPlan: 0
        )

        XCTAssertThrowsError(try config.validate())
    }
}

