public struct MetalTerrainMeshUploadResult {
    public let buffers: [MetalTerrainMeshBuffers]
    public let totalVertexCount: Int
    public let totalIndexCount: Int

    public init(buffers: [MetalTerrainMeshBuffers]) {
        self.buffers = buffers
        self.totalVertexCount = buffers.reduce(0) { $0 + $1.vertexCount }
        self.totalIndexCount = buffers.reduce(0) { $0 + $1.indexCount }
    }
}
