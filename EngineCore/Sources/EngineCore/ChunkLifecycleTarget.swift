public struct ChunkLifecycleTarget: Hashable, Codable, Sendable, StableHashable {
    public let chunkID: WorldChunkID
    public let chunkCoord: WorldChunkCoord
    public let targetState: ChunkLifecycleState
    public let reason: WorldResidencyReason
    public let priority: WorldResidencyPriority

    public init(
        chunkID: WorldChunkID,
        chunkCoord: WorldChunkCoord,
        targetState: ChunkLifecycleState,
        reason: WorldResidencyReason,
        priority: WorldResidencyPriority
    ) {
        self.chunkID = chunkID
        self.chunkCoord = chunkCoord
        self.targetState = targetState
        self.reason = reason
        self.priority = priority
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_7A90_7E01,
            chunkID.stableHash,
            chunkCoord.stableHash,
            targetState.stableHash,
            reason.stableHash,
            priority.stableHash
        )
    }
}

