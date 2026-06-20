import EngineCore

public struct MetalTerrainMeshDescriptor: Hashable {
    public let meshPayload: TerrainMeshPayload
    public let chunkID: WorldChunkID?
    public let lifecycleState: ChunkLifecycleState
    public let payloadState: CachedChunkPayloadState?
    public let colorMode: MetalDebugTerrainColorMode
    public let renderMode: MetalTerrainRenderMode
    public let isSelected: Bool
    public let debugName: String

    public init(
        meshPayload: TerrainMeshPayload,
        chunkID: WorldChunkID? = nil,
        lifecycleState: ChunkLifecycleState = .meshRequested,
        payloadState: CachedChunkPayloadState? = nil,
        colorMode: MetalDebugTerrainColorMode = .mixed,
        renderMode: MetalTerrainRenderMode = .debug,
        isSelected: Bool = false,
        debugName: String? = nil
    ) {
        self.meshPayload = meshPayload
        self.chunkID = chunkID
        self.lifecycleState = lifecycleState
        self.payloadState = payloadState
        self.colorMode = colorMode
        self.renderMode = renderMode
        self.isSelected = isSelected
        self.debugName = debugName ?? "chunk-\(meshPayload.chunkCoord.x)-\(meshPayload.chunkCoord.z)"
    }
}
