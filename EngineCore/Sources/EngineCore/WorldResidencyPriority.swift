public struct WorldResidencyPriority: Hashable, Codable, Sendable, StableHashable, Comparable {
    public let rank: Int
    public let distanceChunks: Int
    public let stateRank: Int
    public let reasonRank: Int

    public init(
        distanceChunks: Int,
        targetState: ChunkLifecycleState,
        reason: WorldResidencyReason
    ) {
        precondition(distanceChunks >= 0, "World residency distance cannot be negative.")

        self.distanceChunks = distanceChunks
        self.stateRank = targetState.priorityRank
        self.reasonRank = reason.priorityRank
        self.rank = distanceChunks * 100 + targetState.priorityRank * 10 + reason.priorityRank
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9A10_0001,
            StableHasher.bits(rank),
            StableHasher.bits(distanceChunks),
            StableHasher.bits(stateRank),
            StableHasher.bits(reasonRank)
        )
    }

    public static func < (lhs: WorldResidencyPriority, rhs: WorldResidencyPriority) -> Bool {
        if lhs.rank != rhs.rank {
            return lhs.rank < rhs.rank
        }
        if lhs.distanceChunks != rhs.distanceChunks {
            return lhs.distanceChunks < rhs.distanceChunks
        }
        if lhs.stateRank != rhs.stateRank {
            return lhs.stateRank < rhs.stateRank
        }
        return lhs.reasonRank < rhs.reasonRank
    }
}

