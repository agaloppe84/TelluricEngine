public struct TerrainSample: Hashable, Codable, Sendable, StableHashable {
    public let coord: TerrainSampleCoord
    public let scalarValue: Double
    public let heightMeters: Double
    public let valueHash: UInt64

    public init(
        coord: TerrainSampleCoord,
        scalarValue: Double,
        heightMeters: Double,
        valueHash: UInt64
    ) {
        self.coord = coord
        self.scalarValue = scalarValue
        self.heightMeters = heightMeters
        self.valueHash = valueHash
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_54A9_0001,
            coord.stableHash,
            valueHash
        )
    }
}

