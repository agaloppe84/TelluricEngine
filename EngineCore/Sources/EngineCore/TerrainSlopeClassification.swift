public enum TerrainSlopeClassification: UInt8, Codable, CaseIterable, Sendable, StableHashable {
    case unknown = 0
    case flat = 1
    case gentle = 2
    case moderate = 3
    case steep = 4
    case extreme = 5

    public static func classify(slopeDegrees: Float, isInsideKnownTerrain: Bool = true) -> TerrainSlopeClassification {
        guard isInsideKnownTerrain, slopeDegrees.isFinite else {
            return .unknown
        }
        if slopeDegrees < 5 {
            return .flat
        }
        if slopeDegrees < 15 {
            return .gentle
        }
        if slopeDegrees < 35 {
            return .moderate
        }
        if slopeDegrees < 55 {
            return .steep
        }
        return .extreme
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_5109_0001,
            UInt64(rawValue)
        )
    }
}

