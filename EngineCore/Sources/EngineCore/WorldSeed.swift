public struct WorldSeed: Hashable, Codable, Sendable, StableHashable {
    public static let defaultGeneratorVersion: UInt32 = 1

    public let stableSeed: StableSeed
    public let generatorVersion: UInt32

    public init(_ rawValue: UInt64, generatorVersion: UInt32 = Self.defaultGeneratorVersion) {
        self.stableSeed = StableSeed(rawValue)
        self.generatorVersion = generatorVersion
    }

    public init(stableSeed: StableSeed, generatorVersion: UInt32 = Self.defaultGeneratorVersion) {
        self.stableSeed = stableSeed
        self.generatorVersion = generatorVersion
    }

    public var rawValue: UInt64 {
        stableSeed.rawValue
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_575E_ED01,
            stableSeed.stableHash,
            StableHasher.bits(generatorVersion)
        )
    }
}

