public struct TEBounds3f: Hashable, Codable, Sendable, StableHashable {
    public private(set) var min: TEVec3f
    public private(set) var max: TEVec3f

    public init(min: TEVec3f, max: TEVec3f) {
        self.min = min
        self.max = max
    }

    public init(firstPoint: TEVec3f) {
        self.min = firstPoint
        self.max = firstPoint
    }

    public mutating func include(_ point: TEVec3f) {
        min = TEVec3f(
            x: Swift.min(min.x, point.x),
            y: Swift.min(min.y, point.y),
            z: Swift.min(min.z, point.z)
        )
        max = TEVec3f(
            x: Swift.max(max.x, point.x),
            y: Swift.max(max.y, point.y),
            z: Swift.max(max.z, point.z)
        )
    }

    public func contains(_ point: TEVec3f) -> Bool {
        point.x >= min.x && point.x <= max.x
            && point.y >= min.y && point.y <= max.y
            && point.z >= min.z && point.z <= max.z
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_B0A0_0001,
            min.stableHash,
            max.stableHash
        )
    }
}

