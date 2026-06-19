import simd

public struct MetalDebugCameraState: Sendable, Hashable {
    public var target: SIMD3<Float>
    public var distance: Float
    public var yawRadians: Float
    public var pitchRadians: Float
    public var zoomScale: Float
    public var orthographicScale: Float
    public var nearZ: Float
    public var farZ: Float

    public init(
        target: SIMD3<Float> = .zero,
        distance: Float = 180,
        yawRadians: Float = 0.70,
        pitchRadians: Float = 0.82,
        zoomScale: Float = 1,
        orthographicScale: Float = 160,
        nearZ: Float = 0.1,
        farZ: Float = 2_000
    ) {
        self.target = target
        self.distance = distance
        self.yawRadians = yawRadians
        self.pitchRadians = pitchRadians
        self.zoomScale = zoomScale
        self.orthographicScale = orthographicScale
        self.nearZ = nearZ
        self.farZ = farZ
    }

    public var stableDebugID: UInt64 {
        var state: UInt64 = 0x7E11_571C_CA4E_7001
        for value in [
            target.x,
            target.y,
            target.z,
            distance,
            yawRadians,
            pitchRadians,
            zoomScale,
            orthographicScale,
            nearZ,
            farZ
        ] {
            state = (state &* 0x9E37_79B9_7F4A_7C15) ^ UInt64(value.bitPattern)
        }
        return state
    }
}
