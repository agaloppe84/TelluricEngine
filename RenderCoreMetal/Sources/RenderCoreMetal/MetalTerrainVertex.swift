import simd

public struct MetalTerrainVertex: Equatable {
    public var position: SIMD3<Float>
    public var normal: SIMD3<Float>
    public var color: SIMD4<Float>

    public init(
        position: SIMD3<Float>,
        normal: SIMD3<Float>,
        color: SIMD4<Float>
    ) {
        self.position = position
        self.normal = normal
        self.color = color
    }
}
