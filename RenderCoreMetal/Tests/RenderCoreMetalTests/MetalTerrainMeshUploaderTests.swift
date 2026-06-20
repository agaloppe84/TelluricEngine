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

    func testCPUVertexConversionAppliesDebugVerticalScale() throws {
        let mesh = makeMeshPayload()
        let descriptor = MetalTerrainMeshDescriptor(meshPayload: mesh)

        let vertices = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: descriptor,
            verticalScale: 0.25
        )

        XCTAssertEqual(vertices.count, mesh.vertices.count)
        XCTAssertEqual(vertices.first?.position.x, mesh.vertices.first?.position.x)
        XCTAssertEqual(vertices.first?.position.y, (mesh.vertices.first?.position.y ?? 0) * 0.25)
        XCTAssertEqual(vertices.first?.position.z, mesh.vertices.first?.position.z)
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

    func testGamePreviewRenderModeChangesTerrainColor() throws {
        let mesh = makeMeshPayload()
        let debug = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: MetalTerrainMeshDescriptor(meshPayload: mesh, colorMode: .mixed, renderMode: .debug)
        )
        let game = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: MetalTerrainMeshDescriptor(meshPayload: mesh, colorMode: .surface, renderMode: .gamePreview)
        )

        XCTAssertEqual(debug.count, game.count)
        XCTAssertNotEqual(debug.first?.color, game.first?.color)
        XCTAssertEqual(game.first?.color.w, 1)
    }

    func testNativeMetalDebugResourceLabelsAreStable() {
        XCTAssertEqual(
            MetalDebugResourceLabels.terrainVertexBuffer(debugName: "chunk-0-0"),
            "chunk-0-0-terrain-vertices"
        )
        XCTAssertEqual(
            MetalDebugResourceLabels.terrainIndexBuffer(debugName: "chunk-0-0"),
            "chunk-0-0-terrain-indices"
        )
        XCTAssertEqual(
            MetalDebugResourceLabels.commandBuffer(frameIndex: 7),
            "telluric-debug-frame-7-command-buffer"
        )
        XCTAssertEqual(MetalDebugResourceLabels.terrainDrawGroup, "telluric terrain meshes")
        XCTAssertEqual(MetalDebugResourceLabels.debugLineDrawGroup, "telluric debug line overlays")
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
        XCTAssertEqual(result.buffers[0].vertexBuffer.label, "chunk-0-0-terrain-vertices")
        XCTAssertEqual(result.buffers[0].indexBuffer.label, "chunk-0-0-terrain-indices")
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

    func testBufferCacheReusesUnchangedMeshWhenDeviceIsAvailable() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available in this environment.")
        }

        let cache = MetalTerrainBufferCache(device: device)
        let descriptor = MetalTerrainMeshDescriptor(meshPayload: makeMeshPayload())

        let first = try cache.update(descriptors: [descriptor], verticalScale: 1)
        let second = try cache.update(descriptors: [descriptor], verticalScale: 1)

        XCTAssertEqual(first.createdCount, 1)
        XCTAssertEqual(first.reusedCount, 0)
        XCTAssertEqual(second.createdCount, 0)
        XCTAssertEqual(second.reusedCount, 1)
        XCTAssertTrue(first.buffers[0].vertexBuffer === second.buffers[0].vertexBuffer)
        XCTAssertTrue(first.buffers[0].indexBuffer === second.buffers[0].indexBuffer)
    }

    func testBufferCacheCreatesNewBuffersWhenDescriptorChanges() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available in this environment.")
        }

        let cache = MetalTerrainBufferCache(device: device)
        let mesh = makeMeshPayload()
        let normal = MetalTerrainMeshDescriptor(meshPayload: mesh, isSelected: false)
        let selected = MetalTerrainMeshDescriptor(meshPayload: mesh, isSelected: true)

        _ = try cache.update(descriptors: [normal], verticalScale: 1)
        let changed = try cache.update(descriptors: [selected], verticalScale: 1)

        XCTAssertEqual(changed.createdCount, 1)
        XCTAssertEqual(changed.reusedCount, 0)
        XCTAssertEqual(changed.evictedCount, 1)
    }

    func testBufferCacheEvictsRemovedChunkWhenDeviceIsAvailable() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device available in this environment.")
        }

        let cache = MetalTerrainBufferCache(device: device)
        let first = MetalTerrainMeshDescriptor(meshPayload: makeMeshPayload(chunkCoord: ChunkCoord(x: 0, z: 0)))
        let second = MetalTerrainMeshDescriptor(meshPayload: makeMeshPayload(chunkCoord: ChunkCoord(x: 1, z: 0)))

        _ = try cache.update(descriptors: [first, second], verticalScale: 1)
        let update = try cache.update(descriptors: [second], verticalScale: 1)

        XCTAssertEqual(update.createdCount, 0)
        XCTAssertEqual(update.reusedCount, 1)
        XCTAssertEqual(update.evictedCount, 1)
        XCTAssertEqual(cache.cachedBufferCount, 1)
        XCTAssertEqual(update.buffers.first?.debugName, second.debugName)
    }

    private func makeMeshPayload(chunkCoord: ChunkCoord = ChunkCoord(x: 0, z: 0)) -> TerrainMeshPayload {
        let samplePayload = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(42),
            chunkCoord: chunkCoord,
            generatorVersion: .phase1,
            layout: TerrainChunkLayout(samplesPerAxis: 5)
        )

        return TerrainMeshBuilder.makePayload(from: samplePayload)
    }
}
