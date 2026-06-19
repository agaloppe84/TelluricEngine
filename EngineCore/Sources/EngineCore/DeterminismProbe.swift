public struct DeterminismProbeResult: Hashable, Codable, Sendable {
    public let worldSeed: WorldSeed
    public let chunkCoord: ChunkCoord
    public let probeVersion: UInt32
    public let sampleValue: UInt64
    public let normalizedUnitValue: Double
    public let outputHash: UInt64

    public init(
        worldSeed: WorldSeed,
        chunkCoord: ChunkCoord,
        probeVersion: UInt32,
        sampleValue: UInt64,
        normalizedUnitValue: Double,
        outputHash: UInt64
    ) {
        self.worldSeed = worldSeed
        self.chunkCoord = chunkCoord
        self.probeVersion = probeVersion
        self.sampleValue = sampleValue
        self.normalizedUnitValue = normalizedUnitValue
        self.outputHash = outputHash
    }
}

public enum DeterminismProbe {
    public static let probeVersion: UInt32 = 1

    public static func sample(worldSeed: WorldSeed, chunkCoord: ChunkCoord) -> DeterminismProbeResult {
        let base = StableHasher.hash(
            seed: 0x7E11_571C_0B0E_0001,
            worldSeed.stableHash,
            chunkCoord.stableHash,
            StableHasher.bits(probeVersion)
        )
        let sampleValue = StableHasher.mix(base)
        let outputHash = StableHasher.hash(
            seed: 0x7E11_571C_0A7E_0001,
            worldSeed.rawValue,
            StableHasher.bits(worldSeed.generatorVersion),
            chunkCoord.stableHash,
            StableHasher.bits(probeVersion),
            sampleValue
        )

        return DeterminismProbeResult(
            worldSeed: worldSeed,
            chunkCoord: chunkCoord,
            probeVersion: probeVersion,
            sampleValue: sampleValue,
            normalizedUnitValue: Double(sampleValue >> 11) / 9_007_199_254_740_992.0,
            outputHash: outputHash
        )
    }
}
