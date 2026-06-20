public struct WorldResidencyRequest: Hashable, Codable, Sendable, StableHashable {
    public let worldSeed: WorldSeed
    public let generatorVersion: TerrainGeneratorVersion
    public let centerWorldPosition: TEVec3f
    public let centerChunkCoord: WorldChunkCoord
    public let layout: TerrainChunkLayout
    public let profile: TerrainGenerationProfile
    public let config: WorldResidencyConfig
    public let cameraForward: TEVec3f?
    public let playerVelocity: TEVec3f?

    public init(
        worldSeed: WorldSeed,
        generatorVersion: TerrainGeneratorVersion = .phase1,
        centerWorldPosition: TEVec3f,
        centerChunkCoord: WorldChunkCoord,
        layout: TerrainChunkLayout = .phase1Default,
        profile: TerrainGenerationProfile = .defaultProcedural,
        config: WorldResidencyConfig,
        cameraForward: TEVec3f? = nil,
        playerVelocity: TEVec3f? = nil
    ) {
        self.worldSeed = worldSeed
        self.generatorVersion = generatorVersion
        self.centerWorldPosition = centerWorldPosition
        self.centerChunkCoord = centerChunkCoord
        self.layout = layout
        self.profile = profile
        self.config = config
        self.cameraForward = cameraForward
        self.playerVelocity = playerVelocity
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9E90_0001,
            worldSeed.stableHash,
            generatorVersion.stableHash,
            centerWorldPosition.stableHash,
            centerChunkCoord.stableHash,
            layout.stableHash,
            profile.stableHash,
            config.stableHash,
            optionalHash(cameraForward),
            cameraForward == nil ? 0 : 1,
            optionalHash(playerVelocity),
            playerVelocity == nil ? 0 : 1
        )
    }

    private func optionalHash(_ value: TEVec3f?) -> UInt64 {
        value?.stableHash ?? 0
    }
}
