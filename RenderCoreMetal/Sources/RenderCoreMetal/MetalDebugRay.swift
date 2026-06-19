import simd

public struct MetalDebugRay: Sendable, Hashable {
    public var origin: SIMD3<Float>
    public var direction: SIMD3<Float>

    public init(origin: SIMD3<Float>, direction: SIMD3<Float>) {
        self.origin = SIMD3<Float>(
            origin.x.isFinite ? origin.x : 0,
            origin.y.isFinite ? origin.y : 0,
            origin.z.isFinite ? origin.z : 0
        )

        let cleanDirection = SIMD3<Float>(
            direction.x.isFinite ? direction.x : 0,
            direction.y.isFinite ? direction.y : 0,
            direction.z.isFinite ? direction.z : 0
        )
        let length = simd_length(cleanDirection)
        self.direction = length > 0.000_001
            ? cleanDirection / length
            : SIMD3<Float>(0, -1, 0)
    }

    public func point(at distance: Float) -> SIMD3<Float> {
        origin + direction * max(distance.isFinite ? distance : 0, 0)
    }
}
