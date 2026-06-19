import XCTest
@testable import EngineCore

final class WorldResidencyPlannerTests: XCTestCase {
    func testPlannerAssignsExpectedStatesByChebyshevRadius() throws {
        let plan = try makePlan()

        XCTAssertEqual(plan.target(for: WorldChunkCoord(x: 0, z: 0))?.targetState, .active)
        XCTAssertEqual(plan.target(for: WorldChunkCoord(x: 1, z: 0))?.targetState, .resident)
        XCTAssertEqual(plan.target(for: WorldChunkCoord(x: 2, z: 0))?.targetState, .meshRequested)
        XCTAssertEqual(plan.target(for: WorldChunkCoord(x: 3, z: 0))?.targetState, .sampleRequested)
        XCTAssertEqual(plan.target(for: WorldChunkCoord(x: 4, z: 0))?.targetState, .evictionCandidate)
    }

    func testPlannerIncludesExpectedChebyshevSquareCount() throws {
        let plan = try makePlan()

        XCTAssertEqual(plan.targets.count, 81)
        XCTAssertEqual(plan.simulationChunks.count, 81)
    }

    func testMaxChunksPerPlanCapsStableTargetList() throws {
        let config = WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4,
            maxChunksPerPlan: 10
        )
        let plan = try WorldResidencyPlanner().makePlan(makeRequest(config: config))

        XCTAssertEqual(plan.targets.count, 10)
        XCTAssertEqual(plan.simulationChunks.count, 10)
        XCTAssertEqual(plan.targets.first?.chunkCoord, WorldChunkCoord(x: 0, z: 0))
    }

    func testStableOrderingUsesDistanceThenCoordinateTieBreak() throws {
        let plan = try makePlan()
        let firstNineCoords = plan.targets.prefix(9).map(\.chunkCoord)

        XCTAssertEqual(
            Array(firstNineCoords),
            [
                WorldChunkCoord(x: 0, z: 0),
                WorldChunkCoord(x: -1, z: -1),
                WorldChunkCoord(x: -1, z: 0),
                WorldChunkCoord(x: -1, z: 1),
                WorldChunkCoord(x: 0, z: -1),
                WorldChunkCoord(x: 0, z: 1),
                WorldChunkCoord(x: 1, z: -1),
                WorldChunkCoord(x: 1, z: 0),
                WorldChunkCoord(x: 1, z: 1)
            ]
        )
    }

    private func makePlan() throws -> WorldResidencyPlan {
        try WorldResidencyPlanner().makePlan(makeRequest(config: Self.standardConfig))
    }

    private func makeRequest(config: WorldResidencyConfig) -> WorldResidencyRequest {
        WorldResidencyRequest(
            worldSeed: WorldSeed(9_001),
            centerWorldPosition: .zero,
            centerChunkCoord: WorldChunkCoord(x: 0, z: 0),
            config: config
        )
    }

    private static var standardConfig: WorldResidencyConfig {
        WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        )
    }
}

