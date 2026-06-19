import XCTest
@testable import EngineCore

final class WorldResidencyDeterminismTests: XCTestCase {
    func testSameRequestProducesSamePlan() throws {
        let request = makeRequest()
        let planner = WorldResidencyPlanner()

        let first = try planner.makePlan(request)
        let second = try planner.makePlan(request)
        let third = try planner.makePlan(request)

        XCTAssertEqual(first.targets, second.targets)
        XCTAssertEqual(first.simulationChunks, second.simulationChunks)
        XCTAssertEqual(first.streamingCells, second.streamingCells)
        XCTAssertEqual(first.renderCandidates, second.renderCandidates)
        XCTAssertEqual(first.stableHash, second.stableHash)
        XCTAssertEqual(second.stableHash, third.stableHash)
    }

    func testDifferentCenterProducesDifferentPlanHash() throws {
        let first = try WorldResidencyPlanner().makePlan(makeRequest(center: WorldChunkCoord(x: 0, z: 0)))
        let second = try WorldResidencyPlanner().makePlan(makeRequest(center: WorldChunkCoord(x: 1, z: 0)))

        XCTAssertNotEqual(first.stableHash, second.stableHash)
    }

    private func makeRequest(center: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0)) -> WorldResidencyRequest {
        WorldResidencyRequest(
            worldSeed: WorldSeed(44),
            centerWorldPosition: .zero,
            centerChunkCoord: center,
            config: WorldResidencyConfig(
                activeRadiusChunks: 0,
                residentRadiusChunks: 1,
                meshRadiusChunks: 2,
                sampleRadiusChunks: 3,
                evictionRadiusChunks: 4
            )
        )
    }
}

