public struct TerrainSurfacePayload: Hashable, Codable, Sendable, StableHashable {
    public let generatorVersion: TerrainGeneratorVersion
    public let chunkCoord: ChunkCoord
    public let layout: TerrainChunkLayout
    public let samples: [TerrainSurfaceSample]
    public let stableHash: UInt64

    public init(
        generatorVersion: TerrainGeneratorVersion,
        chunkCoord: ChunkCoord,
        layout: TerrainChunkLayout,
        samples: [TerrainSurfaceSample]
    ) {
        precondition(samples.count == layout.sampleCount, "Surface sample count does not match its layout.")

        self.generatorVersion = generatorVersion
        self.chunkCoord = chunkCoord
        self.layout = layout
        self.samples = samples
        self.stableHash = Self.computeStableHash(
            generatorVersion: generatorVersion,
            chunkCoord: chunkCoord,
            layout: layout,
            samples: samples
        )
    }

    public func sample(localX: Int, localZ: Int) -> TerrainSurfaceSample {
        precondition(localX >= 0 && localX < layout.samplesPerAxis, "localX is outside the surface payload layout.")
        precondition(localZ >= 0 && localZ < layout.samplesPerAxis, "localZ is outside the surface payload layout.")

        return samples[localZ * layout.samplesPerAxis + localX]
    }

    private static func computeStableHash(
        generatorVersion: TerrainGeneratorVersion,
        chunkCoord: ChunkCoord,
        layout: TerrainChunkLayout,
        samples: [TerrainSurfaceSample]
    ) -> UInt64 {
        var state = StableHasher.hash(
            seed: 0x7E11_571C_5A7E_0001,
            generatorVersion.stableHash,
            chunkCoord.stableHash,
            layout.stableHash
        )

        for sample in samples {
            state = StableHasher.combine(state, sample.stableHash)
        }

        return StableHasher.combine(state, UInt64(samples.count))
    }
}

