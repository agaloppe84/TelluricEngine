public enum TerrainSurfaceResolver {
    public static func resolve(sample: TerrainSample, normal: TEVec3f) -> TerrainSurfaceSample {
        let height = Float(sample.heightMeters)
        let slope = clamp01(1.0 - normal.y)
        let moisture = moisture01(for: sample)
        let material = materialFor(heightMeters: height, slope01: slope, moisture01: moisture)
        let tags = tags(for: material)

        return TerrainSurfaceSample(
            material: material,
            physicalTag: tags.physical,
            audioTag: tags.audio,
            slope01: slope,
            moisture01: moisture,
            heightMeters: height
        )
    }

    private static func moisture01(for sample: TerrainSample) -> Float {
        let moistureHash = StableHasher.hash(
            seed: 0x7E11_571C_4015_0001,
            sample.coord.stableHash,
            sample.valueHash
        )
        return Float(Double(moistureHash >> 11) / 9_007_199_254_740_992.0)
    }

    private static func materialFor(
        heightMeters: Float,
        slope01: Float,
        moisture01: Float
    ) -> TerrainSurfaceMaterial {
        if heightMeters < -96 && moisture01 > 0.58 {
            return .shallowWater
        }
        if moisture01 > 0.82 && slope01 < 0.38 {
            return .mud
        }
        if slope01 > 0.68 && heightMeters > 40 {
            return .rock
        }
        if slope01 > 0.48 {
            return .gravel
        }
        if heightMeters > 84 && moisture01 < 0.72 {
            return .snow
        }
        if heightMeters < -48 && moisture01 < 0.45 {
            return .sand
        }
        if slope01 < 0.28 && heightMeters > -64 && heightMeters < 72 {
            return .grass
        }
        return .soil
    }

    private static func tags(
        for material: TerrainSurfaceMaterial
    ) -> (physical: PhysicalSurfaceTag, audio: AudioSurfaceTag) {
        switch material {
        case .rock:
            return (.hardRock, .stone)
        case .soil:
            return (.looseSoil, .dirt)
        case .grass:
            return (.softGrass, .grass)
        case .sand:
            return (.looseSand, .sand)
        case .gravel:
            return (.looseGravel, .gravel)
        case .mud:
            return (.stickyMud, .mud)
        case .snow:
            return (.compactSnow, .snow)
        case .shallowWater:
            return (.shallowWater, .water)
        }
    }

    private static func clamp01(_ value: Float) -> Float {
        Swift.max(0, Swift.min(1, value))
    }
}
