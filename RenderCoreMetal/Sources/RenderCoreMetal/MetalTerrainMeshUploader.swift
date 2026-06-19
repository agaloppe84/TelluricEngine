import EngineCore
import Metal
import simd

public struct MetalTerrainMeshUploader {
    public let device: MTLDevice

    public init(device: MTLDevice) {
        self.device = device
    }

    public func upload(meshes: [TerrainMeshPayload]) throws -> MetalTerrainMeshUploadResult {
        try upload(
            descriptors: meshes.map {
                MetalTerrainMeshDescriptor(meshPayload: $0)
            }
        )
    }

    public func upload(descriptors: [MetalTerrainMeshDescriptor]) throws -> MetalTerrainMeshUploadResult {
        guard descriptors.isEmpty == false else {
            throw MetalDebugRenderError.emptyMeshList
        }

        let buffers = try descriptors.map(upload)
        return MetalTerrainMeshUploadResult(buffers: buffers)
    }

    public static func makeMetalVertices(
        descriptor: MetalTerrainMeshDescriptor
    ) throws -> [MetalTerrainVertex] {
        let mesh = descriptor.meshPayload
        guard mesh.vertices.isEmpty == false, mesh.indices.isEmpty == false else {
            throw MetalDebugRenderError.emptyMeshPayload(mesh.stableHash)
        }

        return mesh.vertices.map { vertex in
            MetalTerrainVertex(
                position: SIMD3<Float>(
                    vertex.position.x,
                    vertex.position.y,
                    vertex.position.z
                ),
                normal: SIMD3<Float>(
                    vertex.normal.x,
                    vertex.normal.y,
                    vertex.normal.z
                ),
                color: debugColor(
                    heightMeters: vertex.heightMeters,
                    surface: vertex.surface,
                    lifecycleState: descriptor.lifecycleState,
                    colorMode: descriptor.colorMode,
                    isSelected: descriptor.isSelected
                )
            )
        }
    }

    public static func debugColor(
        heightMeters: Float,
        surface: TerrainSurfaceSample,
        lifecycleState: ChunkLifecycleState
    ) -> SIMD4<Float> {
        debugColor(
            heightMeters: heightMeters,
            surface: surface,
            lifecycleState: lifecycleState,
            colorMode: .mixed
        )
    }

    public static func color(for state: ChunkLifecycleState) -> SIMD3<Float> {
        switch state {
        case .active:
            return SIMD3<Float>(0.95, 0.23, 0.18)
        case .resident:
            return SIMD3<Float>(0.20, 0.70, 0.36)
        case .meshed, .meshRequested:
            return SIMD3<Float>(0.24, 0.45, 0.92)
        case .sampled, .sampleRequested:
            return SIMD3<Float>(0.90, 0.72, 0.28)
        case .evictionCandidate:
            return SIMD3<Float>(0.55, 0.48, 0.40)
        case .unloaded:
            return SIMD3<Float>(0.20, 0.22, 0.25)
        }
    }

    private func upload(_ descriptor: MetalTerrainMeshDescriptor) throws -> MetalTerrainMeshBuffers {
        let vertices = try Self.makeMetalVertices(descriptor: descriptor)
        let indices = descriptor.meshPayload.indices

        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<MetalTerrainVertex>.stride,
            options: [.storageModeShared]
        ) else {
            throw MetalDebugRenderError.bufferAllocationFailed("\(descriptor.debugName)-vertices")
        }

        guard let indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<TerrainMeshIndex>.stride,
            options: [.storageModeShared]
        ) else {
            throw MetalDebugRenderError.bufferAllocationFailed("\(descriptor.debugName)-indices")
        }

        vertexBuffer.label = "\(descriptor.debugName)-terrain-vertices"
        indexBuffer.label = "\(descriptor.debugName)-terrain-indices"

        return MetalTerrainMeshBuffers(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            vertexCount: vertices.count,
            indexCount: indices.count,
            chunkID: descriptor.chunkID,
            debugName: descriptor.debugName,
            bounds: descriptor.meshPayload.bounds,
            meshStableHash: descriptor.meshPayload.stableHash
        )
    }

    static func color(for material: TerrainSurfaceMaterial) -> SIMD3<Float> {
        switch material {
        case .rock:
            return SIMD3<Float>(0.48, 0.48, 0.50)
        case .soil:
            return SIMD3<Float>(0.42, 0.32, 0.22)
        case .grass:
            return SIMD3<Float>(0.26, 0.58, 0.26)
        case .sand:
            return SIMD3<Float>(0.82, 0.70, 0.42)
        case .gravel:
            return SIMD3<Float>(0.45, 0.45, 0.42)
        case .mud:
            return SIMD3<Float>(0.30, 0.24, 0.18)
        case .snow:
            return SIMD3<Float>(0.86, 0.90, 0.92)
        case .shallowWater:
            return SIMD3<Float>(0.18, 0.45, 0.72)
        }
    }

    static func mix(
        _ lhs: SIMD3<Float>,
        _ rhs: SIMD3<Float>,
        amount: Float
    ) -> SIMD3<Float> {
        lhs * (1 - amount) + rhs * amount
    }
}
