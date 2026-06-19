public struct TerrainWorldPosition: Hashable, Codable, Sendable, StableHashable {
    public let x: Float
    public let y: Float
    public let z: Float

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_90A9_0001,
            StableHasher.bits(x),
            StableHasher.bits(y),
            StableHasher.bits(z)
        )
    }
}

