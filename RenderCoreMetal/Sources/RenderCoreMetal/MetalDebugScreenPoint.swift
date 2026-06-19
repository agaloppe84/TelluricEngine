import simd

public struct MetalDebugScreenPoint: Sendable, Hashable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x.isFinite ? x : 0
        self.y = y.isFinite ? y : 0
    }

    public init(_ value: SIMD2<Float>) {
        self.init(x: value.x, y: value.y)
    }

    public var simdValue: SIMD2<Float> {
        SIMD2<Float>(x, y)
    }
}
