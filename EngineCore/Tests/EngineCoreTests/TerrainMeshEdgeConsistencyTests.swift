import XCTest
@testable import EngineCore

final class TerrainMeshEdgeConsistencyTests: XCTestCase {
    func testEastWestNeighborEdgesAreCompatible() {
        let layout = TerrainChunkLayout(samplesPerAxis: 9)
        let west = makeMesh(chunk: ChunkCoord(x: 0, z: 0), layout: layout)
        let east = makeMesh(chunk: ChunkCoord(x: 1, z: 0), layout: layout)

        for localZ in 0..<layout.samplesPerAxis {
            let westEdge = west.vertex(localX: layout.samplesPerAxis - 1, localZ: localZ)
            let eastEdge = east.vertex(localX: 0, localZ: localZ)

            assertSharedEdgeVertex(westEdge, eastEdge)
        }
    }

    func testZNeighborEdgesAreCompatible() {
        let layout = TerrainChunkLayout(samplesPerAxis: 9)
        let first = makeMesh(chunk: ChunkCoord(x: 0, z: 0), layout: layout)
        let second = makeMesh(chunk: ChunkCoord(x: 0, z: 1), layout: layout)

        for localX in 0..<layout.samplesPerAxis {
            let firstEdge = first.vertex(localX: localX, localZ: layout.samplesPerAxis - 1)
            let secondEdge = second.vertex(localX: localX, localZ: 0)

            assertSharedEdgeVertex(firstEdge, secondEdge)
        }
    }

    private func makeMesh(chunk: ChunkCoord, layout: TerrainChunkLayout) -> TerrainMeshPayload {
        let samples = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(7_777),
            chunkCoord: chunk,
            layout: layout
        )
        return TerrainMeshBuilder.makePayload(from: samples)
    }

    private func assertSharedEdgeVertex(
        _ lhs: TerrainMeshVertex,
        _ rhs: TerrainMeshVertex,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.sampleCoord, rhs.sampleCoord, file: file, line: line)
        XCTAssertEqual(lhs.position, rhs.position, file: file, line: line)
        XCTAssertEqual(lhs.heightMeters, rhs.heightMeters, file: file, line: line)
        XCTAssertEqual(lhs.normal, rhs.normal, file: file, line: line)
        XCTAssertEqual(lhs.surface.material, rhs.surface.material, file: file, line: line)
        XCTAssertEqual(lhs.surface.physicalTag, rhs.surface.physicalTag, file: file, line: line)
        XCTAssertEqual(lhs.surface.audioTag, rhs.surface.audioTag, file: file, line: line)
    }
}

