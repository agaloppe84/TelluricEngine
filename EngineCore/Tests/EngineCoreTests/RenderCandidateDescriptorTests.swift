import XCTest
@testable import EngineCore

final class RenderCandidateDescriptorTests: XCTestCase {
    func testOnlyActiveAndResidentChunksProduceRenderCandidates() throws {
        let plan = try makePlan()
        let targetStates = Set(plan.renderCandidates.map(\.targetState))

        XCTAssertEqual(plan.renderCandidates.count, 9)
        XCTAssertEqual(targetStates, [.active, .resident])
        XCTAssertFalse(plan.renderCandidates.contains { $0.targetState == .meshRequested })
        XCTAssertFalse(plan.renderCandidates.contains { $0.targetState == .sampleRequested })
        XCTAssertFalse(plan.renderCandidates.contains { $0.targetState == .evictionCandidate })
    }

    func testRenderCandidatesAreCpuOnlyDescriptorsForPhase3() throws {
        let plan = try makePlan()

        for candidate in plan.renderCandidates {
            XCTAssertNil(candidate.bounds)
            XCTAssertNil(candidate.meshStableHash)
            XCTAssertNil(candidate.surfaceStableHash)
            XCTAssertEqual(candidate.chunkID.coord, candidate.chunkCoord)
            XCTAssertNotEqual(candidate.stableHash, 0)
        }
    }

    private func makePlan() throws -> WorldResidencyPlan {
        try WorldResidencyPlanner().makePlan(
            WorldResidencyRequest(
                worldSeed: WorldSeed(123),
                centerWorldPosition: .zero,
                centerChunkCoord: WorldChunkCoord(x: 0, z: 0),
                config: WorldResidencyConfig(
                    activeRadiusChunks: 0,
                    residentRadiusChunks: 1,
                    meshRadiusChunks: 2,
                    sampleRadiusChunks: 3,
                    evictionRadiusChunks: 4
                )
            )
        )
    }
}

