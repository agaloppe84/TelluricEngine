import EngineCore

public struct MetalTerrainMeshDescriptor: Hashable {
    public let meshPayload: TerrainMeshPayload
    public let chunkID: WorldChunkID?
    public let lifecycleState: ChunkLifecycleState
    public let payloadState: CachedChunkPayloadState?
    public let debugName: String

    public init(
        meshPayload: TerrainMeshPayload,
        chunkID: WorldChunkID? = nil,
        lifecycleState: ChunkLifecycleState = .meshRequested,
        payloadState: CachedChunkPayloadState? = nil,
        debugName: String? = nil
    ) {
        self.meshPayload = meshPayload
        self.chunkID = chunkID
        self.lifecycleState = lifecycleState
        self.payloadState = payloadState
        self.debugName = debugName ?? "chunk-\(meshPayload.chunkCoord.x)-\(meshPayload.chunkCoord.z)"
    }
}
