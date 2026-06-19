public struct TerrainProbe: Hashable, Codable, Sendable, StableHashable {
    public let id: UInt64
    public let worldPosition: TerrainWorldPosition
    public let lastQueryResult: TerrainQueryResult?
    public let isGrounded: Bool
    public let walkability: TerrainWalkability
    public let stableHash: UInt64

    public init(
        id: UInt64 = 1,
        worldPosition: TerrainWorldPosition,
        lastQueryResult: TerrainQueryResult?,
        isGrounded: Bool,
        walkability: TerrainWalkability
    ) {
        self.id = id
        self.worldPosition = worldPosition
        self.lastQueryResult = lastQueryResult
        self.isGrounded = isGrounded
        self.walkability = walkability
        self.stableHash = Self.computeStableHash(
            id: id,
            worldPosition: worldPosition,
            lastQueryResult: lastQueryResult,
            isGrounded: isGrounded,
            walkability: walkability
        )
    }

    private static func computeStableHash(
        id: UInt64,
        worldPosition: TerrainWorldPosition,
        lastQueryResult: TerrainQueryResult?,
        isGrounded: Bool,
        walkability: TerrainWalkability
    ) -> UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9B10_0001,
            id,
            worldPosition.stableHash,
            lastQueryResult?.stableHash ?? 0,
            lastQueryResult == nil ? 0 : 1,
            isGrounded ? 1 : 0,
            walkability.stableHash
        )
    }
}

