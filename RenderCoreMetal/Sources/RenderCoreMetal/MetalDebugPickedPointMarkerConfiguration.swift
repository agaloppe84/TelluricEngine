import simd

public struct MetalDebugPickedPointMarkerConfiguration: Sendable, Hashable {
    public var isEnabled: Bool
    public var size: Float
    public var color: SIMD4<Float>

    public init(
        isEnabled: Bool = true,
        size: Float = 2.5,
        color: SIMD4<Float> = SIMD4<Float>(1.0, 0.38, 0.18, 1.0)
    ) {
        self.isEnabled = isEnabled
        self.size = size.isFinite ? max(size, 0.1) : 2.5
        self.color = color
    }

    public var stableDebugID: UInt64 {
        var state: UInt64 = isEnabled ? 1 : 0
        state = (state << 32) ^ UInt64(size.bitPattern)
        for value in [color.x, color.y, color.z, color.w] {
            state = (state &* 0xC2B2_AE3D_27D4_EB4F) ^ UInt64(value.bitPattern)
        }
        return state
    }
}
