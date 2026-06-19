import XCTest
@testable import EngineCore

final class ChunkLifecycleTransitionTests: XCTestCase {
    func testTransitionsAreProducedFromCurrentStatesToPlanTargets() throws {
        let plan = try makePlan()
        let center = try requireTarget(WorldChunkCoord(x: 0, z: 0), in: plan)
        let resident = try requireTarget(WorldChunkCoord(x: -1, z: -1), in: plan)
        let mesh = try requireTarget(WorldChunkCoord(x: -2, z: -2), in: plan)
        let sample = try requireTarget(WorldChunkCoord(x: -3, z: -3), in: plan)
        let eviction = try requireTarget(WorldChunkCoord(x: -4, z: -4), in: plan)
        let identical = try requireTarget(WorldChunkCoord(x: 1, z: 0), in: plan)
        var currentStates = Dictionary(
            uniqueKeysWithValues: plan.targets.map { ($0.chunkID, $0.targetState) }
        )
        currentStates[center.chunkID] = .resident
        currentStates[resident.chunkID] = .meshed
        currentStates[mesh.chunkID] = .sampled
        currentStates[sample.chunkID] = .unloaded
        currentStates[eviction.chunkID] = .active
        currentStates[identical.chunkID] = .resident

        let transitions = ChunkLifecycleTransition.makeTransitions(
            currentStates: currentStates,
            plan: plan
        )

        XCTAssertEqual(transitions.count, 5)
        XCTAssertTrue(transitions.containsTransition(chunkID: center.chunkID, from: .resident, to: .active))
        XCTAssertTrue(transitions.containsTransition(chunkID: resident.chunkID, from: .meshed, to: .resident))
        XCTAssertTrue(transitions.containsTransition(chunkID: mesh.chunkID, from: .sampled, to: .meshRequested))
        XCTAssertTrue(transitions.containsTransition(chunkID: sample.chunkID, from: .unloaded, to: .sampleRequested))
        XCTAssertTrue(transitions.containsTransition(chunkID: eviction.chunkID, from: .active, to: .evictionCandidate))
        XCTAssertFalse(transitions.contains { $0.chunkID == identical.chunkID })
    }

    func testTransitionsAreReturnedInStableOrder() throws {
        let plan = try makePlan()
        let currentStates = Dictionary(
            uniqueKeysWithValues: plan.targets.map { ($0.chunkID, ChunkLifecycleState.unloaded) }
        )
        let transitions = ChunkLifecycleTransition.makeTransitions(
            currentStates: currentStates,
            plan: plan
        )

        let sorted = transitions.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            return lhs.chunkID < rhs.chunkID
        }

        XCTAssertEqual(transitions, sorted)
    }

    private func makePlan() throws -> WorldResidencyPlan {
        try WorldResidencyPlanner().makePlan(
            WorldResidencyRequest(
                worldSeed: WorldSeed(55),
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

    private func requireTarget(
        _ coord: WorldChunkCoord,
        in plan: WorldResidencyPlan,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> ChunkLifecycleTarget {
        guard let target = plan.target(for: coord) else {
            XCTFail("Missing target for \(coord)", file: file, line: line)
            throw TestError.missingTarget
        }
        return target
    }

    private enum TestError: Error {
        case missingTarget
    }
}

private extension Array where Element == ChunkLifecycleTransition {
    func containsTransition(
        chunkID: WorldChunkID,
        from fromState: ChunkLifecycleState,
        to toState: ChunkLifecycleState
    ) -> Bool {
        contains {
            $0.chunkID == chunkID
                && $0.fromState == fromState
                && $0.toState == toState
        }
    }
}
