public enum TerrainGenerationProfile: UInt8, Codable, CaseIterable, Sendable, StableHashable {
    case defaultProcedural = 0
    case debugPlayable = 1

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_6E90_0001,
            UInt64(rawValue)
        )
    }
}
