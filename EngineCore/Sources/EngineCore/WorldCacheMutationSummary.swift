public struct WorldCacheMutationSummary: Hashable, Codable, Sendable, StableHashable {
    public var createdCount: Int
    public var updatedCount: Int
    public var reusedCount: Int
    public var evictedCount: Int
    public var samplePayloadCount: Int
    public var meshPayloadCount: Int
    public var renderCandidateCount: Int

    public init(
        createdCount: Int = 0,
        updatedCount: Int = 0,
        reusedCount: Int = 0,
        evictedCount: Int = 0,
        samplePayloadCount: Int = 0,
        meshPayloadCount: Int = 0,
        renderCandidateCount: Int = 0
    ) {
        self.createdCount = createdCount
        self.updatedCount = updatedCount
        self.reusedCount = reusedCount
        self.evictedCount = evictedCount
        self.samplePayloadCount = samplePayloadCount
        self.meshPayloadCount = meshPayloadCount
        self.renderCandidateCount = renderCandidateCount
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_CA7E_1001,
            StableHasher.bits(createdCount),
            StableHasher.bits(updatedCount),
            StableHasher.bits(reusedCount),
            StableHasher.bits(evictedCount),
            StableHasher.bits(samplePayloadCount),
            StableHasher.bits(meshPayloadCount),
            StableHasher.bits(renderCandidateCount)
        )
    }
}
