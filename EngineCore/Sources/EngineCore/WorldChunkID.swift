public struct WorldChunkID: Hashable, Codable, Sendable, StableHashable, Comparable {
    public let worldSeed: WorldSeed
    public let generatorVersion: TerrainGeneratorVersion
    public let layout: TerrainChunkLayout
    public let coord: WorldChunkCoord

    public init(
        worldSeed: WorldSeed,
        generatorVersion: TerrainGeneratorVersion,
        layout: TerrainChunkLayout,
        coord: WorldChunkCoord
    ) {
        self.worldSeed = worldSeed
        self.generatorVersion = generatorVersion
        self.layout = layout
        self.coord = coord
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_C1D0_0001,
            worldSeed.stableHash,
            generatorVersion.stableHash,
            layout.stableHash,
            coord.stableHash
        )
    }

    public static func < (lhs: WorldChunkID, rhs: WorldChunkID) -> Bool {
        if lhs.coord != rhs.coord {
            return lhs.coord < rhs.coord
        }
        if lhs.worldSeed.rawValue != rhs.worldSeed.rawValue {
            return lhs.worldSeed.rawValue < rhs.worldSeed.rawValue
        }
        if lhs.generatorVersion.stableHash != rhs.generatorVersion.stableHash {
            return lhs.generatorVersion.stableHash < rhs.generatorVersion.stableHash
        }
        return lhs.layout.stableHash < rhs.layout.stableHash
    }
}

