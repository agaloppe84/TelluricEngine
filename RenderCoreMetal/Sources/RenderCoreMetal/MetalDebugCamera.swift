import EngineCore
import simd

public struct MetalDebugCamera {
    public var target: SIMD3<Float>
    public var distance: Float
    public var orthographicScale: Float
    public var nearZ: Float
    public var farZ: Float

    public init(
        target: SIMD3<Float> = .zero,
        distance: Float = 180,
        orthographicScale: Float = 160,
        nearZ: Float = 0.1,
        farZ: Float = 2_000
    ) {
        self.target = target
        self.distance = distance
        self.orthographicScale = orthographicScale
        self.nearZ = nearZ
        self.farZ = farZ
    }

    public static func fitting(bounds: [TerrainMeshBounds]) -> MetalDebugCamera {
        guard let first = bounds.first else {
            return MetalDebugCamera()
        }

        var minPoint = SIMD3<Float>(first.min.x, first.min.y, first.min.z)
        var maxPoint = SIMD3<Float>(first.max.x, first.max.y, first.max.z)

        for bounds in bounds.dropFirst() {
            minPoint = simd_min(minPoint, SIMD3<Float>(bounds.min.x, bounds.min.y, bounds.min.z))
            maxPoint = simd_max(maxPoint, SIMD3<Float>(bounds.max.x, bounds.max.y, bounds.max.z))
        }

        let center = (minPoint + maxPoint) * 0.5
        let extent = maxPoint - minPoint
        let radius = max(max(extent.x, extent.z), extent.y) * 0.5
        let scale = max(radius * 2.8, 48)

        return MetalDebugCamera(
            target: center,
            distance: max(scale * 1.4, 120),
            orthographicScale: scale,
            nearZ: 0.1,
            farZ: max(scale * 6, 2_000)
        )
    }

    public func viewProjectionMatrix(aspectRatio: Float) -> simd_float4x4 {
        let direction = simd_normalize(SIMD3<Float>(0.72, 1.08, 0.86))
        let eye = target + direction * distance
        let view = Self.lookAt(eye: eye, target: target, up: SIMD3<Float>(0, 1, 0))
        let halfHeight = orthographicScale * 0.5
        let halfWidth = halfHeight * max(aspectRatio, 0.1)
        let projection = Self.orthographic(
            left: -halfWidth,
            right: halfWidth,
            bottom: -halfHeight,
            top: halfHeight,
            nearZ: nearZ,
            farZ: farZ
        )

        return projection * view
    }

    private static func lookAt(
        eye: SIMD3<Float>,
        target: SIMD3<Float>,
        up: SIMD3<Float>
    ) -> simd_float4x4 {
        let zAxis = simd_normalize(eye - target)
        let xAxis = simd_normalize(simd_cross(up, zAxis))
        let yAxis = simd_cross(zAxis, xAxis)

        let translation = SIMD3<Float>(
            -simd_dot(xAxis, eye),
            -simd_dot(yAxis, eye),
            -simd_dot(zAxis, eye)
        )

        return simd_float4x4(
            SIMD4<Float>(xAxis.x, yAxis.x, zAxis.x, 0),
            SIMD4<Float>(xAxis.y, yAxis.y, zAxis.y, 0),
            SIMD4<Float>(xAxis.z, yAxis.z, zAxis.z, 0),
            SIMD4<Float>(translation.x, translation.y, translation.z, 1)
        )
    }

    private static func orthographic(
        left: Float,
        right: Float,
        bottom: Float,
        top: Float,
        nearZ: Float,
        farZ: Float
    ) -> simd_float4x4 {
        let width = right - left
        let height = top - bottom
        let depth = farZ - nearZ

        return simd_float4x4(
            SIMD4<Float>(2 / width, 0, 0, 0),
            SIMD4<Float>(0, 2 / height, 0, 0),
            SIMD4<Float>(0, 0, -1 / depth, 0),
            SIMD4<Float>(
                -(right + left) / width,
                -(top + bottom) / height,
                -nearZ / depth,
                1
            )
        )
    }
}
