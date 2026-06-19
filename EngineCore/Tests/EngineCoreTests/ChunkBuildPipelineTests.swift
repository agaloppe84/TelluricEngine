import XCTest
@testable import EngineCore

final class ChunkBuildPipelineTests: XCTestCase {
    func testBuildsSampleOnlyChunks() throws {
        let (_, _, cache) = try WorldCacheTestSupport.buildCache()
        let record = try WorldCacheTestSupport.requireRecord(WorldChunkCoord(x: 3, z: 0), in: cache)

        XCTAssertEqual(record.lifecycleState, .sampleRequested)
        XCTAssertEqual(record.payloadState, .sampled)
        XCTAssertNotNil(record.samplePayload)
        XCTAssertNil(record.meshPayload)
        XCTAssertNil(record.renderCandidate)
    }

    func testBuildsMeshRequestedChunksWithoutRenderCandidate() throws {
        let (_, _, cache) = try WorldCacheTestSupport.buildCache()
        let record = try WorldCacheTestSupport.requireRecord(WorldChunkCoord(x: 2, z: 0), in: cache)

        XCTAssertEqual(record.lifecycleState, .meshRequested)
        XCTAssertEqual(record.payloadState, .meshed)
        XCTAssertNotNil(record.samplePayload)
        XCTAssertNotNil(record.meshPayload)
        XCTAssertNil(record.renderCandidate)
    }

    func testBuildsResidentAndActiveChunksWithRenderCandidates() throws {
        let (_, _, cache) = try WorldCacheTestSupport.buildCache()
        let active = try WorldCacheTestSupport.requireRecord(WorldChunkCoord(x: 0, z: 0), in: cache)
        let resident = try WorldCacheTestSupport.requireRecord(WorldChunkCoord(x: 1, z: 0), in: cache)

        XCTAssertEqual(active.lifecycleState, .active)
        XCTAssertEqual(active.payloadState, .active)
        XCTAssertNotNil(active.samplePayload)
        XCTAssertNotNil(active.meshPayload)
        XCTAssertNotNil(active.renderCandidate)

        XCTAssertEqual(resident.lifecycleState, .resident)
        XCTAssertEqual(resident.payloadState, .resident)
        XCTAssertNotNil(resident.samplePayload)
        XCTAssertNotNil(resident.meshPayload)
        XCTAssertNotNil(resident.renderCandidate)
    }

    func testEvictionCandidatesAreRemovedFromCache() throws {
        let plan = try WorldCacheTestSupport.makePlan()
        let evictionTarget = try WorldCacheTestSupport.requireTarget(WorldChunkCoord(x: 4, z: 0), in: plan)
        var cache = InMemoryWorldCache(
            records: [
                CachedChunkRecord(
                    chunkID: evictionTarget.chunkID,
                    chunkCoord: evictionTarget.chunkCoord,
                    lifecycleState: .active,
                    payloadState: .active,
                    priority: evictionTarget.priority,
                    lastPlanHash: 1
                )
            ]
        )

        let result = try ChunkBuildPipeline().apply(plan: plan, cache: &cache)

        XCTAssertFalse(cache.contains(evictionTarget.chunkID))
        XCTAssertGreaterThanOrEqual(result.mutationSummary.evictedCount, 1)
    }

    func testApplyingSamePlanTwiceIsIdempotentAndReusesRecords() throws {
        let plan = try WorldCacheTestSupport.makePlan()
        var cache = InMemoryWorldCache()

        let first = try ChunkBuildPipeline().apply(plan: plan, cache: &cache)
        let firstRecordCount = cache.records.count
        let firstSnapshotHash = first.snapshot.stableHash
        let second = try ChunkBuildPipeline().apply(plan: plan, cache: &cache)

        XCTAssertEqual(cache.records.count, firstRecordCount)
        XCTAssertEqual(second.snapshot.stableHash, firstSnapshotHash)
        XCTAssertEqual(second.snapshot.stats, first.snapshot.stats)
        XCTAssertEqual(second.mutationSummary.createdCount, 0)
        XCTAssertEqual(second.mutationSummary.updatedCount, 0)
        XCTAssertEqual(second.mutationSummary.reusedCount, firstRecordCount)
    }
}
