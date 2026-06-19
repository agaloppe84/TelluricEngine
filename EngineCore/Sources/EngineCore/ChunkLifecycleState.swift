public enum ChunkLifecycleState: UInt8, Hashable, Codable, Sendable, CaseIterable, StableHashable {
    case unloaded = 0
    case sampleRequested = 1
    case sampled = 2
    case meshRequested = 3
    case meshed = 4
    case resident = 5
    case active = 6
    case evictionCandidate = 7

    public var priorityRank: Int {
        switch self {
        case .active:
            return 0
        case .resident:
            return 1
        case .meshed:
            return 2
        case .meshRequested:
            return 3
        case .sampled:
            return 4
        case .sampleRequested:
            return 5
        case .evictionCandidate:
            return 6
        case .unloaded:
            return 7
        }
    }

    public var stableHash: UInt64 {
        StableHasher.hash(seed: 0x7E11_571C_57A7_3001, UInt64(rawValue))
    }
}

