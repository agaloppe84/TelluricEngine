import XCTest
@testable import EngineCore

enum WorldCacheTestSupport {
    static let layout = TerrainChunkLayout(samplesPerAxis: 5)

    static var standardConfig: WorldResidencyConfig {
        WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        )
    }

    static func makeRequest(
        center: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0),
        seed: UInt64 = 4_004,
        config: WorldResidencyConfig = standardConfig,
        layout: TerrainChunkLayout = layout
    ) -> WorldResidencyRequest {
        WorldResidencyRequest(
            worldSeed: WorldSeed(seed),
            centerWorldPosition: .zero,
            centerChunkCoord: center,
            layout: layout,
            config: config
        )
    }

    static func makePlan(
        center: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0),
        seed: UInt64 = 4_004,
        config: WorldResidencyConfig = standardConfig,
        layout: TerrainChunkLayout = layout
    ) throws -> WorldResidencyPlan {
        try WorldResidencyPlanner().makePlan(
            makeRequest(center: center, seed: seed, config: config, layout: layout)
        )
    }

    static func buildCache(
        center: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0),
        seed: UInt64 = 4_004,
        config: WorldResidencyConfig = standardConfig,
        layout: TerrainChunkLayout = layout
    ) throws -> (plan: WorldResidencyPlan, result: ChunkBuildResult, cache: InMemoryWorldCache) {
        let plan = try makePlan(center: center, seed: seed, config: config, layout: layout)
        var cache = InMemoryWorldCache()
        let result = try ChunkBuildPipeline().apply(plan: plan, cache: &cache)
        return (plan, result, cache)
    }

    static func requireRecord(
        _ coord: WorldChunkCoord,
        in cache: InMemoryWorldCache,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> CachedChunkRecord {
        guard let record = cache.records.first(where: { $0.chunkCoord == coord }) else {
            XCTFail("Missing cached record for \(coord)", file: file, line: line)
            throw TestError.missingRecord
        }
        return record
    }

    static func requireTarget(
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

    enum TestError: Error {
        case missingRecord
        case missingTarget
    }
}
