import XCTest
@testable import EngineCore

final class WorldCacheStatsTests: XCTestCase {
    func testStatsMatchStandardResidencyRings() throws {
        let (_, result, cache) = try WorldCacheTestSupport.buildCache()
        let stats = result.snapshot.stats

        XCTAssertEqual(cache.records.count, 49)
        XCTAssertEqual(stats.totalRecords, 49)
        XCTAssertEqual(stats.samplePayloadRecords, 49)
        XCTAssertEqual(stats.meshPayloadRecords, 25)
        XCTAssertEqual(stats.residentRecords, 8)
        XCTAssertEqual(stats.activeRecords, 1)
        XCTAssertEqual(stats.renderCandidateRecords, 9)
        XCTAssertEqual(stats.estimatedVertexCount, 25 * WorldCacheTestSupport.layout.sampleCount)
        XCTAssertEqual(
            stats.estimatedIndexCount,
            25 * WorldCacheTestSupport.layout.chunkSampleSpan * WorldCacheTestSupport.layout.chunkSampleSpan * 6
        )
        XCTAssertEqual(result.mutationSummary.samplePayloadCount, stats.samplePayloadRecords)
        XCTAssertEqual(result.mutationSummary.meshPayloadCount, stats.meshPayloadRecords)
        XCTAssertEqual(result.mutationSummary.renderCandidateCount, stats.renderCandidateRecords)
    }

    func testEmptyCacheStatsAreZero() {
        let snapshot = InMemoryWorldCache().snapshot()

        XCTAssertEqual(snapshot.stats.totalRecords, 0)
        XCTAssertEqual(snapshot.stats.samplePayloadRecords, 0)
        XCTAssertEqual(snapshot.stats.meshPayloadRecords, 0)
        XCTAssertEqual(snapshot.stats.residentRecords, 0)
        XCTAssertEqual(snapshot.stats.activeRecords, 0)
        XCTAssertEqual(snapshot.stats.renderCandidateRecords, 0)
        XCTAssertEqual(snapshot.stats.estimatedVertexCount, 0)
        XCTAssertEqual(snapshot.stats.estimatedIndexCount, 0)
    }
}
