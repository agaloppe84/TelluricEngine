import XCTest
@testable import EngineCore

final class TerrainMeshPayloadDeterminismTests: XCTestCase {
    func testSameInputsProduceSameMeshPayload() {
        let layout = TerrainChunkLayout(samplesPerAxis: 8)
        let chunk = ChunkCoord(x: -2, z: 3)
        let version = TerrainGeneratorVersion.phase1
        let first = makeMesh(seed: 42_4242, chunk: chunk, version: version, layout: layout)
        let second = makeMesh(seed: 42_4242, chunk: chunk, version: version, layout: layout)
        let third = makeMesh(seed: 42_4242, chunk: chunk, version: version, layout: layout)

        XCTAssertEqual(first.vertices.count, second.vertices.count)
        XCTAssertEqual(first.vertices, second.vertices)
        XCTAssertEqual(first.indices, second.indices)
        XCTAssertEqual(first.bounds, second.bounds)
        XCTAssertEqual(first.surfacePayload, second.surfacePayload)
        XCTAssertEqual(first.stableHash, second.stableHash)
        XCTAssertEqual(second.stableHash, third.stableHash)
    }

    func testDifferentSeedsProduceDifferentMeshHashes() {
        let layout = TerrainChunkLayout(samplesPerAxis: 8)
        let chunk = ChunkCoord(x: -2, z: 3)
        let firstSamples = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(1_001),
            chunkCoord: chunk,
            layout: layout
        )
        let secondSamples = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(1_002),
            chunkCoord: chunk,
            layout: layout
        )
        let first = TerrainMeshBuilder.makePayload(from: firstSamples)
        let second = TerrainMeshBuilder.makePayload(from: secondSamples)

        XCTAssertNotEqual(firstSamples.payloadHash, secondSamples.payloadHash)
        XCTAssertNotEqual(first.stableHash, second.stableHash)
    }

    private func makeMesh(
        seed: UInt64,
        chunk: ChunkCoord,
        version: TerrainGeneratorVersion,
        layout: TerrainChunkLayout
    ) -> TerrainMeshPayload {
        let samples = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(seed),
            chunkCoord: chunk,
            generatorVersion: version,
            layout: layout
        )
        return TerrainMeshBuilder.makePayload(from: samples)
    }
}

