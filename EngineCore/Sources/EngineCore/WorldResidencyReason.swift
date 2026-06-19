public enum WorldResidencyReason: UInt8, Hashable, Codable, Sendable, CaseIterable, StableHashable {
    case activeRadius = 0
    case residentRadius = 1
    case meshRadius = 2
    case sampleRadius = 3
    case evictionRadius = 4
    case outsideEvictionRadius = 5

    public var priorityRank: Int {
        Int(rawValue)
    }

    public var stableHash: UInt64 {
        StableHasher.hash(seed: 0x7E11_571C_7EA5_0001, UInt64(rawValue))
    }
}

