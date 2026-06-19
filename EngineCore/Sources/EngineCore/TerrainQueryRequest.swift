public struct TerrainQueryRequest: Hashable, Codable, Sendable, StableHashable {
    public let worldX: Float
    public let worldZ: Float
    public let queryMode: TerrainQueryMode

    public init(
        worldX: Float,
        worldZ: Float,
        queryMode: TerrainQueryMode = .bilinearHeightfield
    ) {
        self.worldX = worldX
        self.worldZ = worldZ
        self.queryMode = queryMode
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_90BE_0001,
            StableHasher.bits(worldX),
            StableHasher.bits(worldZ),
            queryMode.stableHash
        )
    }
}

