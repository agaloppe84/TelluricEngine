public struct StreamingCellDescriptor: Hashable, Codable, Sendable, StableHashable {
    public let cellCoord: StreamingCellCoord
    public let chunkIDs: [WorldChunkID]
    public let targetState: ChunkLifecycleState
    public let reason: WorldResidencyReason
    public let priority: WorldResidencyPriority

    public init(
        cellCoord: StreamingCellCoord,
        chunkIDs: [WorldChunkID],
        targetState: ChunkLifecycleState,
        reason: WorldResidencyReason,
        priority: WorldResidencyPriority
    ) {
        self.cellCoord = cellCoord
        self.chunkIDs = chunkIDs
        self.targetState = targetState
        self.reason = reason
        self.priority = priority
    }

    public var stableHash: UInt64 {
        var state = StableHasher.hash(
            seed: 0x7E11_571C_CE11_D001,
            cellCoord.stableHash,
            targetState.stableHash,
            reason.stableHash,
            priority.stableHash
        )
        for chunkID in chunkIDs {
            state = StableHasher.combine(state, chunkID.stableHash)
        }
        return StableHasher.combine(state, UInt64(chunkIDs.count))
    }
}

