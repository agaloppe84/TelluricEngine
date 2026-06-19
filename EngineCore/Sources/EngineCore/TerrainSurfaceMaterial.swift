public enum TerrainSurfaceMaterial: UInt8, Hashable, Codable, Sendable, CaseIterable, StableHashable {
    case rock = 0
    case soil = 1
    case grass = 2
    case sand = 3
    case gravel = 4
    case mud = 5
    case snow = 6
    case shallowWater = 7

    public var stableHash: UInt64 {
        StableHasher.hash(seed: 0x7E11_571C_5A70_0001, UInt64(rawValue))
    }
}

