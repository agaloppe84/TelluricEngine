public struct TerrainGeneratorVersion: Hashable, Codable, Sendable, StableHashable {
    public static let phase1 = TerrainGeneratorVersion(major: 1, minor: 0, patch: 0)

    public let major: UInt32
    public let minor: UInt32
    public let patch: UInt32

    public init(major: UInt32, minor: UInt32, patch: UInt32) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_7E44_0001,
            StableHasher.bits(major),
            StableHasher.bits(minor),
            StableHasher.bits(patch)
        )
    }
}

