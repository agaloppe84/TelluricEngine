public enum CachedChunkPayloadState: UInt8, Hashable, Codable, Sendable, StableHashable {
    case empty = 0
    case sampled = 1
    case meshed = 2
    case resident = 3
    case active = 4
    case evictionCandidate = 5

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_CA7E_0001,
            UInt64(rawValue)
        )
    }
}
