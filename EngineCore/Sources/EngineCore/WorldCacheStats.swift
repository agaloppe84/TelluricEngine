public struct WorldCacheStats: Hashable, Codable, Sendable, StableHashable {
    public let totalRecords: Int
    public let samplePayloadRecords: Int
    public let meshPayloadRecords: Int
    public let residentRecords: Int
    public let activeRecords: Int
    public let renderCandidateRecords: Int
    public let estimatedVertexCount: Int
    public let estimatedIndexCount: Int

    public init(
        totalRecords: Int,
        samplePayloadRecords: Int,
        meshPayloadRecords: Int,
        residentRecords: Int,
        activeRecords: Int,
        renderCandidateRecords: Int,
        estimatedVertexCount: Int,
        estimatedIndexCount: Int
    ) {
        self.totalRecords = totalRecords
        self.samplePayloadRecords = samplePayloadRecords
        self.meshPayloadRecords = meshPayloadRecords
        self.residentRecords = residentRecords
        self.activeRecords = activeRecords
        self.renderCandidateRecords = renderCandidateRecords
        self.estimatedVertexCount = estimatedVertexCount
        self.estimatedIndexCount = estimatedIndexCount
    }

    public init(records: [CachedChunkRecord]) {
        var samplePayloadRecords = 0
        var meshPayloadRecords = 0
        var residentRecords = 0
        var activeRecords = 0
        var renderCandidateRecords = 0
        var estimatedVertexCount = 0
        var estimatedIndexCount = 0

        for record in records {
            if record.samplePayload != nil {
                samplePayloadRecords += 1
            }
            if let meshPayload = record.meshPayload {
                meshPayloadRecords += 1
                estimatedVertexCount += meshPayload.vertices.count
                estimatedIndexCount += meshPayload.indices.count
            }
            if record.lifecycleState == .resident {
                residentRecords += 1
            }
            if record.lifecycleState == .active {
                activeRecords += 1
            }
            if record.renderCandidate != nil {
                renderCandidateRecords += 1
            }
        }

        self.init(
            totalRecords: records.count,
            samplePayloadRecords: samplePayloadRecords,
            meshPayloadRecords: meshPayloadRecords,
            residentRecords: residentRecords,
            activeRecords: activeRecords,
            renderCandidateRecords: renderCandidateRecords,
            estimatedVertexCount: estimatedVertexCount,
            estimatedIndexCount: estimatedIndexCount
        )
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_CA7E_57A7,
            StableHasher.bits(totalRecords),
            StableHasher.bits(samplePayloadRecords),
            StableHasher.bits(meshPayloadRecords),
            StableHasher.bits(residentRecords),
            StableHasher.bits(activeRecords),
            StableHasher.bits(renderCandidateRecords),
            StableHasher.bits(estimatedVertexCount),
            StableHasher.bits(estimatedIndexCount)
        )
    }
}
