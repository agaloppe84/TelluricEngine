import EngineCore
import XCTest
@testable import RenderCoreMetal

final class MetalDebugDisplayOptionsTests: XCTestCase {
    func testColorModeExposesExpectedCases() {
        XCTAssertEqual(
            MetalDebugTerrainColorMode.allCases,
            [.surface, .lifecycle, .altitude, .mixed]
        )
    }

    func testDisplayOptionsTrackWireframeBoundsAndNormals() {
        let options = MetalDebugTerrainDisplayOptions(
            colorMode: .surface,
            isWireframeEnabled: true,
            showsBounds: true,
            normals: MetalDebugNormalsConfiguration(isEnabled: true, stride: 4, length: 3)
        )

        XCTAssertEqual(options.colorMode, .surface)
        XCTAssertTrue(options.isWireframeEnabled)
        XCTAssertTrue(options.showsBounds)
        XCTAssertTrue(options.normals.isEnabled)
        XCTAssertEqual(options.normals.stride, 4)
        XCTAssertNotEqual(options.stableDebugID, MetalDebugTerrainDisplayOptions.default.stableDebugID)
    }

    func testBoundsLineGenerationCountIsStable() {
        let descriptor = makeDescriptor()
        let lines = MetalDebugLineBuilder.makeBoundsLineVertices(descriptors: [descriptor])

        XCTAssertEqual(lines.count, 24)
        XCTAssertEqual(lines.first?.color, MetalDebugLineBuilder.boundsColor)
    }

    func testNormalLineGenerationRespectsStride() {
        let descriptor = makeDescriptor()
        let config = MetalDebugNormalsConfiguration(isEnabled: true, stride: 4, length: 2)
        let lines = MetalDebugLineBuilder.makeNormalLineVertices(
            descriptors: [descriptor],
            configuration: config
        )
        let expectedNormalCount = (descriptor.meshPayload.vertices.count + config.stride - 1) / config.stride

        XCTAssertEqual(lines.count, expectedNormalCount * 2)
    }

    func testVertexColorsChangeBetweenDebugModes() throws {
        let mesh = makeMeshPayload()
        let surface = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: MetalTerrainMeshDescriptor(meshPayload: mesh, colorMode: .surface)
        )
        let lifecycle = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: MetalTerrainMeshDescriptor(meshPayload: mesh, lifecycleState: .active, colorMode: .lifecycle)
        )
        let altitude = try MetalTerrainMeshUploader.makeMetalVertices(
            descriptor: MetalTerrainMeshDescriptor(meshPayload: mesh, colorMode: .altitude)
        )

        XCTAssertEqual(surface.count, mesh.vertices.count)
        XCTAssertNotEqual(surface.first?.color, lifecycle.first?.color)
        XCTAssertNotEqual(lifecycle.first?.color, altitude.first?.color)
    }

    private func makeDescriptor() -> MetalTerrainMeshDescriptor {
        MetalTerrainMeshDescriptor(meshPayload: makeMeshPayload())
    }

    private func makeMeshPayload() -> TerrainMeshPayload {
        let samplePayload = TerrainChunkSampler.makePayload(
            worldSeed: WorldSeed(808),
            chunkCoord: ChunkCoord(x: 1, z: -1),
            layout: TerrainChunkLayout(samplesPerAxis: 5)
        )
        return TerrainMeshBuilder.makePayload(from: samplePayload)
    }
}
