import XCTest
@testable import EngineCore

final class WorldCacheDeterminismTests: XCTestCase {
    func testSameRequestBuildsSameSnapshotRepeatedly() throws {
        let first = try WorldCacheTestSupport.buildCache()
        let second = try WorldCacheTestSupport.buildCache()
        let third = try WorldCacheTestSupport.buildCache()

        XCTAssertEqual(first.plan.stableHash, second.plan.stableHash)
        XCTAssertEqual(first.cache.records, second.cache.records)
        XCTAssertEqual(first.result.snapshot.stats, second.result.snapshot.stats)
        XCTAssertEqual(first.result.snapshot.renderCandidates, second.result.snapshot.renderCandidates)
        XCTAssertEqual(first.result.snapshot.stableHash, second.result.snapshot.stableHash)
        XCTAssertEqual(second.result.snapshot.stableHash, third.result.snapshot.stableHash)
    }

    func testChangingCenterChangesPlanAndSnapshotDeterministically() throws {
        let first = try WorldCacheTestSupport.buildCache(center: WorldChunkCoord(x: 0, z: 0))
        let second = try WorldCacheTestSupport.buildCache(center: WorldChunkCoord(x: 2, z: 0))
        let secondRepeat = try WorldCacheTestSupport.buildCache(center: WorldChunkCoord(x: 2, z: 0))

        XCTAssertNotEqual(first.plan.stableHash, second.plan.stableHash)
        XCTAssertNotEqual(first.result.snapshot.stableHash, second.result.snapshot.stableHash)
        XCTAssertEqual(second.plan.stableHash, secondRepeat.plan.stableHash)
        XCTAssertEqual(second.result.snapshot.stableHash, secondRepeat.result.snapshot.stableHash)
    }

    func testApplyingDifferentCenterEvictsRecordsOutsideNewPlan() throws {
        let firstPlan = try WorldCacheTestSupport.makePlan(center: WorldChunkCoord(x: 0, z: 0))
        let secondPlan = try WorldCacheTestSupport.makePlan(center: WorldChunkCoord(x: 8, z: 0))
        var cache = InMemoryWorldCache()

        _ = try ChunkBuildPipeline().apply(plan: firstPlan, cache: &cache)
        let firstActiveID = try WorldCacheTestSupport
            .requireTarget(WorldChunkCoord(x: 0, z: 0), in: firstPlan)
            .chunkID
        let second = try ChunkBuildPipeline().apply(plan: secondPlan, cache: &cache)

        XCTAssertFalse(cache.contains(firstActiveID))
        XCTAssertGreaterThan(second.mutationSummary.evictedCount, 0)
        XCTAssertEqual(cache.snapshot(planHash: secondPlan.stableHash).activeRecords.first?.chunkCoord, WorldChunkCoord(x: 8, z: 0))
    }
}
