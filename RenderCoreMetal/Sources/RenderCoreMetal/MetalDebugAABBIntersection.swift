import EngineCore
import simd

public enum MetalDebugAABBIntersection {
    public static func distance(
        ray: MetalDebugRay,
        bounds: TerrainMeshBounds
    ) -> Float? {
        distance(
            ray: ray,
            min: SIMD3<Float>(bounds.min.x, bounds.min.y, bounds.min.z),
            max: SIMD3<Float>(bounds.max.x, bounds.max.y, bounds.max.z)
        )
    }

    public static func distance(
        ray: MetalDebugRay,
        min minPoint: SIMD3<Float>,
        max maxPoint: SIMD3<Float>
    ) -> Float? {
        let epsilon: Float = 0.000_001
        var tMin = -Float.greatestFiniteMagnitude
        var tMax = Float.greatestFiniteMagnitude

        for axis in 0..<3 {
            let origin = ray.origin[axis]
            let direction = ray.direction[axis]
            let lower = min(minPoint[axis], maxPoint[axis])
            let upper = max(minPoint[axis], maxPoint[axis])

            if abs(direction) < epsilon {
                if origin < lower || origin > upper {
                    return nil
                }
                continue
            }

            var t1 = (lower - origin) / direction
            var t2 = (upper - origin) / direction
            if t1 > t2 {
                swap(&t1, &t2)
            }

            tMin = max(tMin, t1)
            tMax = min(tMax, t2)

            if tMin > tMax {
                return nil
            }
        }

        if tMin >= 0 {
            return tMin.isFinite ? tMin : nil
        }
        if tMax >= 0 {
            return tMax.isFinite ? tMax : nil
        }
        return nil
    }
}
