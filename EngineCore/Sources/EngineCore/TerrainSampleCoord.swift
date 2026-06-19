public struct TerrainSampleCoord: Hashable, Codable, Sendable, StableHashable {
    public let x: Int64
    public let z: Int64

    public init(x: Int64, z: Int64) {
        self.x = x
        self.z = z
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_7C00_A001,
            StableHasher.bits(x),
            StableHasher.bits(z)
        )
    }
}

