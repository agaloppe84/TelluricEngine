import XCTest
@testable import EngineCore

final class TerrainSurfacePayloadTests: XCTestCase {
    func testSurfacePayloadMatchesMeshVertices() {
        let mesh = makeMesh()
        let rebuilt = makeMesh()

        XCTAssertEqual(mesh.surfacePayload.samples.count, mesh.vertices.count)
        XCTAssertEqual(mesh.surfacePayload.stableHash, rebuilt.surfacePayload.stableHash)

        for localZ in 0..<mesh.layout.samplesPerAxis {
            for localX in 0..<mesh.layout.samplesPerAxis {
                XCTAssertEqual(
                    mesh.surfacePayload.sample(localX: localX, localZ: localZ),
                    mesh.vertex(localX: localX, localZ: localZ).surface
                )
            }
        }
    }

    func testSurfaceResolutionIsStableForSameSample() {
        let mesh = makeMesh()
        let vertex = mesh.vertex(localX: 2, localZ: 3)
        let terrainSample = TerrainSample(
            coord: vertex.sampleCoord,
            scalarValue: 0,
            heightMeters: Double(vertex.heightMeters),
            valueHash: 12_345
        )

        let first = TerrainSurfaceResolver.resolve(sample: terrainSample, normal: vertex.normal)
        let second = TerrainSurfaceResolver.resolve(sample: terrainSample, normal: vertex.normal)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.material, second.material)
        XCTAssertEqual(first.physicalTag, second.physicalTag)
        XCTAssertEqual(first.audioTag, second.audioTag)
    }

    func testSurfaceTagsAreDataOnlyAndMappedForAllMaterials() {
        let cases: [(material: TerrainSurfaceMaterial, physical: PhysicalSurfaceTag, audio: AudioSurfaceTag)] = [
            (.rock, .hardRock, .stone),
            (.soil, .looseSoil, .dirt),
            (.grass, .softGrass, .grass),
            (.sand, .looseSand, .sand),
            (.gravel, .looseGravel, .gravel),
            (.mud, .stickyMud, .mud),
            (.snow, .compactSnow, .snow),
            (.shallowWater, .shallowWater, .water)
        ]

        XCTAssertEqual(cases.count, TerrainSurfaceMaterial.allCases.count)
        for expected in cases {
            let sample = TerrainSurfaceSample(
                material: expected.material,
                physicalTag: expected.physical,
                audioTag: expected.audio,
                slope01: 0.25,
                moisture01: 0.5,
                heightMeters: 12
            )

            XCTAssertEqual(sample.material, expected.material)
            XCTAssertEqual(sample.physicalTag, expected.physical)
            XCTAssertEqual(sample.audioTag, expected.audio)
        }
    }

    private func makeMesh() -> TerrainMeshPayload {
        let samples = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(808),
            chunkCoord: ChunkCoord(x: 0, z: 0),
            layout: TerrainChunkLayout(samplesPerAxis: 6)
        )
        return TerrainMeshBuilder.makePayload(from: samples)
    }
}
