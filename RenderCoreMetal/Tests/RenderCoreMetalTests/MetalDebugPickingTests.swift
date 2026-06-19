import EngineCore
import simd
import XCTest
@testable import RenderCoreMetal

final class MetalDebugPickingTests: XCTestCase {
    func testRayDirectionIsNormalized() {
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(0, 0, 0),
            direction: SIMD3<Float>(10, 0, 0)
        )

        XCTAssertEqual(ray.direction, SIMD3<Float>(1, 0, 0))
    }

    func testInvalidViewportSizeReturnsNilRayAndMissReason() {
        let controller = MetalDebugPickingController()
        let ray = controller.makeRay(
            screenPoint: SIMD2<Float>(10, 10),
            viewportSize: SIMD2<Float>(0, 100),
            cameraState: MetalDebugCameraState()
        )
        let result = controller.pick(
            screenPoint: SIMD2<Float>(10, 10),
            viewportSize: SIMD2<Float>(0, 100),
            cameraState: MetalDebugCameraState(),
            descriptors: []
        )

        XCTAssertNil(ray)
        XCTAssertEqual(result.missReason, .invalidViewport)
    }

    func testRayAABBHitReturnsExpectedDistance() throws {
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(-2, 0, 0),
            direction: SIMD3<Float>(1, 0, 0)
        )

        let distance = MetalDebugAABBIntersection.distance(
            ray: ray,
            min: SIMD3<Float>(-1, -1, -1),
            max: SIMD3<Float>(1, 1, 1)
        )

        XCTAssertEqual(try XCTUnwrap(distance), 1, accuracy: 0.0001)
    }

    func testRayAABBMissReturnsNil() {
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(-2, 3, 0),
            direction: SIMD3<Float>(1, 0, 0)
        )

        let distance = MetalDebugAABBIntersection.distance(
            ray: ray,
            min: SIMD3<Float>(-1, -1, -1),
            max: SIMD3<Float>(1, 1, 1)
        )

        XCTAssertNil(distance)
    }

    func testRayAABBFromInsideReturnsExitDistance() throws {
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(0, 0, 0),
            direction: SIMD3<Float>(0, 0, 1)
        )

        let distance = MetalDebugAABBIntersection.distance(
            ray: ray,
            min: SIMD3<Float>(-1, -1, -1),
            max: SIMD3<Float>(1, 1, 1)
        )

        XCTAssertEqual(try XCTUnwrap(distance), 1, accuracy: 0.0001)
    }

    func testParallelRayIsHandledSafely() {
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(0, 2, -2),
            direction: SIMD3<Float>(0, 0, 1)
        )

        let distance = MetalDebugAABBIntersection.distance(
            ray: ray,
            min: SIMD3<Float>(-1, -1, -1),
            max: SIMD3<Float>(1, 1, 1)
        )

        XCTAssertNil(distance)
    }

    func testPickingChoosesNearestHit() {
        let near = makeDescriptor(chunkX: 0, chunkZ: 0)
        let far = makeDescriptor(chunkX: 0, chunkZ: 1)
        let nearCenter = center(of: near.meshPayload.bounds)
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(nearCenter.x, near.meshPayload.bounds.max.y + 100, nearCenter.z),
            direction: SIMD3<Float>(0, -1, 0)
        )

        let result = MetalDebugPickingController().pick(
            ray: ray,
            descriptors: [far, near]
        )

        XCTAssertEqual(result.hit?.chunkCoord, near.chunkID?.coord)
        XCTAssertNotNil(result.hit?.nearestVertexIndex)
        XCTAssertNotNil(result.hit?.surface)
    }

    func testPickingTieBreakIsStableByChunkCoord() {
        let mesh = makeMeshPayload(chunkX: 0, chunkZ: 0)
        let lowCoord = WorldChunkCoord(x: 0, z: 0)
        let highCoord = WorldChunkCoord(x: 1, z: 0)
        let low = MetalTerrainMeshDescriptor(
            meshPayload: mesh,
            chunkID: makeChunkID(coord: lowCoord)
        )
        let high = MetalTerrainMeshDescriptor(
            meshPayload: mesh,
            chunkID: makeChunkID(coord: highCoord)
        )
        let center = center(of: mesh.bounds)
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(center.x, mesh.bounds.max.y + 100, center.z),
            direction: SIMD3<Float>(0, -1, 0)
        )

        let first = MetalDebugPickingController().pick(ray: ray, descriptors: [high, low])
        let second = MetalDebugPickingController().pick(ray: ray, descriptors: [low, high])

        XCTAssertEqual(first.hit?.chunkCoord, lowCoord)
        XCTAssertEqual(second.hit?.chunkCoord, lowCoord)
        XCTAssertEqual(first.stableDebugID, second.stableDebugID)
    }

    func testGridLineGenerationCountIsStable() {
        let descriptors = [
            makeDescriptor(chunkX: 0, chunkZ: 0),
            makeDescriptor(chunkX: 1, chunkZ: 0)
        ]
        let lines = MetalDebugLineBuilder.makeGridLineVertices(
            descriptors: descriptors,
            configuration: MetalDebugGridConfiguration(isEnabled: true)
        )

        XCTAssertEqual(lines.count, 10)
    }

    func testPickedPointMarkerLineGenerationIsStable() {
        let lines = MetalDebugLineBuilder.makePickedPointMarkerLineVertices(
            point: MetalDebugWorldPoint(x: 1, y: 2, z: 3),
            configuration: MetalDebugPickedPointMarkerConfiguration(isEnabled: true, size: 2)
        )

        XCTAssertEqual(lines.count, 6)
        XCTAssertEqual(lines.first?.position, SIMD3<Float>(-1, 2, 3))
    }

    private func makeDescriptor(chunkX: Int32, chunkZ: Int32) -> MetalTerrainMeshDescriptor {
        let coord = WorldChunkCoord(x: chunkX, z: chunkZ)
        return MetalTerrainMeshDescriptor(
            meshPayload: makeMeshPayload(chunkX: chunkX, chunkZ: chunkZ),
            chunkID: makeChunkID(coord: coord)
        )
    }

    private func makeMeshPayload(chunkX: Int32, chunkZ: Int32) -> TerrainMeshPayload {
        let samplePayload = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(8_008),
            chunkCoord: ChunkCoord(x: chunkX, z: chunkZ),
            layout: TerrainChunkLayout(samplesPerAxis: 5)
        )
        return TerrainMeshBuilder.makePayload(from: samplePayload)
    }

    private func makeChunkID(coord: WorldChunkCoord) -> WorldChunkID {
        WorldChunkID(
            worldSeed: WorldSeed(8_008),
            generatorVersion: .phase1,
            layout: TerrainChunkLayout(samplesPerAxis: 5),
            coord: coord
        )
    }

    private func center(of bounds: TerrainMeshBounds) -> SIMD3<Float> {
        SIMD3<Float>(
            (bounds.min.x + bounds.max.x) * 0.5,
            (bounds.min.y + bounds.max.y) * 0.5,
            (bounds.min.z + bounds.max.z) * 0.5
        )
    }
}
