public enum AudioSurfaceTag: UInt8, Hashable, Codable, Sendable, CaseIterable, StableHashable {
    case stone = 0
    case dirt = 1
    case grass = 2
    case sand = 3
    case gravel = 4
    case mud = 5
    case snow = 6
    case water = 7

    public var stableHash: UInt64 {
        StableHasher.hash(seed: 0x7E11_571C_5A72_0001, UInt64(rawValue))
    }
}

