import simd

public struct MetalDebugGridConfiguration: Sendable, Hashable {
    public var isEnabled: Bool
    public var heightOffset: Float
    public var color: SIMD4<Float>

    public init(
        isEnabled: Bool = false,
        heightOffset: Float = 0.35,
        color: SIMD4<Float> = SIMD4<Float>(0.25, 0.80, 0.95, 0.82)
    ) {
        self.isEnabled = isEnabled
        self.heightOffset = heightOffset.isFinite ? max(heightOffset, 0) : 0.35
        self.color = color
    }

    public var stableDebugID: UInt64 {
        var state: UInt64 = isEnabled ? 1 : 0
        state = (state << 32) ^ UInt64(heightOffset.bitPattern)
        for value in [color.x, color.y, color.z, color.w] {
            state = (state &* 0x9E37_79B9_7F4A_7C15) ^ UInt64(value.bitPattern)
        }
        return state
    }
}
