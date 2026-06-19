public struct StableSeed: Hashable, Codable, Sendable, ExpressibleByIntegerLiteral, StableHashable {
    public let rawValue: UInt64

    public init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public init(integerLiteral value: UInt64) {
        self.rawValue = value
    }

    public var stableHash: UInt64 {
        StableHasher.hash(seed: 0x7E11_571C_5EED_0001, rawValue)
    }
}

