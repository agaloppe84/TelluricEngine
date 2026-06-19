public struct TerrainProbeMoveResult: Hashable, Codable, Sendable, StableHashable {
    public let previousProbe: TerrainProbe?
    public let probe: TerrainProbe
    public let queryResult: TerrainQueryResult
    public let didMove: Bool
    public let stableHash: UInt64

    public init(
        previousProbe: TerrainProbe?,
        probe: TerrainProbe,
        queryResult: TerrainQueryResult,
        didMove: Bool
    ) {
        self.previousProbe = previousProbe
        self.probe = probe
        self.queryResult = queryResult
        self.didMove = didMove
        self.stableHash = Self.computeStableHash(
            previousProbe: previousProbe,
            probe: probe,
            queryResult: queryResult,
            didMove: didMove
        )
    }

    private static func computeStableHash(
        previousProbe: TerrainProbe?,
        probe: TerrainProbe,
        queryResult: TerrainQueryResult,
        didMove: Bool
    ) -> UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9B21_0001,
            previousProbe?.stableHash ?? 0,
            previousProbe == nil ? 0 : 1,
            probe.stableHash,
            queryResult.stableHash,
            didMove ? 1 : 0
        )
    }
}

