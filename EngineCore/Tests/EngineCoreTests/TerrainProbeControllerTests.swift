import XCTest
@testable import EngineCore

final class TerrainProbeControllerTests: XCTestCase {
    func testProbeInitialPlacementSnapsToTerrain() throws {
        let engine = try makeEngine()
        let result = TerrainProbeController().place(worldX: 0, worldZ: 0, terrain: engine)

        XCTAssertTrue(result.probe.isGrounded)
        XCTAssertTrue(result.queryResult.isInsideKnownTerrain)
        XCTAssertEqual(result.probe.worldPosition.y, result.queryResult.heightMeters, accuracy: 0.0001)
        XCTAssertEqual(result.probe.walkability, result.queryResult.walkability)
    }

    func testProbeMovementUpdatesXZAndHeight() throws {
        let engine = try makeEngine()
        let controller = TerrainProbeController()
        let initial = controller.place(worldX: 0, worldZ: 0, terrain: engine).probe

        let moved = controller.move(
            probe: initial,
            request: TerrainProbeMoveRequest(deltaX: 1, deltaZ: 0),
            terrain: engine
        )

        XCTAssertEqual(moved.probe.worldPosition.x, initial.worldPosition.x + 1, accuracy: 0.0001)
        XCTAssertEqual(moved.probe.worldPosition.z, initial.worldPosition.z, accuracy: 0.0001)
        XCTAssertEqual(moved.probe.worldPosition.y, moved.queryResult.heightMeters, accuracy: 0.0001)
        XCTAssertEqual(moved.probe.walkability, moved.queryResult.walkability)
    }

    func testRepeatedProbeMoveIsDeterministic() throws {
        let engine = try makeEngine()
        let controller = TerrainProbeController()
        let initial = controller.place(worldX: 0, worldZ: 0, terrain: engine).probe
        let request = TerrainProbeMoveRequest(deltaX: 1, deltaZ: 1)

        let first = controller.move(probe: initial, request: request, terrain: engine)
        let second = controller.move(probe: initial, request: request, terrain: engine)

        XCTAssertEqual(first.stableHash, second.stableHash)
        XCTAssertEqual(first.probe, second.probe)
    }

    func testProbeOutsideKnownTerrainIsHandled() throws {
        let engine = try makeEngine()
        let controller = TerrainProbeController()
        let initial = controller.place(worldX: 0, worldZ: 0, terrain: engine).probe

        let moved = controller.move(
            probe: initial,
            request: TerrainProbeMoveRequest(deltaX: 10_000, deltaZ: 10_000),
            terrain: engine
        )

        XCTAssertFalse(moved.probe.isGrounded)
        XCTAssertEqual(moved.queryResult.walkability.reason, .outsideKnownTerrain)
        XCTAssertEqual(moved.probe.walkability.reason, .outsideKnownTerrain)
    }

    private func makeEngine() throws -> TerrainQueryEngine {
        let result = try WorldCacheTestSupport.buildCache(layout: TerrainChunkLayout(samplesPerAxis: 5))
        return TerrainQueryEngine(snapshot: result.result.snapshot)
    }
}

