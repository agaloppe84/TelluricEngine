public struct ChunkTerrainSamplePayload: Hashable, Codable, Sendable, StableHashable {
    public let worldSeed: WorldSeed
    public let chunkCoord: ChunkCoord
    public let generatorVersion: TerrainGeneratorVersion
    public let layout: TerrainChunkLayout
    public let samples: [TerrainSample]
    public let payloadHash: UInt64

    public init(
        worldSeed: WorldSeed,
        chunkCoord: ChunkCoord,
        generatorVersion: TerrainGeneratorVersion,
        layout: TerrainChunkLayout,
        samples: [TerrainSample]
    ) {
        precondition(samples.count == layout.sampleCount, "Terrain payload sample count does not match its layout.")

        self.worldSeed = worldSeed
        self.chunkCoord = chunkCoord
        self.generatorVersion = generatorVersion
        self.layout = layout
        self.samples = samples
        self.payloadHash = Self.computePayloadHash(
            worldSeed: worldSeed,
            chunkCoord: chunkCoord,
            generatorVersion: generatorVersion,
            layout: layout,
            samples: samples
        )
    }

    public var stableHash: UInt64 {
        payloadHash
    }

    public func sample(localX: Int, localZ: Int) -> TerrainSample {
        precondition(localX >= 0 && localX < layout.samplesPerAxis, "localX is outside the terrain payload layout.")
        precondition(localZ >= 0 && localZ < layout.samplesPerAxis, "localZ is outside the terrain payload layout.")

        return samples[localZ * layout.samplesPerAxis + localX]
    }

    private static func computePayloadHash(
        worldSeed: WorldSeed,
        chunkCoord: ChunkCoord,
        generatorVersion: TerrainGeneratorVersion,
        layout: TerrainChunkLayout,
        samples: [TerrainSample]
    ) -> UInt64 {
        var state = StableHasher.hash(
            seed: 0x7E11_571C_7A10_AD01,
            worldSeed.stableHash,
            chunkCoord.stableHash,
            generatorVersion.stableHash,
            layout.stableHash
        )

        for sample in samples {
            state = StableHasher.combine(state, sample.stableHash)
        }

        return StableHasher.mix(state ^ UInt64(samples.count))
    }
}

