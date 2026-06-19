import XCTest
@testable import EngineCore

final class TerrainDeterminismTests: XCTestCase {
    func testSameSeedProducesSameTerrainPayload() {
        let layout = TerrainChunkLayout(samplesPerAxis: 7)
        let chunk = ChunkCoord(x: -2, z: 5)
        let first = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(12_345),
            chunkCoord: chunk,
            layout: layout
        )
        let second = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(12_345),
            chunkCoord: chunk,
            layout: layout
        )

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.payloadHash, second.payloadHash)
    }

    func testDifferentSeedsProduceDifferentTerrainPayloads() {
        let layout = TerrainChunkLayout(samplesPerAxis: 7)
        let chunk = ChunkCoord(x: -2, z: 5)
        let first = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(12_345),
            chunkCoord: chunk,
            layout: layout
        )
        let second = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(54_321),
            chunkCoord: chunk,
            layout: layout
        )

        XCTAssertNotEqual(first.payloadHash, second.payloadHash)
        XCTAssertNotEqual(first.samples.map(\.valueHash), second.samples.map(\.valueHash))
    }

    func testNeighboringChunksShareStableEdgeSamples() {
        let layout = TerrainChunkLayout(samplesPerAxis: 9)
        let west = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(7_777),
            chunkCoord: ChunkCoord(x: 0, z: 0),
            layout: layout
        )
        let east = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(7_777),
            chunkCoord: ChunkCoord(x: 1, z: 0),
            layout: layout
        )

        for localZ in 0..<layout.samplesPerAxis {
            let westEdge = west.sample(localX: layout.samplesPerAxis - 1, localZ: localZ)
            let eastEdge = east.sample(localX: 0, localZ: localZ)

            XCTAssertEqual(westEdge.coord, eastEdge.coord)
            XCTAssertEqual(westEdge.valueHash, eastEdge.valueHash)
            XCTAssertEqual(westEdge.scalarValue, eastEdge.scalarValue)
            XCTAssertEqual(westEdge.heightMeters, eastEdge.heightMeters)
        }
    }

    func testTerrainPayloadHashIsStable() {
        let payload = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(0x7E11_571C),
            chunkCoord: ChunkCoord(x: -3, z: 4),
            layout: TerrainChunkLayout(samplesPerAxis: 5)
        )

        XCTAssertEqual(payload.payloadHash, payload.stableHash)
        XCTAssertEqual(payload.payloadHash, 0x56D2_A14A_6CB8_6E8A)
    }
}
