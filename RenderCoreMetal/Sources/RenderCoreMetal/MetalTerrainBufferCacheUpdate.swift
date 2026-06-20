public struct MetalTerrainBufferCacheUpdate {
    public let buffers: [MetalTerrainMeshBuffers]
    public let createdCount: Int
    public let reusedCount: Int
    public let evictedCount: Int

    public init(
        buffers: [MetalTerrainMeshBuffers],
        createdCount: Int,
        reusedCount: Int,
        evictedCount: Int
    ) {
        self.buffers = buffers
        self.createdCount = createdCount
        self.reusedCount = reusedCount
        self.evictedCount = evictedCount
    }
}
