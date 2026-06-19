public struct ChunkBuildResult: Hashable, Codable, Sendable, StableHashable {
    public let planHash: UInt64
    public let mutationSummary: WorldCacheMutationSummary
    public let snapshot: ResidentWorldSnapshot
    public let stableHash: UInt64

    public init(
        planHash: UInt64,
        mutationSummary: WorldCacheMutationSummary,
        snapshot: ResidentWorldSnapshot
    ) {
        self.planHash = planHash
        self.mutationSummary = mutationSummary
        self.snapshot = snapshot
        self.stableHash = StableHasher.hash(
            seed: 0x7E11_571C_B111_D002,
            planHash,
            mutationSummary.stableHash,
            snapshot.stableHash
        )
    }
}
