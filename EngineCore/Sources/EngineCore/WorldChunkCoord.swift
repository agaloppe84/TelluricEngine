public struct WorldChunkCoord: Hashable, Codable, Sendable, StableHashable, Comparable {
    public let x: Int32
    public let z: Int32

    public init(x: Int32, z: Int32) {
        self.x = x
        self.z = z
    }

    public init(chunkCoord: ChunkCoord) {
        self.x = chunkCoord.x
        self.z = chunkCoord.z
    }

    public var chunkCoord: ChunkCoord {
        ChunkCoord(x: x, z: z)
    }

    public func chebyshevDistance(to other: WorldChunkCoord) -> Int {
        let dx = Swift.abs(Int(x) - Int(other.x))
        let dz = Swift.abs(Int(z) - Int(other.z))
        return Swift.max(dx, dz)
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_C400_0001,
            StableHasher.bits(x),
            StableHasher.bits(z)
        )
    }

    public static func < (lhs: WorldChunkCoord, rhs: WorldChunkCoord) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        }
        return lhs.z < rhs.z
    }
}

