import EngineCore
import Metal
import XCTest
@testable import RenderCoreMetal

final class MetalTerrainMeshUploaderTests: XCTestCase {
    func testCPUVertexConversionPreservesVertexCountAndPositions() throws {
        let mesh = makeMeshPayload()
        let descriptor = MetalTerrainMeshDescriptor(
            meshPayload: mesh,
            lifecycleState: .resident
        )

        let vertices = try MetalTerrainMeshUploader.makeMetalVertices(descriptor: descriptor)

        XCTAssertEqual(vertices.count, mesh.vertices.count)
        XCTAssertEqual(vertices.first?.position.x, mesh.vertices.first?.position.x)
        XCTAssertEqual(vertices.first?.position.y, mesh.vertices.first?.position.y)
        XCTAssertEqual(vertices.first?.position.z, mesh.vertices.first?.position.z)
        XCTAssertEqual(vertices.first?.color.w, 1)
    }

    func testDebugColorDiffersByLifecycleState() {
        let surface = TerrainSurfaceSample(
            material: .grass,
            physicalTag: .softGrass,
            audioTag: .grass,
            slope01: 0.2,
            moisture01: 0.5,
            heightMeters: 12
        )

        let active = MetalTerrainMeshUploader.debugColor(
            heightMeters: 12,
            surface: surface,
            lifecycleState: .active
        )
        let resident = MetalTerrainMeshUploader.debugColor(
            heightMeters: 12,
            surface: surface,
            lifecycleState: .resident
        )

        XCTAssertNotEqual(active, resident)
        XCTAssertEqual(active.w, 1)
        XCTAssertEqual(resident.w, 1)
    }

    func testSelectedDescriptorChangesDebugColor() throws {
        let mesh = makeMeshPayload()
        let normal = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: MetalTerrainMeshDescriptor(meshPayload: mesh, colorMode: .mixed)
        )
        let selected = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: MetalTerrainMeshDescriptor(meshPayload: mesh, colorMode: .mixed, isSelected: true)
        )

        XCTAssertEqual(normal.count, selected.count)
        XCTAssertNotEqual(normal.first?.color, selected.first?.color)
    }

    func testUploadCreatesMetalBuffersWhenDeviceIsAvailable() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available in this environment.")
        }

        let mesh = makeMeshPayload()
        let uploader = MetalTerrainMeshUploader(device: device)
        let result = try uploader.upload(meshes: [mesh])

        XCTAssertEqual(result.buffers.count, 1)
        XCTAssertEqual(result.totalVertexCount, mesh.vertices.count)
        XCTAssertEqual(result.totalIndexCount, mesh.indices.count)
        XCTAssertEqual(result.buffers[0].vertexCount, mesh.vertices.count)
        XCTAssertEqual(result.buffers[0].indexCount, mesh.indices.count)
        XCTAssertEqual(result.buffers[0].meshStableHash, mesh.stableHash)
    }

    func testUploadRejectsEmptyMeshListWhenDeviceIsAvailable() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available in this environment.")
        }

        let uploader = MetalTerrainMeshUploader(device: device)

        XCTAssertThrowsError(try uploader.upload(meshes: [])) { error in
            XCTAssertEqual(error as? MetalDebugRenderError, .emptyMeshList)
        }
    }

    private func makeMeshPayload() -> TerrainMeshPayload {
        let samplePayload = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(42),
            chunkCoord: ChunkCoord(x: 0, z: 0),
            generatorVersion: .phase1,
            layout: TerrainChunkLayout(samplesPerAxis: 5)
        )

        return TerrainMeshBuilder.makePayload(from: samplePayload)
    }
}
