import EngineCore
import XCTest
@testable import RenderCoreMetal

final class MetalDebugCameraControllerTests: XCTestCase {
    func testResetProducesValidStateForBounds() {
        let mesh = makeMeshPayload()
        let state = MetalDebugCameraController().reset(bounds: [mesh.bounds])

        XCTAssertTrue(state.target.x.isFinite)
        XCTAssertTrue(state.target.y.isFinite)
        XCTAssertTrue(state.target.z.isFinite)
        XCTAssertGreaterThan(state.distance, 0)
        XCTAssertGreaterThan(state.orthographicScale, 0)
        XCTAssertGreaterThan(state.farZ, state.nearZ)
    }

    func testZoomClampsScale() {
        let controller = MetalDebugCameraController(minZoomScale: 0.5, maxZoomScale: 2.0)
        let base = controller.reset(bounds: nil)

        let zoomedIn = controller.zoom(base, delta: -100)
        let zoomedOut = controller.zoom(base, delta: 100)

        XCTAssertEqual(zoomedIn.zoomScale, 0.5)
        XCTAssertEqual(zoomedOut.zoomScale, 2.0)
        XCTAssertGreaterThan(zoomedOut.distance, zoomedIn.distance)
    }

    func testPitchClampsAndOrbitChangesYaw() {
        let controller = MetalDebugCameraController(minPitchRadians: 0.2, maxPitchRadians: 1.1)
        let base = controller.reset(bounds: nil)

        let low = controller.orbit(base, deltaYaw: 0.5, deltaPitch: -100)
        let high = controller.orbit(base, deltaYaw: 0.5, deltaPitch: 100)

        XCTAssertEqual(low.pitchRadians, 0.2)
        XCTAssertEqual(high.pitchRadians, 1.1)
        XCTAssertNotEqual(low.yawRadians, base.yawRadians)
    }

    func testPanChangesTarget() {
        let controller = MetalDebugCameraController()
        let base = controller.reset(bounds: nil)
        let panned = controller.pan(base, dx: 3, dz: -5)

        XCTAssertEqual(panned.target.x, base.target.x + 3)
        XCTAssertEqual(panned.target.z, base.target.z - 5)
    }

    private func makeMeshPayload() -> TerrainMeshPayload {
        let samplePayload = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(707),
            chunkCoord: ChunkCoord(x: 0, z: 0),
            layout: TerrainChunkLayout(samplesPerAxis: 5)
        )
        return TerrainMeshBuilder.makePayload(from: samplePayload)
    }
}
