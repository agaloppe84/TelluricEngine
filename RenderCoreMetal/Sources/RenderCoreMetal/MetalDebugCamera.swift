import EngineCore
import simd

public struct MetalDebugCamera {
    public var state: MetalDebugCameraState

    public init(
        target: SIMD3<Float> = .zero,
        distance: Float = 180,
        orthographicScale: Float = 160,
        nearZ: Float = 0.1,
        farZ: Float = 2_000
    ) {
        self.state = MetalDebugCameraState(
            target: target,
            distance: distance,
            orthographicScale: orthographicScale,
            nearZ: nearZ,
            farZ: farZ
        )
    }

    public init(state: MetalDebugCameraState) {
        self.state = state
    }

    public static func fitting(bounds: [TerrainMeshBounds]) -> MetalDebugCamera {
        MetalDebugCamera(state: MetalDebugCameraController().reset(bounds: bounds))
    }

    public func viewProjectionMatrix(aspectRatio: Float) -> simd_float4x4 {
        let horizontal = cos(state.pitchRadians)
        let direction = simd_normalize(
            SIMD3<Float>(
                sin(state.yawRadians) * horizontal,
                sin(state.pitchRadians),
                cos(state.yawRadians) * horizontal
            )
        )
        let eye = state.target + direction * state.distance
        let view = Self.lookAt(eye: eye, target: state.target, up: SIMD3<Float>(0, 1, 0))
        let halfHeight = state.orthographicScale * 0.5
        let halfWidth = halfHeight * max(aspectRatio, 0.1)
        let projection = Self.orthographic(
            left: -halfWidth,
            right: halfWidth,
            bottom: -halfHeight,
            top: halfHeight,
            nearZ: state.nearZ,
            farZ: state.farZ
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
