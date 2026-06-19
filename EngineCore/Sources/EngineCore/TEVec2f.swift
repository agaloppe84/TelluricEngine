public struct TEVec2f: Hashable, Codable, Sendable, StableHashable {
    public let x: Float
    public let y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    public static func + (lhs: TEVec2f, rhs: TEVec2f) -> TEVec2f {
        TEVec2f(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: TEVec2f, rhs: TEVec2f) -> TEVec2f {
        TEVec2f(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func * (lhs: TEVec2f, rhs: Float) -> TEVec2f {
        TEVec2f(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_2F00_0001,
            StableHasher.bits(x),
            StableHasher.bits(y)
        )
    }
}

