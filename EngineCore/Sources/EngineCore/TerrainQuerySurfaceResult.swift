public struct TerrainQuerySurfaceResult: Hashable, Codable, Sendable, StableHashable {
    public let material: TerrainSurfaceMaterial
    public let physicalTag: PhysicalSurfaceTag
    public let audioTag: AudioSurfaceTag
    public let slope01: Float
    public let moisture01: Float
    public let heightMeters: Float

    public init(sample: TerrainSurfaceSample) {
        self.init(
            material: sample.material,
            physicalTag: sample.physicalTag,
            audioTag: sample.audioTag,
            slope01: sample.slope01,
            moisture01: sample.moisture01,
            heightMeters: sample.heightMeters
        )
    }

    public init(
        material: TerrainSurfaceMaterial,
        physicalTag: PhysicalSurfaceTag,
        audioTag: AudioSurfaceTag,
        slope01: Float,
        moisture01: Float,
        heightMeters: Float
    ) {
        self.material = material
        self.physicalTag = physicalTag
        self.audioTag = audioTag
        self.slope01 = slope01
        self.moisture01 = moisture01
        self.heightMeters = heightMeters
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9055_0001,
            material.stableHash,
            physicalTag.stableHash,
            audioTag.stableHash,
            StableHasher.bits(slope01),
            StableHasher.bits(moisture01),
            StableHasher.bits(heightMeters)
        )
    }
}

