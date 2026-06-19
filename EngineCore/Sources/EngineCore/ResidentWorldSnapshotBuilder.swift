public enum ResidentWorldSnapshotBuilder {
    public static func makeSnapshot(
        planHash: UInt64?,
        records: [CachedChunkRecord]
    ) -> ResidentWorldSnapshot {
        let sortedRecords = records.sorted(by: InMemoryWorldCache.isRecordOrderedBefore)
        let activeRecords = sortedRecords.filter { $0.lifecycleState == .active }
        let residentRecords = sortedRecords.filter { $0.lifecycleState == .resident }
        let renderCandidates = sortedRecords
            .compactMap(\.renderCandidate)
            .sorted(by: InMemoryWorldCache.isRenderCandidateOrderedBefore)
        let stats = WorldCacheStats(records: sortedRecords)
        let cacheHash = InMemoryWorldCache.computeStableHash(records: sortedRecords)

        return ResidentWorldSnapshot(
            planHash: planHash,
            cacheHash: cacheHash,
            records: sortedRecords,
            activeRecords: activeRecords,
            residentRecords: residentRecords,
            renderCandidates: renderCandidates,
            stats: stats
        )
    }
}
