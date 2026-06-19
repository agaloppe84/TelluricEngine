public struct ResidentWorldSnapshot: Hashable, Codable, Sendable, StableHashable {
    public let planHash: UInt64?
    public let cacheHash: UInt64
    public let records: [CachedChunkRecord]
    public let activeRecords: [CachedChunkRecord]
    public let residentRecords: [CachedChunkRecord]
    public let renderCandidates: [RenderCandidateDescriptor]
    public let stats: WorldCacheStats
    public let stableHash: UInt64

    public init(
        planHash: UInt64?,
        cacheHash: UInt64,
        records: [CachedChunkRecord],
        activeRecords: [CachedChunkRecord],
        residentRecords: [CachedChunkRecord],
        renderCandidates: [RenderCandidateDescriptor],
        stats: WorldCacheStats
    ) {
        self.planHash = planHash
        self.cacheHash = cacheHash
        self.records = records
        self.activeRecords = activeRecords
        self.residentRecords = residentRecords
        self.renderCandidates = renderCandidates
        self.stats = stats
        self.stableHash = Self.computeStableHash(
            planHash: planHash,
            cacheHash: cacheHash,
            records: records,
            activeRecords: activeRecords,
            residentRecords: residentRecords,
            renderCandidates: renderCandidates,
            stats: stats
        )
    }

    private static func computeStableHash(
        planHash: UInt64?,
        cacheHash: UInt64,
        records: [CachedChunkRecord],
        activeRecords: [CachedChunkRecord],
        residentRecords: [CachedChunkRecord],
        renderCandidates: [RenderCandidateDescriptor],
        stats: WorldCacheStats
    ) -> UInt64 {
        var state = StableHasher.hash(
            seed: 0x7E11_571C_5AA9_0001,
            planHash ?? 0,
            planHash == nil ? 0 : 1,
            cacheHash,
            stats.stableHash
        )

        for record in records {
            state = StableHasher.combine(state, record.stableHash)
        }
        for record in activeRecords {
            state = StableHasher.combine(state, record.stableHash)
        }
        for record in residentRecords {
            state = StableHasher.combine(state, record.stableHash)
        }
        for candidate in renderCandidates {
            state = StableHasher.combine(state, candidate.stableHash)
        }

        state = StableHasher.combine(state, UInt64(records.count))
        state = StableHasher.combine(state, UInt64(activeRecords.count))
        state = StableHasher.combine(state, UInt64(residentRecords.count))
        return StableHasher.combine(state, UInt64(renderCandidates.count))
    }
}
