import EngineCore
import simd

public struct MetalDebugCameraController: Sendable {
    public let minZoomScale: Float
    public let maxZoomScale: Float
    public let minPitchRadians: Float
    public let maxPitchRadians: Float

    public init(
        minZoomScale: Float = 0.22,
        maxZoomScale: Float = 4.0,
        minPitchRadians: Float = 0.18,
        maxPitchRadians: Float = 1.35
    ) {
        self.minZoomScale = minZoomScale
        self.maxZoomScale = maxZoomScale
        self.minPitchRadians = minPitchRadians
        self.maxPitchRadians = maxPitchRadians
    }

    public func reset(bounds: [TerrainMeshBounds]?) -> MetalDebugCameraState {
        guard let bounds, let first = bounds.first else {
            return sanitize(MetalDebugCameraState())
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

        return sanitize(
            MetalDebugCameraState(
                target: center,
                distance: max(scale * 1.4, 120),
                yawRadians: 0.70,
                pitchRadians: 0.82,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 6, 2_000)
            )
        )
    }

    public func apply(
        _ input: MetalDebugCameraInput,
        to state: MetalDebugCameraState,
        bounds: [TerrainMeshBounds]? = nil
    ) -> MetalDebugCameraState {
        switch input {
        case .pan(let dx, let dz):
            return pan(state, dx: dx, dz: dz)
        case .zoom(let delta):
            return zoom(state, delta: delta)
        case .orbit(let deltaYaw, let deltaPitch):
            return orbit(state, deltaYaw: deltaYaw, deltaPitch: deltaPitch)
        case .reset, .fitTerrain:
            return reset(bounds: bounds)
        }
    }

    public func pan(
        _ state: MetalDebugCameraState,
        dx: Float,
        dz: Float
    ) -> MetalDebugCameraState {
        var next = sanitize(state)
        next.target += SIMD3<Float>(finite(dx), 0, finite(dz))
        return sanitize(next)
    }

    public func zoom(
        _ state: MetalDebugCameraState,
        delta: Float
    ) -> MetalDebugCameraState {
        let current = sanitize(state)
        let baseDistance = current.distance / max(current.zoomScale, 0.001)
        let baseScale = current.orthographicScale / max(current.zoomScale, 0.001)
        let factor = max(0.05, 1 + finite(delta))
        let zoomScale = clamp(current.zoomScale * factor, minZoomScale, maxZoomScale)

        var next = current
        next.zoomScale = zoomScale
        next.distance = clamp(baseDistance * zoomScale, 12, 20_000)
        next.orthographicScale = clamp(baseScale * zoomScale, 4, 20_000)
        return sanitize(next)
    }

    public func orbit(
        _ state: MetalDebugCameraState,
        deltaYaw: Float,
        deltaPitch: Float
    ) -> MetalDebugCameraState {
        var next = sanitize(state)
        next.yawRadians = finite(next.yawRadians + deltaYaw)
        next.pitchRadians = clamp(next.pitchRadians + finite(deltaPitch), minPitchRadians, maxPitchRadians)
        return sanitize(next)
    }

    private func sanitize(_ state: MetalDebugCameraState) -> MetalDebugCameraState {
        var next = state
        next.target = SIMD3<Float>(
            finite(next.target.x),
            finite(next.target.y),
            finite(next.target.z)
        )
        next.zoomScale = clamp(finite(next.zoomScale, fallback: 1), minZoomScale, maxZoomScale)
        next.distance = clamp(finite(next.distance, fallback: 180), 12, 20_000)
        next.orthographicScale = clamp(finite(next.orthographicScale, fallback: 160), 4, 20_000)
        next.yawRadians = finite(next.yawRadians)
        next.pitchRadians = clamp(finite(next.pitchRadians, fallback: 0.82), minPitchRadians, maxPitchRadians)
        next.nearZ = clamp(finite(next.nearZ, fallback: 0.1), 0.001, 10_000)
        next.farZ = max(next.nearZ + 1, finite(next.farZ, fallback: 2_000))
        return next
    }

    private func finite(_ value: Float, fallback: Float = 0) -> Float {
        value.isFinite ? value : fallback
    }

    private func clamp(_ value: Float, _ lower: Float, _ upper: Float) -> Float {
        min(max(value, lower), upper)
    }
}
