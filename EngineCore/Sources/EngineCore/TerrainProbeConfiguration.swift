public struct TerrainProbeConfiguration: Hashable, Codable, Sendable, StableHashable {
    public static let `default` = TerrainProbeConfiguration()

    public let walkabilityConfig: TerrainWalkabilityConfig
    public let allowsNonWalkableMovement: Bool

    public init(
        walkabilityConfig: TerrainWalkabilityConfig = .default,
        allowsNonWalkableMovement: Bool = true
    ) {
        self.walkabilityConfig = walkabilityConfig
        self.allowsNonWalkableMovement = allowsNonWalkableMovement
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9B00_0001,
            walkabilityConfig.stableHash,
            allowsNonWalkableMovement ? 1 : 0
        )
    }
}

