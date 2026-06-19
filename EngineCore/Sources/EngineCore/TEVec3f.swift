public struct TEVec3f: Hashable, Codable, Sendable, StableHashable {
    public static let zero = TEVec3f(x: 0, y: 0, z: 0)
    public static let up = TEVec3f(x: 0, y: 1, z: 0)

    public let x: Float
    public let y: Float
    public let z: Float

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static func + (lhs: TEVec3f, rhs: TEVec3f) -> TEVec3f {
        TEVec3f(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    public static func - (lhs: TEVec3f, rhs: TEVec3f) -> TEVec3f {
        TEVec3f(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    public static func * (lhs: TEVec3f, rhs: Float) -> TEVec3f {
        TEVec3f(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    public func dot(_ other: TEVec3f) -> Float {
        x * other.x + y * other.y + z * other.z
    }

    public func cross(_ other: TEVec3f) -> TEVec3f {
        TEVec3f(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    public var lengthSquared: Float {
        dot(self)
    }

    public var normalized: TEVec3f {
        let lengthSquared = self.lengthSquared
        if lengthSquared <= 0 {
            return .zero
        }

        return self * (1.0 / lengthSquared.squareRoot())
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_3F00_0001,
            StableHasher.bits(x),
            StableHasher.bits(y),
            StableHasher.bits(z)
        )
    }
}

