public enum TerrainScalarField {
    public static let heightRangeMeters: Double = 256.0

    public static func sample(
        worldSeed: WorldSeed,
        coord: TerrainSampleCoord,
        generatorVersion: TerrainGeneratorVersion = .phase1
    ) -> TerrainSample {
        let valueHash = StableHasher.hash(
            seed: 0x7E11_571C_51CE_0001,
            worldSeed.stableHash,
            generatorVersion.stableHash,
            coord.stableHash
        )
        let scalarValue = Double(valueHash >> 11) / 9_007_199_254_740_992.0
        let heightMeters = scalarValue * heightRangeMeters - (heightRangeMeters * 0.5)

        return TerrainSample(
            coord: coord,
            scalarValue: scalarValue,
            heightMeters: heightMeters,
            valueHash: valueHash
        )
    }
}

