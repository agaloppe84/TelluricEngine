public struct CachedChunkRecord: Hashable, Codable, Sendable, StableHashable {
    public let chunkID: WorldChunkID
    public let chunkCoord: WorldChunkCoord
    public let lifecycleState: ChunkLifecycleState
    public let payloadState: CachedChunkPayloadState
    public let priority: WorldResidencyPriority
    public let samplePayload: ChunkTerrainSamplePayload?
    public let meshPayload: TerrainMeshPayload?
    public let renderCandidate: RenderCandidateDescriptor?
    public let lastPlanHash: UInt64?
    public let stableHash: UInt64

    public init(
        chunkID: WorldChunkID,
        chunkCoord: WorldChunkCoord,
        lifecycleState: ChunkLifecycleState,
        payloadState: CachedChunkPayloadState,
        priority: WorldResidencyPriority,
        samplePayload: ChunkTerrainSamplePayload? = nil,
        meshPayload: TerrainMeshPayload? = nil,
        renderCandidate: RenderCandidateDescriptor? = nil,
        lastPlanHash: UInt64? = nil
    ) {
        self.chunkID = chunkID
        self.chunkCoord = chunkCoord
        self.lifecycleState = lifecycleState
        self.payloadState = payloadState
        self.priority = priority
        self.samplePayload = samplePayload
        self.meshPayload = meshPayload
        self.renderCandidate = renderCandidate
        self.lastPlanHash = lastPlanHash
        self.stableHash = Self.computeStableHash(
            chunkID: chunkID,
            chunkCoord: chunkCoord,
            lifecycleState: lifecycleState,
            payloadState: payloadState,
            priority: priority,
            samplePayload: samplePayload,
            meshPayload: meshPayload,
            renderCandidate: renderCandidate,
            lastPlanHash: lastPlanHash
        )
    }

    public var hasSamplePayload: Bool {
        samplePayload != nil
    }

    public var hasMeshPayload: Bool {
        meshPayload != nil
    }

    private static func computeStableHash(
        chunkID: WorldChunkID,
        chunkCoord: WorldChunkCoord,
        lifecycleState: ChunkLifecycleState,
        payloadState: CachedChunkPayloadState,
        priority: WorldResidencyPriority,
        samplePayload: ChunkTerrainSamplePayload?,
        meshPayload: TerrainMeshPayload?,
        renderCandidate: RenderCandidateDescriptor?,
        lastPlanHash: UInt64?
    ) -> UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_CA7E_0002,
            chunkID.stableHash,
            chunkCoord.stableHash,
            lifecycleState.stableHash,
            payloadState.stableHash,
            priority.stableHash,
            samplePayload?.stableHash ?? 0,
            samplePayload == nil ? 0 : 1,
            meshPayload?.stableHash ?? 0,
            meshPayload == nil ? 0 : 1,
            renderCandidate?.stableHash ?? 0,
            renderCandidate == nil ? 0 : 1,
            lastPlanHash ?? 0,
            lastPlanHash == nil ? 0 : 1
        )
    }
}
