public enum TerrainQueryError: Error, Hashable, Codable, Sendable, StableHashable {
    case noMeshPayloads
    case nonFiniteCoordinate

    public var stableHash: UInt64 {
        switch self {
        case .noMeshPayloads:
            return StableHasher.hash(seed: 0x7E11_571C_9E99_0001, 1)
        case .nonFiniteCoordinate:
            return StableHasher.hash(seed: 0x7E11_571C_9E99_0001, 2)
        }
    }
}

