public enum TerrainQueryMode: UInt8, Codable, CaseIterable, Sendable, StableHashable {
    case nearestVertex = 0
    case bilinearHeightfield = 1

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_90DE_0001,
            UInt64(rawValue)
        )
    }
}

