public enum TerrainChunkSampler {
    public static func makePayload(
        worldSeed: WorldSeed,
        chunkCoord: ChunkCoord,
        generatorVersion: TerrainGeneratorVersion = .phase1,
        layout: TerrainChunkLayout = .phase1Default
    ) -> ChunkTerrainSamplePayload {
        var samples: [TerrainSample] = []
        samples.reserveCapacity(layout.sampleCount)

        for localZ in 0..<layout.samplesPerAxis {
            for localX in 0..<layout.samplesPerAxis {
                let coord = layout.worldSampleCoord(
                    chunkCoord: chunkCoord,
                    localX: localX,
                    localZ: localZ
                )
                samples.append(
                    TerrainScalarField.sample(
                        worldSeed: worldSeed,
                        coord: coord,
                        generatorVersion: generatorVersion
                    )
                )
            }
        }

        return ChunkTerrainSamplePayload(
            worldSeed: worldSeed,
            chunkCoord: chunkCoord,
            generatorVersion: generatorVersion,
            layout: layout,
            samples: samples
        )
    }
}

