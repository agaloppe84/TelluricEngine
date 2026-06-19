public enum WorldResidencyConfigError: Error, Equatable, Sendable {
    case negativeRadius(name: String, value: Int)
    case inconsistentRadii
    case invalidMaxChunksPerPlan(Int)
    case invalidStreamingCellSizeChunks(Int)
}

public struct WorldResidencyConfig: Hashable, Codable, Sendable, StableHashable {
    public let activeRadiusChunks: Int
    public let residentRadiusChunks: Int
    public let meshRadiusChunks: Int
    public let sampleRadiusChunks: Int
    public let evictionRadiusChunks: Int
    public let maxChunksPerPlan: Int?
    public let streamingCellSizeChunks: Int

    public init(
        activeRadiusChunks: Int,
        residentRadiusChunks: Int,
        meshRadiusChunks: Int,
        sampleRadiusChunks: Int,
        evictionRadiusChunks: Int,
        maxChunksPerPlan: Int? = nil,
        streamingCellSizeChunks: Int = 2
    ) {
        self.activeRadiusChunks = activeRadiusChunks
        self.residentRadiusChunks = residentRadiusChunks
        self.meshRadiusChunks = meshRadiusChunks
        self.sampleRadiusChunks = sampleRadiusChunks
        self.evictionRadiusChunks = evictionRadiusChunks
        self.maxChunksPerPlan = maxChunksPerPlan
        self.streamingCellSizeChunks = streamingCellSizeChunks
    }

    public func validate() throws {
        let radii = [
            ("activeRadiusChunks", activeRadiusChunks),
            ("residentRadiusChunks", residentRadiusChunks),
            ("meshRadiusChunks", meshRadiusChunks),
            ("sampleRadiusChunks", sampleRadiusChunks),
            ("evictionRadiusChunks", evictionRadiusChunks)
        ]

        for radius in radii where radius.1 < 0 {
            throw WorldResidencyConfigError.negativeRadius(name: radius.0, value: radius.1)
        }

        guard activeRadiusChunks <= residentRadiusChunks,
              residentRadiusChunks <= meshRadiusChunks,
              meshRadiusChunks <= sampleRadiusChunks,
              sampleRadiusChunks <= evictionRadiusChunks
        else {
            throw WorldResidencyConfigError.inconsistentRadii
        }

        if let maxChunksPerPlan, maxChunksPerPlan <= 0 {
            throw WorldResidencyConfigError.invalidMaxChunksPerPlan(maxChunksPerPlan)
        }

        if streamingCellSizeChunks <= 0 {
            throw WorldResidencyConfigError.invalidStreamingCellSizeChunks(streamingCellSizeChunks)
        }
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_C0F1_9001,
            StableHasher.bits(activeRadiusChunks),
            StableHasher.bits(residentRadiusChunks),
            StableHasher.bits(meshRadiusChunks),
            StableHasher.bits(sampleRadiusChunks),
            StableHasher.bits(evictionRadiusChunks),
            StableHasher.bits(maxChunksPerPlan ?? 0),
            maxChunksPerPlan == nil ? 0 : 1,
            StableHasher.bits(streamingCellSizeChunks)
        )
    }
}

