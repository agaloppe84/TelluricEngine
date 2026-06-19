public struct SimulationChunkDescriptor: Hashable, Codable, Sendable, StableHashable {
    public let chunkID: WorldChunkID
    public let chunkCoord: WorldChunkCoord
    public let worldSeed: WorldSeed
    public let generatorVersion: TerrainGeneratorVersion
    public let layout: TerrainChunkLayout
    public let targetState: ChunkLifecycleState
    public let priority: WorldResidencyPriority

    public init(target: ChunkLifecycleTarget) {
        self.chunkID = target.chunkID
        self.chunkCoord = target.chunkCoord
        self.worldSeed = target.chunkID.worldSeed
        self.generatorVersion = target.chunkID.generatorVersion
        self.layout = target.chunkID.layout
        self.targetState = target.targetState
        self.priority = target.priority
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_514C_0001,
            chunkID.stableHash,
            chunkCoord.stableHash,
            worldSeed.stableHash,
            generatorVersion.stableHash,
            layout.stableHash,
            targetState.stableHash,
            priority.stableHash
        )
    }
}

