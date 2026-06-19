public struct TerrainMeshVertex: Hashable, Codable, Sendable, StableHashable {
    public let position: TEVec3f
    public let normal: TEVec3f
    public let uv: TEVec2f
    public let sampleCoord: TerrainSampleCoord
    public let heightMeters: Float
    public let surface: TerrainSurfaceSample

    public init(
        position: TEVec3f,
        normal: TEVec3f,
        uv: TEVec2f,
        sampleCoord: TerrainSampleCoord,
        heightMeters: Float,
        surface: TerrainSurfaceSample
    ) {
        self.position = position
        self.normal = normal
        self.uv = uv
        self.sampleCoord = sampleCoord
        self.heightMeters = heightMeters
        self.surface = surface
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_7E22_0001,
            position.stableHash,
            normal.stableHash,
            uv.stableHash,
            sampleCoord.stableHash,
            StableHasher.bits(heightMeters),
            surface.stableHash
        )
    }
}

