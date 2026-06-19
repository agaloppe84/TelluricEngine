public struct MetalDebugNormalsConfiguration: Sendable, Hashable {
    public var isEnabled: Bool
    public var stride: Int
    public var length: Float

    public init(
        isEnabled: Bool = false,
        stride: Int = 8,
        length: Float = 2.0
    ) {
        self.isEnabled = isEnabled
        self.stride = max(1, stride)
        self.length = max(0.01, length)
    }

    public var stableDebugID: UInt64 {
        UInt64(isEnabled ? 1 : 0)
            ^ (UInt64(stride) << 8)
            ^ (UInt64(length.bitPattern) << 24)
    }
}
