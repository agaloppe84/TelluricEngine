import EngineCore
import Metal

public struct MetalTerrainMeshBuffers {
    public let vertexBuffer: MTLBuffer
    public let indexBuffer: MTLBuffer
    public let vertexCount: Int
    public let indexCount: Int
    public let chunkID: WorldChunkID?
    public let debugName: String
    public let bounds: TerrainMeshBounds
    public let meshStableHash: UInt64

    public init(
        vertexBuffer: MTLBuffer,
        indexBuffer: MTLBuffer,
        vertexCount: Int,
        indexCount: Int,
        chunkID: WorldChunkID?,
        debugName: String,
        bounds: TerrainMeshBounds,
        meshStableHash: UInt64
    ) {
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        self.vertexCount = vertexCount
        self.indexCount = indexCount
        self.chunkID = chunkID
        self.debugName = debugName
        self.bounds = bounds
        self.meshStableHash = meshStableHash
    }
}
