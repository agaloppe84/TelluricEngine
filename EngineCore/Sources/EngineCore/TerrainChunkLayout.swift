public struct TerrainChunkLayout: Hashable, Codable, Sendable, StableHashable {
    public static let phase1Default = TerrainChunkLayout(samplesPerAxis: 9)

    public let samplesPerAxis: Int

    public init(samplesPerAxis: Int) {
        precondition(samplesPerAxis >= 2, "A terrain chunk needs at least two samples per axis.")
        self.samplesPerAxis = samplesPerAxis
    }

    public var chunkSampleSpan: Int {
        samplesPerAxis - 1
    }

    public var sampleCount: Int {
        samplesPerAxis * samplesPerAxis
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_7A90_0001,
            UInt64(samplesPerAxis)
        )
    }

    public func worldSampleCoord(
        chunkCoord: ChunkCoord,
        localX: Int,
        localZ: Int
    ) -> TerrainSampleCoord {
        precondition(localX >= 0 && localX < samplesPerAxis, "localX is outside the terrain chunk layout.")
        precondition(localZ >= 0 && localZ < samplesPerAxis, "localZ is outside the terrain chunk layout.")

        let span = Int64(chunkSampleSpan)
        return TerrainSampleCoord(
            x: Int64(chunkCoord.x) * span + Int64(localX),
            z: Int64(chunkCoord.z) * span + Int64(localZ)
        )
    }
}

