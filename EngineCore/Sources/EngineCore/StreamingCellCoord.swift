public struct StreamingCellCoord: Hashable, Codable, Sendable, StableHashable, Comparable {
    public let x: Int32
    public let z: Int32

    public init(x: Int32, z: Int32) {
        self.x = x
        self.z = z
    }

    public init(chunkCoord: WorldChunkCoord, cellSizeChunks: Int) {
        precondition(cellSizeChunks > 0, "Streaming cell size must be positive.")

        self.x = Int32(Self.floorDiv(Int(chunkCoord.x), cellSizeChunks))
        self.z = Int32(Self.floorDiv(Int(chunkCoord.z), cellSizeChunks))
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_CE11_0001,
            StableHasher.bits(x),
            StableHasher.bits(z)
        )
    }

    public static func < (lhs: StreamingCellCoord, rhs: StreamingCellCoord) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        }
        return lhs.z < rhs.z
    }

    private static func floorDiv(_ value: Int, _ divisor: Int) -> Int {
        let quotient = value / divisor
        let remainder = value % divisor
        if remainder != 0 && ((remainder > 0) != (divisor > 0)) {
            return quotient - 1
        }
        return quotient
    }
}

