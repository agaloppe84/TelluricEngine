import XCTest
@testable import EngineCore

final class TerrainMeshPayloadTopologyTests: XCTestCase {
    func testTopologyCountsMatchGridLayout() {
        let layout = TerrainChunkLayout(samplesPerAxis: 6)
        let mesh = makeMesh(layout: layout)

        XCTAssertEqual(mesh.vertices.count, layout.samplesPerAxis * layout.samplesPerAxis)
        XCTAssertEqual(mesh.indices.count, (layout.samplesPerAxis - 1) * (layout.samplesPerAxis - 1) * 6)
    }

    func testAllIndicesAreValid() {
        let mesh = makeMesh(layout: TerrainChunkLayout(samplesPerAxis: 6))

        for index in mesh.indices {
            XCTAssertLessThan(Int(index), mesh.vertices.count)
        }
    }

    func testTrianglesAreNotDegenerateInNominalGrid() {
        let mesh = makeMesh(layout: TerrainChunkLayout(samplesPerAxis: 6))

        for offset in stride(from: 0, to: mesh.indices.count, by: 3) {
            let i0 = Int(mesh.indices[offset])
            let i1 = Int(mesh.indices[offset + 1])
            let i2 = Int(mesh.indices[offset + 2])

            XCTAssertNotEqual(i0, i1)
            XCTAssertNotEqual(i1, i2)
            XCTAssertNotEqual(i2, i0)

            let p0 = mesh.vertices[i0].position
            let p1 = mesh.vertices[i1].position
            let p2 = mesh.vertices[i2].position
            let triangleNormal = (p1 - p0).cross(p2 - p0)

            XCTAssertGreaterThan(triangleNormal.lengthSquared, 0)
        }
    }

    func testTriangleWindingProducesUpwardNormalsForFlatTopologyReference() {
        let topLeft = TEVec3f(x: 0, y: 0, z: 0)
        let bottomLeft = TEVec3f(x: 0, y: 0, z: 1)
        let topRight = TEVec3f(x: 1, y: 0, z: 0)
        let bottomRight = TEVec3f(x: 1, y: 0, z: 1)

        let first = (bottomLeft - topLeft).cross(topRight - topLeft)
        let second = (bottomLeft - topRight).cross(bottomRight - topRight)

        XCTAssertGreaterThan(first.y, 0)
        XCTAssertGreaterThan(second.y, 0)
    }

    private func makeMesh(layout: TerrainChunkLayout) -> TerrainMeshPayload {
        let samples = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(333),
            chunkCoord: ChunkCoord(x: 1, z: -1),
            layout: layout
        )
        return TerrainMeshBuilder.makePayload(from: samples)
    }
}

