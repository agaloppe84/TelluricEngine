public struct RenderCandidateDescriptor: Hashable, Codable, Sendable, StableHashable {
    public let chunkID: WorldChunkID
    public let chunkCoord: WorldChunkCoord
    public let priority: WorldResidencyPriority
    public let targetState: ChunkLifecycleState
    public let bounds: TerrainMeshBounds?
    public let meshStableHash: UInt64?
    public let surfaceStableHash: UInt64?

    public init(
        chunkID: WorldChunkID,
        chunkCoord: WorldChunkCoord,
        priority: WorldResidencyPriority,
        targetState: ChunkLifecycleState,
        bounds: TerrainMeshBounds? = nil,
        meshStableHash: UInt64? = nil,
        surfaceStableHash: UInt64? = nil
    ) {
        self.chunkID = chunkID
        self.chunkCoord = chunkCoord
        self.priority = priority
        self.targetState = targetState
        self.bounds = bounds
        self.meshStableHash = meshStableHash
        self.surfaceStableHash = surfaceStableHash
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9E7D_0001,
            chunkID.stableHash,
            chunkCoord.stableHash,
            priority.stableHash,
            targetState.stableHash,
            bounds?.stableHash ?? 0,
            bounds == nil ? 0 : 1,
            meshStableHash ?? 0,
            meshStableHash == nil ? 0 : 1,
            surfaceStableHash ?? 0,
            surfaceStableHash == nil ? 0 : 1
        )
    }
}

