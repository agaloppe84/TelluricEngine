public struct ChunkBuildRequest: Hashable, Codable, Sendable, StableHashable {
    public let target: ChunkLifecycleTarget
    public let planHash: UInt64

    public init(target: ChunkLifecycleTarget, planHash: UInt64) {
        self.target = target
        self.planHash = planHash
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_B111_D001,
            target.stableHash,
            planHash
        )
    }
}
