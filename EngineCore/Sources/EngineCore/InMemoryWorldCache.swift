public struct InMemoryWorldCache: Hashable, Codable, Sendable, StableHashable {
    private var storage: [WorldChunkID: CachedChunkRecord]

    public init() {
        self.storage = [:]
    }

    public init(records: [CachedChunkRecord]) {
        var storage: [WorldChunkID: CachedChunkRecord] = [:]
        for record in records {
            storage[record.chunkID] = record
        }
        self.storage = storage
    }

    public var records: [CachedChunkRecord] {
        storage.values.sorted(by: Self.isRecordOrderedBefore)
    }

    public var stableHash: UInt64 {
        Self.computeStableHash(records: records)
    }

    public func record(for id: WorldChunkID) -> CachedChunkRecord? {
        storage[id]
    }

    public func contains(_ id: WorldChunkID) -> Bool {
        storage[id] != nil
    }

    public mutating func upsert(_ record: CachedChunkRecord) {
        storage[record.chunkID] = record
    }

    @discardableResult
    public mutating func remove(_ id: WorldChunkID) -> CachedChunkRecord? {
        storage.removeValue(forKey: id)
    }

    public mutating func removeAll() {
        storage.removeAll()
    }

    public func snapshot(planHash: UInt64? = nil) -> ResidentWorldSnapshot {
        ResidentWorldSnapshotBuilder.makeSnapshot(planHash: planHash, records: records)
    }

    public static func isRecordOrderedBefore(
        _ lhs: CachedChunkRecord,
        _ rhs: CachedChunkRecord
    ) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }
        if lhs.chunkCoord != rhs.chunkCoord {
            return lhs.chunkCoord < rhs.chunkCoord
        }
        return lhs.chunkID < rhs.chunkID
    }

    public static func isRenderCandidateOrderedBefore(
        _ lhs: RenderCandidateDescriptor,
        _ rhs: RenderCandidateDescriptor
    ) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }
        if lhs.chunkCoord != rhs.chunkCoord {
            return lhs.chunkCoord < rhs.chunkCoord
        }
        return lhs.chunkID < rhs.chunkID
    }

    public static func computeStableHash(records: [CachedChunkRecord]) -> UInt64 {
        var state = StableHasher.hash(seed: 0x7E11_571C_CA7E_0003)
        let sortedRecords = records.sorted(by: Self.isRecordOrderedBefore)

        for record in sortedRecords {
            state = StableHasher.combine(state, record.stableHash)
        }

        return StableHasher.combine(state, UInt64(sortedRecords.count))
    }
}
