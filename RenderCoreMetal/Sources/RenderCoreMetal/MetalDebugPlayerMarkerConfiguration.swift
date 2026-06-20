import simd

public struct MetalDebugPlayerMarkerConfiguration: Sendable, Hashable {
    public var isEnabled: Bool
    public var radius: Float
    public var height: Float
    public var color: SIMD4<Float>

    public init(
        isEnabled: Bool = true,
        radius: Float = 2.6,
        height: Float = 9.0,
        color: SIMD4<Float> = SIMD4<Float>(1.0, 0.92, 0.12, 1.0)
    ) {
        self.isEnabled = isEnabled
        self.radius = radius.isFinite ? max(radius, 0.2) : 2.6
        self.height = height.isFinite ? max(height, 0.5) : 9.0
        self.color = color
    }

    public var stableDebugID: UInt64 {
        var state: UInt64 = isEnabled ? 1 : 0
        state = (state &* 0x9E37_79B9_7F4A_7C15) ^ UInt64(radius.bitPattern)
        state = (state &* 0x9E37_79B9_7F4A_7C15) ^ UInt64(height.bitPattern)
        for value in [color.x, color.y, color.z, color.w] {
            state = (state &* 0xC2B2_AE3D_27D4_EB4F) ^ UInt64(value.bitPattern)
        }
        return state
    }
}
