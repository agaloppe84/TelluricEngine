import XCTest
@testable import EngineCore

final class TerrainGenerationProfileTests: XCTestCase {
    func testDebugPlayableProfileIsDeterministicForSameSeedAndChunk() {
        let first = makeSamplePayload(profile: .debugPlayable)
        let second = makeSamplePayload(profile: .debugPlayable)

        XCTAssertEqual(first.samples.map(\.heightMeters), second.samples.map(\.heightMeters))
        XCTAssertEqual(first.stableHash, second.stableHash)
    }

    func testProfileChangesPayloadStableHash() {
        let defaultPayload = makeSamplePayload(profile: .defaultProcedural)
        let playablePayload = makeSamplePayload(profile: .debugPlayable)

        XCTAssertNotEqual(defaultPayload.stableHash, playablePayload.stableHash)
        XCTAssertNotEqual(defaultPayload.samples.map(\.heightMeters), playablePayload.samples.map(\.heightMeters))
    }

    func testDebugPlayableProfileKeepsHeightRangeBounded() {
        let payload = makeSamplePayload(profile: .debugPlayable)
        let heights = payload.samples.map(\.heightMeters)
        let minHeight = heights.min() ?? 0
        let maxHeight = heights.max() ?? 0
        let halfRange = TerrainScalarField.debugPlayableHeightRangeMeters * 0.5

        XCTAssertGreaterThanOrEqual(minHeight, -halfRange)
        XCTAssertLessThanOrEqual(maxHeight, halfRange)
        XCTAssertLessThanOrEqual(maxHeight - minHeight, TerrainScalarField.debugPlayableHeightRangeMeters)
    }

    func testDebugPlayableCenterQueryIsWalkable() throws {
        let snapshot = try makeSnapshot(profile: .debugPlayable)
        let terrain = TerrainQueryEngine(snapshot: snapshot)
        let result = terrain.query(TerrainQueryRequest(worldX: 8, worldZ: 8))

        XCTAssertTrue(result.isInsideKnownTerrain)
        XCTAssertTrue(result.walkability.isWalkable)
        XCTAssertLessThanOrEqual(result.slopeDegrees, 35)
        XCTAssertNotEqual(result.surface?.material, .shallowWater)
    }

    func testDebugPlayableSlopesAreMostlyReasonable() {
        let mesh = TerrainMeshBuilder.makePayload(from: makeSamplePayload(profile: .debugPlayable))
        let slopes = mesh.vertices.map { vertex in
            let y = max(-1, min(1, vertex.normal.normalized.y))
            return Float(acos(Double(y))) * 180 / Float.pi
        }
        let reasonableCount = slopes.filter { $0 <= 35 }.count
        let ratio = Float(reasonableCount) / Float(slopes.count)

        XCTAssertGreaterThanOrEqual(ratio, 0.90)
    }

    private func makeSamplePayload(
        profile: TerrainGenerationProfile
    ) -> ChunkTerrainSamplePayload {
        TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(96_001),
            chunkCoord: ChunkCoord(x: 0, z: 0),
            generatorVersion: .phase1,
            layout: TerrainChunkLayout(samplesPerAxis: 17),
            profile: profile
        )
    }

    private func makeSnapshot(profile: TerrainGenerationProfile) throws -> ResidentWorldSnapshot {
        let request = WorldResidencyRequest(
            worldSeed: WorldSeed(96_001),
            generatorVersion: .phase1,
            centerWorldPosition: .zero,
            centerChunkCoord: WorldChunkCoord(x: 0, z: 0),
            layout: TerrainChunkLayout(samplesPerAxis: 17),
            profile: profile,
            config: WorldResidencyConfig(
                activeRadiusChunks: 0,
                residentRadiusChunks: 0,
                meshRadiusChunks: 0,
                sampleRadiusChunks: 0,
                evictionRadiusChunks: 0
            )
        )
        let plan = try WorldResidencyPlanner().makePlan(request)
        var cache = InMemoryWorldCache()
        return try ChunkBuildPipeline().apply(plan: plan, cache: &cache).snapshot
    }
}
