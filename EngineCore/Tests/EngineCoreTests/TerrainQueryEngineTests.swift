import XCTest
@testable import EngineCore

final class TerrainQueryEngineTests: XCTestCase {
    func testHeightQueryIsDeterministic() throws {
        let snapshot = try makeSnapshot()
        let record = try requireMeshRecord(in: snapshot, coord: WorldChunkCoord(x: 0, z: 0))
        let vertex = try XCTUnwrap(record.meshPayload?.vertex(localX: 2, localZ: 2))
        let engine = TerrainQueryEngine(snapshot: snapshot)
        let request = TerrainQueryRequest(
            worldX: vertex.position.x,
            worldZ: vertex.position.z
        )

        let first = engine.query(request)
        let second = engine.query(request)
        let third = engine.query(request)

        XCTAssertEqual(first.stableHash, second.stableHash)
        XCTAssertEqual(second.stableHash, third.stableHash)
        XCTAssertEqual(first.heightMeters, second.heightMeters)
        XCTAssertEqual(first.normal, second.normal)
        XCTAssertEqual(first.surface, second.surface)
    }

    func testQueryInsideKnownTerrainReturnsFiniteTerrainData() throws {
        let snapshot = try makeSnapshot()
        let record = try requireMeshRecord(in: snapshot, coord: WorldChunkCoord(x: 0, z: 0))
        let vertex = try XCTUnwrap(record.meshPayload?.vertex(localX: 2, localZ: 2))
        let result = TerrainQueryEngine(snapshot: snapshot).query(
            TerrainQueryRequest(worldX: vertex.position.x, worldZ: vertex.position.z)
        )

        XCTAssertTrue(result.isInsideKnownTerrain)
        XCTAssertTrue(result.heightMeters.isFinite)
        XCTAssertTrue(result.normal.x.isFinite)
        XCTAssertTrue(result.normal.y.isFinite)
        XCTAssertTrue(result.normal.z.isFinite)
        XCTAssertTrue(result.slopeDegrees.isFinite)
        XCTAssertNotNil(result.surface)
        XCTAssertEqual(result.sampleCoord, vertex.sampleCoord)
        XCTAssertEqual(result.heightMeters, vertex.heightMeters, accuracy: 0.0001)
    }

    func testQueryOutsideKnownTerrainReturnsOutsideResult() throws {
        let snapshot = try makeSnapshot()
        let result = TerrainQueryEngine(snapshot: snapshot).query(
            TerrainQueryRequest(worldX: 10_000, worldZ: -10_000)
        )

        XCTAssertFalse(result.isInsideKnownTerrain)
        XCTAssertNil(result.surface)
        XCTAssertNil(result.sourceChunkID)
        XCTAssertEqual(result.walkability.reason, .outsideKnownTerrain)
    }

    func testBilinearHeightfieldInterpolatesCellCenter() throws {
        let snapshot = try makeSnapshot()
        let record = try requireMeshRecord(in: snapshot, coord: WorldChunkCoord(x: 0, z: 0))
        let mesh = try XCTUnwrap(record.meshPayload)
        let v00 = mesh.vertex(localX: 1, localZ: 1)
        let v10 = mesh.vertex(localX: 2, localZ: 1)
        let v01 = mesh.vertex(localX: 1, localZ: 2)
        let v11 = mesh.vertex(localX: 2, localZ: 2)
        let worldX = (v00.position.x + v10.position.x) * 0.5
        let worldZ = (v00.position.z + v01.position.z) * 0.5
        let expectedHeight = (v00.heightMeters + v10.heightMeters + v01.heightMeters + v11.heightMeters) * 0.25

        let result = TerrainQueryEngine(snapshot: snapshot).query(
            TerrainQueryRequest(worldX: worldX, worldZ: worldZ, queryMode: .bilinearHeightfield)
        )

        XCTAssertTrue(result.isInsideKnownTerrain)
        XCTAssertEqual(result.heightMeters, expectedHeight, accuracy: 0.0001)
        XCTAssertNotNil(result.surface)
    }

    func testNearestVertexModeSelectsStableNearestVertex() throws {
        let snapshot = try makeSnapshot()
        let record = try requireMeshRecord(in: snapshot, coord: WorldChunkCoord(x: 0, z: 0))
        let mesh = try XCTUnwrap(record.meshPayload)
        let vertex = mesh.vertex(localX: 3, localZ: 1)
        let result = TerrainQueryEngine(snapshot: snapshot).query(
            TerrainQueryRequest(
                worldX: vertex.position.x + 0.1,
                worldZ: vertex.position.z + 0.1,
                queryMode: .nearestVertex
            )
        )

        XCTAssertEqual(result.sampleCoord, vertex.sampleCoord)
        XCTAssertEqual(result.heightMeters, vertex.heightMeters, accuracy: 0.0001)
    }

    func testSharedChunkEdgeQueryIsStableAcrossSnapshots() throws {
        let layout = TerrainChunkLayout(samplesPerAxis: 5)
        let edgeX = Float(layout.chunkSampleSpan)
        let edgeZ: Float = 2
        let first = TerrainQueryEngine(snapshot: try makeSnapshot(center: WorldChunkCoord(x: 0, z: 0), layout: layout))
            .query(TerrainQueryRequest(worldX: edgeX, worldZ: edgeZ))
        let second = TerrainQueryEngine(snapshot: try makeSnapshot(center: WorldChunkCoord(x: 1, z: 0), layout: layout))
            .query(TerrainQueryRequest(worldX: edgeX, worldZ: edgeZ))

        XCTAssertTrue(first.isInsideKnownTerrain)
        XCTAssertTrue(second.isInsideKnownTerrain)
        XCTAssertEqual(first.heightMeters, second.heightMeters, accuracy: 0.0001)
        XCTAssertEqual(first.surface?.material, second.surface?.material)
    }

    private func makeSnapshot(
        center: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0),
        layout: TerrainChunkLayout = TerrainChunkLayout(samplesPerAxis: 5)
    ) throws -> ResidentWorldSnapshot {
        let result = try WorldCacheTestSupport.buildCache(center: center, layout: layout)
        return result.result.snapshot
    }

    private func requireMeshRecord(
        in snapshot: ResidentWorldSnapshot,
        coord: WorldChunkCoord
    ) throws -> CachedChunkRecord {
        let record = try XCTUnwrap(snapshot.records.first { $0.chunkCoord == coord })
        XCTAssertNotNil(record.meshPayload)
        return record
    }
}

