import XCTest
@testable import EngineCore

final class TerrainMeshBoundsTests: XCTestCase {
    func testBoundsContainAllVertices() {
        let mesh = makeMesh()

        for vertex in mesh.vertices {
            XCTAssertTrue(mesh.bounds.contains(vertex.position))
        }
    }

    func testBoundsMinMaxAreOrdered() {
        let mesh = makeMesh()

        XCTAssertLessThanOrEqual(mesh.bounds.min.x, mesh.bounds.max.x)
        XCTAssertLessThanOrEqual(mesh.bounds.min.y, mesh.bounds.max.y)
        XCTAssertLessThanOrEqual(mesh.bounds.min.z, mesh.bounds.max.z)
    }

    func testBoundsCoverHeightRange() {
        let mesh = makeMesh()
        let heights = mesh.vertices.map(\.heightMeters)

        XCTAssertEqual(mesh.bounds.min.y, heights.min()!)
        XCTAssertEqual(mesh.bounds.max.y, heights.max()!)
    }

    private func makeMesh() -> TerrainMeshPayload {
        let samples = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(909),
            chunkCoord: ChunkCoord(x: -4, z: 2),
            layout: TerrainChunkLayout(samplesPerAxis: 7)
        )
        return TerrainMeshBuilder.makePayload(from: samples)
    }
}
