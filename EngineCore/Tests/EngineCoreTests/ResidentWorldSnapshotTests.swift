import XCTest
@testable import EngineCore

final class ResidentWorldSnapshotTests: XCTestCase {
    func testSnapshotExposesStableReadOnlyResidentView() throws {
        let (plan, _, cache) = try WorldCacheTestSupport.buildCache()
        let snapshot = cache.snapshot(planHash: plan.stableHash)

        XCTAssertEqual(snapshot.planHash, plan.stableHash)
        XCTAssertEqual(snapshot.records.count, 49)
        XCTAssertEqual(snapshot.activeRecords.count, 1)
        XCTAssertEqual(snapshot.residentRecords.count, 8)
        XCTAssertEqual(snapshot.renderCandidates.count, 9)
        XCTAssertEqual(snapshot.cacheHash, cache.stableHash)
    }

    func testSnapshotRemainsStableAfterCacheMutates() throws {
        let (firstPlan, _, firstCache) = try WorldCacheTestSupport.buildCache()
        var mutableCache = firstCache
        let snapshotBeforeMutation = mutableCache.snapshot(planHash: firstPlan.stableHash)
        let secondPlan = try WorldCacheTestSupport.makePlan(center: WorldChunkCoord(x: 6, z: 0))

        _ = try ChunkBuildPipeline().apply(plan: secondPlan, cache: &mutableCache)

        XCTAssertEqual(snapshotBeforeMutation.planHash, firstPlan.stableHash)
        XCTAssertEqual(snapshotBeforeMutation.records.count, 49)
        XCTAssertEqual(snapshotBeforeMutation.activeRecords.first?.chunkCoord, WorldChunkCoord(x: 0, z: 0))
        XCTAssertNotEqual(snapshotBeforeMutation.stableHash, mutableCache.snapshot(planHash: secondPlan.stableHash).stableHash)
    }

    func testRenderCandidatesAreSortedStably() throws {
        let (_, _, cache) = try WorldCacheTestSupport.buildCache()
        let snapshot = cache.snapshot()
        let sorted = snapshot.renderCandidates.sorted(by: InMemoryWorldCache.isRenderCandidateOrderedBefore)

        XCTAssertEqual(snapshot.renderCandidates, sorted)
        XCTAssertEqual(snapshot.renderCandidates.first?.chunkCoord, WorldChunkCoord(x: 0, z: 0))
    }
}
