public enum TerrainScalarField {
    public static let heightRangeMeters: Double = 256.0
    public static let debugPlayableHeightRangeMeters: Double = 10.0

    public static func sample(
        worldSeed: WorldSeed,
        coord: TerrainSampleCoord,
        generatorVersion: TerrainGeneratorVersion = .phase1,
        profile: TerrainGenerationProfile = .defaultProcedural
    ) -> TerrainSample {
        switch profile {
        case .defaultProcedural:
            return defaultProceduralSample(
                worldSeed: worldSeed,
                coord: coord,
                generatorVersion: generatorVersion
            )
        case .debugPlayable:
            return debugPlayableSample(
                worldSeed: worldSeed,
                coord: coord,
                generatorVersion: generatorVersion
            )
        }
    }

    private static func defaultProceduralSample(
        worldSeed: WorldSeed,
        coord: TerrainSampleCoord,
        generatorVersion: TerrainGeneratorVersion
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

    private static func debugPlayableSample(
        worldSeed: WorldSeed,
        coord: TerrainSampleCoord,
        generatorVersion: TerrainGeneratorVersion
    ) -> TerrainSample {
        let broad = coherentNoise01(
            worldSeed: worldSeed,
            generatorVersion: generatorVersion,
            coord: coord,
            cellSize: 32,
            salt: 0x7E11_571C_D06D_0001
        )
        let detail = coherentNoise01(
            worldSeed: worldSeed,
            generatorVersion: generatorVersion,
            coord: coord,
            cellSize: 16,
            salt: 0x7E11_571C_D06D_0002
        )
        let scalarValue = clamp01(0.5 + (broad - 0.5) * 0.82 + (detail - 0.5) * 0.18)
        let heightMeters = (scalarValue - 0.5) * debugPlayableHeightRangeMeters
        let valueHash = StableHasher.hash(
            seed: 0x7E11_571C_D06D_0003,
            worldSeed.stableHash,
            generatorVersion.stableHash,
            TerrainGenerationProfile.debugPlayable.stableHash,
            coord.stableHash,
            StableHasher.bits(Float(scalarValue)),
            StableHasher.bits(Float(heightMeters))
        )

        return TerrainSample(
            coord: coord,
            scalarValue: scalarValue,
            heightMeters: heightMeters,
            valueHash: valueHash
        )
    }

    private static func coherentNoise01(
        worldSeed: WorldSeed,
        generatorVersion: TerrainGeneratorVersion,
        coord: TerrainSampleCoord,
        cellSize: Int64,
        salt: UInt64
    ) -> Double {
        let cellX = floorDiv(coord.x, cellSize)
        let cellZ = floorDiv(coord.z, cellSize)
        let localX = Double(coord.x - cellX * cellSize) / Double(cellSize)
        let localZ = Double(coord.z - cellZ * cellSize) / Double(cellSize)
        let tx = smoothstep(localX)
        let tz = smoothstep(localZ)

        let v00 = gridValue01(worldSeed: worldSeed, generatorVersion: generatorVersion, cellX: cellX, cellZ: cellZ, salt: salt)
        let v10 = gridValue01(worldSeed: worldSeed, generatorVersion: generatorVersion, cellX: cellX + 1, cellZ: cellZ, salt: salt)
        let v01 = gridValue01(worldSeed: worldSeed, generatorVersion: generatorVersion, cellX: cellX, cellZ: cellZ + 1, salt: salt)
        let v11 = gridValue01(worldSeed: worldSeed, generatorVersion: generatorVersion, cellX: cellX + 1, cellZ: cellZ + 1, salt: salt)

        let x0 = lerp(v00, v10, tx)
        let x1 = lerp(v01, v11, tx)
        return lerp(x0, x1, tz)
    }

    private static func gridValue01(
        worldSeed: WorldSeed,
        generatorVersion: TerrainGeneratorVersion,
        cellX: Int64,
        cellZ: Int64,
        salt: UInt64
    ) -> Double {
        let hash = StableHasher.hash(
            seed: salt,
            worldSeed.stableHash,
            generatorVersion.stableHash,
            TerrainGenerationProfile.debugPlayable.stableHash,
            StableHasher.bits(cellX),
            StableHasher.bits(cellZ)
        )
        return Double(hash >> 11) / 9_007_199_254_740_992.0
    }

    private static func floorDiv(_ value: Int64, _ divisor: Int64) -> Int64 {
        precondition(divisor > 0, "Terrain noise divisor must be positive.")
        var quotient = value / divisor
        let remainder = value % divisor
        if remainder < 0 {
            quotient -= 1
        }
        return quotient
    }

    private static func smoothstep(_ value: Double) -> Double {
        let t = clamp01(value)
        return t * t * (3 - 2 * t)
    }

    private static func lerp(_ lhs: Double, _ rhs: Double, _ t: Double) -> Double {
        lhs + (rhs - lhs) * t
    }

    private static func clamp01(_ value: Double) -> Double {
        Swift.max(0, Swift.min(1, value))
    }
}
