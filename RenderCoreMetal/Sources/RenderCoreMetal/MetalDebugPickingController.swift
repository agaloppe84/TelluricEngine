import EngineCore
import simd

public struct MetalDebugPickingController: Sendable {
    public init() {}

    public func makeRay(
        screenPoint: SIMD2<Float>,
        viewportSize: SIMD2<Float>,
        cameraState: MetalDebugCameraState
    ) -> MetalDebugRay? {
        guard viewportSize.x.isFinite,
              viewportSize.y.isFinite,
              viewportSize.x > 0,
              viewportSize.y > 0
        else {
            return nil
        }

        let ndcX = (screenPoint.x / viewportSize.x) * 2 - 1
        let ndcY = 1 - (screenPoint.y / viewportSize.y) * 2

        guard ndcX.isFinite, ndcY.isFinite else {
            return nil
        }

        let aspectRatio = viewportSize.y > 0 ? viewportSize.x / viewportSize.y : 1
        let viewProjection = MetalDebugCamera(state: cameraState)
            .viewProjectionMatrix(aspectRatio: aspectRatio)
        let inverseViewProjection = simd_inverse(viewProjection)

        let nearClip = SIMD4<Float>(ndcX, ndcY, 0, 1)
        let farClip = SIMD4<Float>(ndcX, ndcY, 1, 1)
        let nearWorld = inverseViewProjection * nearClip
        let farWorld = inverseViewProjection * farClip

        guard abs(nearWorld.w) > 0.000_001,
              abs(farWorld.w) > 0.000_001
        else {
            return nil
        }

        let origin = SIMD3<Float>(
            nearWorld.x / nearWorld.w,
            nearWorld.y / nearWorld.w,
            nearWorld.z / nearWorld.w
        )
        let far = SIMD3<Float>(
            farWorld.x / farWorld.w,
            farWorld.y / farWorld.w,
            farWorld.z / farWorld.w
        )

        let direction = far - origin
        guard simd_length(direction) > 0.000_001 else {
            return nil
        }

        return MetalDebugRay(origin: origin, direction: direction)
    }

    public func pick(
        screenPoint: SIMD2<Float>,
        viewportSize: SIMD2<Float>,
        cameraState: MetalDebugCameraState,
        descriptors: [MetalTerrainMeshDescriptor]
    ) -> MetalDebugPickingResult {
        let wrappedScreenPoint = MetalDebugScreenPoint(screenPoint)
        let wrappedViewportSize = MetalDebugScreenPoint(viewportSize)

        guard viewportSize.x > 0, viewportSize.y > 0 else {
            return MetalDebugPickingResult(
                screenPoint: wrappedScreenPoint,
                viewportSize: wrappedViewportSize,
                ray: nil,
                hit: nil,
                missReason: .invalidViewport
            )
        }

        guard let ray = makeRay(
            screenPoint: screenPoint,
            viewportSize: viewportSize,
            cameraState: cameraState
        ) else {
            return MetalDebugPickingResult(
                screenPoint: wrappedScreenPoint,
                viewportSize: wrappedViewportSize,
                ray: nil,
                hit: nil,
                missReason: .invalidRay
            )
        }

        return pick(
            ray: ray,
            screenPoint: wrappedScreenPoint,
            viewportSize: wrappedViewportSize,
            descriptors: descriptors
        )
    }

    public func pick(
        ray: MetalDebugRay,
        screenPoint: MetalDebugScreenPoint = MetalDebugScreenPoint(x: 0, y: 0),
        viewportSize: MetalDebugScreenPoint = MetalDebugScreenPoint(x: 1, y: 1),
        descriptors: [MetalTerrainMeshDescriptor]
    ) -> MetalDebugPickingResult {
        guard descriptors.isEmpty == false else {
            return MetalDebugPickingResult(
                screenPoint: screenPoint,
                viewportSize: viewportSize,
                ray: ray,
                hit: nil,
                missReason: .noMeshDescriptors
            )
        }

        let hits = descriptors.compactMap { descriptor -> MetalDebugPickingHit? in
            guard let distance = MetalDebugAABBIntersection.distance(
                ray: ray,
                bounds: descriptor.meshPayload.bounds
            ) else {
                return nil
            }

            let worldPosition = ray.point(at: distance)
            let nearest = nearestVertex(to: worldPosition, in: descriptor.meshPayload)
            let chunkCoord = descriptor.chunkID?.coord
                ?? WorldChunkCoord(chunkCoord: descriptor.meshPayload.chunkCoord)

            return MetalDebugPickingHit(
                chunkID: descriptor.chunkID,
                chunkCoord: chunkCoord,
                distance: distance,
                worldPosition: MetalDebugWorldPoint(position: worldPosition),
                nearestVertexPosition: nearest?.position,
                nearestVertexNormal: nearest?.normal,
                nearestVertexIndex: nearest?.index,
                nearestSampleCoord: nearest?.sampleCoord,
                heightMeters: nearest?.heightMeters,
                surface: nearest?.surface,
                meshStableHash: descriptor.meshPayload.stableHash
            )
        }
        .sorted(by: stableHitSort)

        return MetalDebugPickingResult(
            screenPoint: screenPoint,
            viewportSize: viewportSize,
            ray: ray,
            hit: hits.first,
            missReason: hits.isEmpty ? .noBoundsHit : nil
        )
    }

    private func nearestVertex(
        to point: SIMD3<Float>,
        in mesh: TerrainMeshPayload
    ) -> NearestVertex? {
        var best: NearestVertex?

        for (index, vertex) in mesh.vertices.enumerated() {
            let position = SIMD3<Float>(
                vertex.position.x,
                vertex.position.y,
                vertex.position.z
            )
            let delta = position - point
            let distanceSquared = simd_dot(delta, delta)

            if let current = best {
                if distanceSquared < current.distanceSquared ||
                    (distanceSquared == current.distanceSquared && index < current.index) {
                    best = NearestVertex(
                        index: index,
                        distanceSquared: distanceSquared,
                        position: position,
                        normal: SIMD3<Float>(
                            vertex.normal.x,
                            vertex.normal.y,
                            vertex.normal.z
                        ),
                        sampleCoord: vertex.sampleCoord,
                        heightMeters: vertex.heightMeters,
                        surface: vertex.surface
                    )
                }
            } else {
                best = NearestVertex(
                    index: index,
                    distanceSquared: distanceSquared,
                    position: position,
                    normal: SIMD3<Float>(
                        vertex.normal.x,
                        vertex.normal.y,
                        vertex.normal.z
                    ),
                    sampleCoord: vertex.sampleCoord,
                    heightMeters: vertex.heightMeters,
                    surface: vertex.surface
                )
            }
        }

        return best
    }

    private func stableHitSort(
        lhs: MetalDebugPickingHit,
        rhs: MetalDebugPickingHit
    ) -> Bool {
        if lhs.distance != rhs.distance {
            return lhs.distance < rhs.distance
        }
        if lhs.chunkCoord != rhs.chunkCoord {
            return lhs.chunkCoord < rhs.chunkCoord
        }
        if lhs.meshStableHash != rhs.meshStableHash {
            return (lhs.meshStableHash ?? 0) < (rhs.meshStableHash ?? 0)
        }
        return (lhs.nearestVertexIndex ?? Int.max) < (rhs.nearestVertexIndex ?? Int.max)
    }

    private struct NearestVertex {
        let index: Int
        let distanceSquared: Float
        let position: SIMD3<Float>
        let normal: SIMD3<Float>
        let sampleCoord: TerrainSampleCoord
        let heightMeters: Float
        let surface: TerrainSurfaceSample
    }
}
