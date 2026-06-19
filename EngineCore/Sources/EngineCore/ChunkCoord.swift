public struct ChunkCoord: Hashable, Codable, Sendable, StableHashable {
    public let x: Int32
    public let y: Int32
    public let z: Int32

    public init(x: Int32, y: Int32 = 0, z: Int32) {
        self.x = x
        self.y = y
        self.z = z
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_C0A0_D001,
            StableHasher.bits(x),
            StableHasher.bits(y),
            StableHasher.bits(z)
        )
    }
}

