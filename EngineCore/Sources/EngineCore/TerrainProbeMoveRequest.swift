public struct TerrainProbeMoveRequest: Hashable, Codable, Sendable, StableHashable {
    public let deltaX: Float
    public let deltaZ: Float
    public let queryMode: TerrainQueryMode

    public init(
        deltaX: Float,
        deltaZ: Float,
        queryMode: TerrainQueryMode = .bilinearHeightfield
    ) {
        self.deltaX = deltaX.isFinite ? deltaX : 0
        self.deltaZ = deltaZ.isFinite ? deltaZ : 0
        self.queryMode = queryMode
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9B20_0001,
            StableHasher.bits(deltaX),
            StableHasher.bits(deltaZ),
            queryMode.stableHash
        )
    }
}

