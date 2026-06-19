import XCTest
@testable import EngineCore

final class InMemoryWorldCacheTests: XCTestCase {
    func testCacheStoresAndRemovesRecordsByChunkID() throws {
        let plan = try WorldCacheTestSupport.makePlan()
        let target = try WorldCacheTestSupport.requireTarget(WorldChunkCoord(x: 0, z: 0), in: plan)
        let record = CachedChunkRecord(
            chunkID: target.chunkID,
            chunkCoord: target.chunkCoord,
            lifecycleState: target.targetState,
            payloadState: .active,
            priority: target.priority,
            lastPlanHash: plan.stableHash
        )
        var cache = InMemoryWorldCache()

        XCTAssertFalse(cache.contains(target.chunkID))
        cache.upsert(record)
        XCTAssertTrue(cache.contains(target.chunkID))
        XCTAssertEqual(cache.record(for: target.chunkID), record)
        XCTAssertEqual(cache.remove(target.chunkID), record)
        XCTAssertFalse(cache.contains(target.chunkID))
    }

    func testRecordsAreExposedInStablePriorityThenCoordinateOrder() throws {
        let plan = try WorldCacheTestSupport.makePlan()
        let coords = [
            WorldChunkCoord(x: 1, z: 1),
            WorldChunkCoord(x: 0, z: 0),
            WorldChunkCoord(x: -1, z: -1)
        ]
        let records = try coords.map { coord -> CachedChunkRecord in
            let target = try WorldCacheTestSupport.requireTarget(coord, in: plan)
            return CachedChunkRecord(
                chunkID: target.chunkID,
                chunkCoord: target.chunkCoord,
                lifecycleState: target.targetState,
                payloadState: target.targetState == .active ? .active : .resident,
                priority: target.priority,
                lastPlanHash: plan.stableHash
            )
        }

        let cache = InMemoryWorldCache(records: records)

        XCTAssertEqual(
            cache.records.map(\.chunkCoord),
            [
                WorldChunkCoord(x: 0, z: 0),
                WorldChunkCoord(x: -1, z: -1),
                WorldChunkCoord(x: 1, z: 1)
            ]
        )
    }

    func testStableHashIgnoresDictionaryInsertionOrder() throws {
        let plan = try WorldCacheTestSupport.makePlan()
        let targets = try [
            WorldChunkCoord(x: 1, z: 0),
            WorldChunkCoord(x: 0, z: 0),
            WorldChunkCoord(x: -1, z: 0)
        ].map { try WorldCacheTestSupport.requireTarget($0, in: plan) }
        let records = targets.map {
            CachedChunkRecord(
                chunkID: $0.chunkID,
                chunkCoord: $0.chunkCoord,
                lifecycleState: $0.targetState,
                payloadState: $0.targetState == .active ? .active : .resident,
                priority: $0.priority,
                lastPlanHash: plan.stableHash
            )
        }
        let first = InMemoryWorldCache(records: records)
        let second = InMemoryWorldCache(records: records.reversed())

        XCTAssertEqual(first.records, second.records)
        XCTAssertEqual(first.stableHash, second.stableHash)
    }
}
