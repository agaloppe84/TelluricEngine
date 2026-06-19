import simd

public struct MetalDebugWorldPoint: Sendable, Hashable {
    public var position: SIMD3<Float>

    public init(position: SIMD3<Float>) {
        self.position = SIMD3<Float>(
            position.x.isFinite ? position.x : 0,
            position.y.isFinite ? position.y : 0,
            position.z.isFinite ? position.z : 0
        )
    }

    public init(x: Float, y: Float, z: Float) {
        self.init(position: SIMD3<Float>(x, y, z))
    }
}
