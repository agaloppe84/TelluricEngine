public struct TerrainQueryResult: Hashable, Codable, Sendable, StableHashable {
    public let worldPosition: TerrainWorldPosition
    public let sampleCoord: TerrainSampleCoord?
    public let heightMeters: Float
    public let normal: TEVec3f
    public let surface: TerrainQuerySurfaceResult?
    public let slopeRadians: Float
    public let slopeDegrees: Float
    public let slope01: Float
    public let slopeClassification: TerrainSlopeClassification
    public let walkability: TerrainWalkability
    public let isInsideKnownTerrain: Bool
    public let sourceChunkID: WorldChunkID?
    public let sourceMeshHash: UInt64?
    public let stableHash: UInt64

    public init(
        worldPosition: TerrainWorldPosition,
        sampleCoord: TerrainSampleCoord?,
        heightMeters: Float,
        normal: TEVec3f,
        surface: TerrainQuerySurfaceResult?,
        slopeRadians: Float,
        slopeDegrees: Float,
        slope01: Float,
        slopeClassification: TerrainSlopeClassification,
        walkability: TerrainWalkability,
        isInsideKnownTerrain: Bool,
        sourceChunkID: WorldChunkID?,
        sourceMeshHash: UInt64?
    ) {
        self.worldPosition = worldPosition
        self.sampleCoord = sampleCoord
        self.heightMeters = heightMeters
        self.normal = normal
        self.surface = surface
        self.slopeRadians = slopeRadians
        self.slopeDegrees = slopeDegrees
        self.slope01 = slope01
        self.slopeClassification = slopeClassification
        self.walkability = walkability
        self.isInsideKnownTerrain = isInsideKnownTerrain
        self.sourceChunkID = sourceChunkID
        self.sourceMeshHash = sourceMeshHash
        self.stableHash = Self.computeStableHash(
            worldPosition: worldPosition,
            sampleCoord: sampleCoord,
            heightMeters: heightMeters,
            normal: normal,
            surface: surface,
            slopeRadians: slopeRadians,
            slopeDegrees: slopeDegrees,
            slope01: slope01,
            slopeClassification: slopeClassification,
            walkability: walkability,
            isInsideKnownTerrain: isInsideKnownTerrain,
            sourceChunkID: sourceChunkID,
            sourceMeshHash: sourceMeshHash
        )
    }

    public static func outsideKnownTerrain(
        worldX: Float,
        worldZ: Float,
        walkabilityConfig: TerrainWalkabilityConfig = .default
    ) -> TerrainQueryResult {
        let surface: TerrainQuerySurfaceResult? = nil
        let slopeDegrees: Float = 0
        let walkability = TerrainWalkability.evaluate(
            surface: surface,
            slopeDegrees: slopeDegrees,
            isInsideKnownTerrain: false,
            config: walkabilityConfig
        )
        return TerrainQueryResult(
            worldPosition: TerrainWorldPosition(x: worldX.isFinite ? worldX : 0, y: 0, z: worldZ.isFinite ? worldZ : 0),
            sampleCoord: nil,
            heightMeters: 0,
            normal: .up,
            surface: surface,
            slopeRadians: 0,
            slopeDegrees: slopeDegrees,
            slope01: 0,
            slopeClassification: .unknown,
            walkability: walkability,
            isInsideKnownTerrain: false,
            sourceChunkID: nil,
            sourceMeshHash: nil
        )
    }

    private static func computeStableHash(
        worldPosition: TerrainWorldPosition,
        sampleCoord: TerrainSampleCoord?,
        heightMeters: Float,
        normal: TEVec3f,
        surface: TerrainQuerySurfaceResult?,
        slopeRadians: Float,
        slopeDegrees: Float,
        slope01: Float,
        slopeClassification: TerrainSlopeClassification,
        walkability: TerrainWalkability,
        isInsideKnownTerrain: Bool,
        sourceChunkID: WorldChunkID?,
        sourceMeshHash: UInt64?
    ) -> UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9057_0001,
            worldPosition.stableHash,
            sampleCoord?.stableHash ?? 0,
            sampleCoord == nil ? 0 : 1,
            StableHasher.bits(heightMeters),
            normal.stableHash,
            surface?.stableHash ?? 0,
            surface == nil ? 0 : 1,
            StableHasher.bits(slopeRadians),
            StableHasher.bits(slopeDegrees),
            StableHasher.bits(slope01),
            slopeClassification.stableHash,
            walkability.stableHash,
            isInsideKnownTerrain ? 1 : 0,
            sourceChunkID?.stableHash ?? 0,
            sourceChunkID == nil ? 0 : 1,
            sourceMeshHash ?? 0,
            sourceMeshHash == nil ? 0 : 1
        )
    }
}

