import EngineCore
import Metal

public struct MetalTerrainBufferCacheKey: Hashable {
    public let chunkID: WorldChunkID?
    public let chunkX: Int32
    public let chunkZ: Int32
    public let meshStableHash: UInt64
    public let lifecycleState: ChunkLifecycleState
    public let colorMode: MetalDebugTerrainColorMode
    public let renderMode: MetalTerrainRenderMode
    public let isSelected: Bool
    public let verticalScaleBits: UInt32
    public let debugName: String

    public init(
        descriptor: MetalTerrainMeshDescriptor,
        verticalScale: Float
    ) {
        self.chunkID = descriptor.chunkID
        self.chunkX = descriptor.meshPayload.chunkCoord.x
        self.chunkZ = descriptor.meshPayload.chunkCoord.z
        self.meshStableHash = descriptor.meshPayload.stableHash
        self.lifecycleState = descriptor.lifecycleState
        self.colorMode = descriptor.colorMode
        self.renderMode = descriptor.renderMode
        self.isSelected = descriptor.isSelected
        self.verticalScaleBits = verticalScale.bitPattern
        self.debugName = descriptor.debugName
    }
}

public final class MetalTerrainBufferCache {
    public let device: MTLDevice

    private let uploader: MetalTerrainMeshUploader
    private var storage: [MetalTerrainBufferCacheKey: MetalTerrainMeshBuffers] = [:]

    public init(device: MTLDevice) {
        self.device = device
        self.uploader = MetalTerrainMeshUploader(device: device)
    }

    public var cachedBufferCount: Int {
        storage.count
    }

    public func removeAll() {
        storage.removeAll()
    }

    public func update(
        descriptors: [MetalTerrainMeshDescriptor],
        verticalScale: Float
    ) throws -> MetalTerrainBufferCacheUpdate {
        guard descriptors.isEmpty == false else {
            removeAll()
            throw MetalDebugRenderError.emptyMeshList
        }

        let safeVerticalScale = verticalScale.isFinite ? max(verticalScale, 0.05) : 1
        var nextStorage: [MetalTerrainBufferCacheKey: MetalTerrainMeshBuffers] = [:]
        var buffers: [MetalTerrainMeshBuffers] = []
        var createdCount = 0
        var reusedCount = 0

        for descriptor in descriptors {
            let key = MetalTerrainBufferCacheKey(
                descriptor: descriptor,
                verticalScale: safeVerticalScale
            )

            if let existing = storage[key] {
                nextStorage[key] = existing
                buffers.append(existing)
                reusedCount += 1
                continue
            }

            let uploaded = try uploader.upload(
                descriptors: [descriptor],
                verticalScale: safeVerticalScale
            )
            guard let buffer = uploaded.buffers.first else {
                throw MetalDebugRenderError.emptyMeshPayload(descriptor.meshPayload.stableHash)
            }
            nextStorage[key] = buffer
            buffers.append(buffer)
            createdCount += 1
        }

        let evictedCount = storage.keys.filter { nextStorage[$0] == nil }.count
        storage = nextStorage

        return MetalTerrainBufferCacheUpdate(
            buffers: buffers,
            createdCount: createdCount,
            reusedCount: reusedCount,
            evictedCount: evictedCount
        )
    }
}
