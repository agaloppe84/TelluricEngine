public enum TerrainWalkabilityReason: UInt8, Codable, CaseIterable, Sendable, StableHashable {
    case walkable = 0
    case tooSteep = 1
    case water = 2
    case mud = 3
    case unknown = 4
    case outsideKnownTerrain = 5

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9A1A_0001,
            UInt64(rawValue)
        )
    }
}

public struct TerrainWalkabilityConfig: Hashable, Codable, Sendable, StableHashable {
    public static let `default` = TerrainWalkabilityConfig()

    public let maxWalkableSlopeDegrees: Float
    public let mudIsWalkable: Bool
    public let shallowWaterIsWalkable: Bool

    public init(
        maxWalkableSlopeDegrees: Float = 35,
        mudIsWalkable: Bool = true,
        shallowWaterIsWalkable: Bool = false
    ) {
        self.maxWalkableSlopeDegrees = maxWalkableSlopeDegrees.isFinite
            ? max(0, maxWalkableSlopeDegrees)
            : 35
        self.mudIsWalkable = mudIsWalkable
        self.shallowWaterIsWalkable = shallowWaterIsWalkable
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9A1A_0002,
            StableHasher.bits(maxWalkableSlopeDegrees),
            mudIsWalkable ? 1 : 0,
            shallowWaterIsWalkable ? 1 : 0
        )
    }
}

public struct TerrainWalkability: Hashable, Codable, Sendable, StableHashable {
    public let isWalkable: Bool
    public let reason: TerrainWalkabilityReason

    public init(isWalkable: Bool, reason: TerrainWalkabilityReason) {
        self.isWalkable = isWalkable
        self.reason = reason
    }

    public static let unknown = TerrainWalkability(isWalkable: false, reason: .unknown)
    public static let outsideKnownTerrain = TerrainWalkability(isWalkable: false, reason: .outsideKnownTerrain)

    public static func evaluate(
        surface: TerrainQuerySurfaceResult?,
        slopeDegrees: Float,
        isInsideKnownTerrain: Bool,
        config: TerrainWalkabilityConfig = .default
    ) -> TerrainWalkability {
        guard isInsideKnownTerrain else {
            return .outsideKnownTerrain
        }
        guard slopeDegrees.isFinite, let surface else {
            return .unknown
        }
        if slopeDegrees > config.maxWalkableSlopeDegrees {
            return TerrainWalkability(isWalkable: false, reason: .tooSteep)
        }
        switch surface.material {
        case .shallowWater:
            return TerrainWalkability(
                isWalkable: config.shallowWaterIsWalkable,
                reason: config.shallowWaterIsWalkable ? .walkable : .water
            )
        case .mud:
            return TerrainWalkability(
                isWalkable: config.mudIsWalkable,
                reason: config.mudIsWalkable ? .mud : .mud
            )
        case .rock, .soil, .grass, .sand, .gravel, .snow:
            return TerrainWalkability(isWalkable: true, reason: .walkable)
        }
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_9A1A_0003,
            isWalkable ? 1 : 0,
            reason.stableHash
        )
    }
}

