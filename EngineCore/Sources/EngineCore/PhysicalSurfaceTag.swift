public enum PhysicalSurfaceTag: UInt8, Hashable, Codable, Sendable, CaseIterable, StableHashable {
    case hardRock = 0
    case looseSoil = 1
    case softGrass = 2
    case looseSand = 3
    case looseGravel = 4
    case stickyMud = 5
    case compactSnow = 6
    case shallowWater = 7

    public var stableHash: UInt64 {
        StableHasher.hash(seed: 0x7E11_571C_5A71_0001, UInt64(rawValue))
    }
}

