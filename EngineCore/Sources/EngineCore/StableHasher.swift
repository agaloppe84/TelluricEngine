public enum StableHasher {
    public static let defaultSeed: UInt64 = 0xCBF2_9CE4_8422_2325

    private static let increment: UInt64 = 0x9E37_79B9_7F4A_7C15
    private static let mixA: UInt64 = 0xBF58_476D_1CE4_E5B9
    private static let mixB: UInt64 = 0x94D0_49BB_1331_11EB

    public static func mix(_ value: UInt64) -> UInt64 {
        var z = value &+ increment
        z = (z ^ (z >> 30)) &* mixA
        z = (z ^ (z >> 27)) &* mixB
        return z ^ (z >> 31)
    }

    public static func combine(_ state: UInt64, _ value: UInt64) -> UInt64 {
        mix(state ^ (value &+ increment))
    }

    public static func hash(seed: UInt64 = defaultSeed, _ values: UInt64...) -> UInt64 {
        var state = mix(seed)
        for value in values {
            state = combine(state, value)
        }
        return mix(state ^ UInt64(values.count))
    }

    public static func bits(_ value: Int32) -> UInt64 {
        UInt64(UInt32(bitPattern: value))
    }

    public static func bits(_ value: Int64) -> UInt64 {
        UInt64(bitPattern: value)
    }

    public static func bits(_ value: UInt32) -> UInt64 {
        UInt64(value)
    }
}
