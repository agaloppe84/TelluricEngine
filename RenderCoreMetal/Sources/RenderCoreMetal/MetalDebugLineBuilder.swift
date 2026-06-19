import EngineCore
import simd

public enum MetalDebugLineBuilder {
    public static let boundsColor = SIMD4<Float>(1.0, 0.92, 0.22, 1.0)
    public static let normalColor = SIMD4<Float>(0.35, 0.85, 1.0, 1.0)

    public static func makeBoundsLineVertices(
        descriptors: [MetalTerrainMeshDescriptor],
        color: SIMD4<Float> = boundsColor
    ) -> [MetalDebugLineVertex] {
        descriptors.flatMap {
            makeBoundsLineVertices(bounds: $0.meshPayload.bounds, color: $0.isSelected ? selectedBoundsColor : color)
        }
    }

    public static func makeBoundsLineVertices(
        bounds: TerrainMeshBounds,
        color: SIMD4<Float> = boundsColor
    ) -> [MetalDebugLineVertex] {
        let min = SIMD3<Float>(bounds.min.x, bounds.min.y, bounds.min.z)
        let max = SIMD3<Float>(bounds.max.x, bounds.max.y, bounds.max.z)
        let corners = [
            SIMD3<Float>(min.x, min.y, min.z),
            SIMD3<Float>(max.x, min.y, min.z),
            SIMD3<Float>(max.x, min.y, max.z),
            SIMD3<Float>(min.x, min.y, max.z),
            SIMD3<Float>(min.x, max.y, min.z),
            SIMD3<Float>(max.x, max.y, min.z),
            SIMD3<Float>(max.x, max.y, max.z),
            SIMD3<Float>(min.x, max.y, max.z)
        ]
        let edgePairs = [
            (0, 1), (1, 2), (2, 3), (3, 0),
            (4, 5), (5, 6), (6, 7), (7, 4),
            (0, 4), (1, 5), (2, 6), (3, 7)
        ]

        return edgePairs.flatMap { edge in
            [
                MetalDebugLineVertex(position: corners[edge.0], color: color),
                MetalDebugLineVertex(position: corners[edge.1], color: color)
            ]
        }
    }

    public static func makeNormalLineVertices(
        descriptors: [MetalTerrainMeshDescriptor],
        configuration: MetalDebugNormalsConfiguration,
        color: SIMD4<Float> = normalColor
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled else {
            return []
        }

        var lines: [MetalDebugLineVertex] = []
        for descriptor in descriptors {
            let vertices = descriptor.meshPayload.vertices
            guard vertices.isEmpty == false else {
                continue
            }

            let sampleStride = max(1, configuration.stride)
            for index in Swift.stride(from: 0, to: vertices.count, by: sampleStride) {
                let vertex = vertices[index]
                let start = SIMD3<Float>(
                    vertex.position.x,
                    vertex.position.y,
                    vertex.position.z
                )
                let normal = SIMD3<Float>(
                    vertex.normal.x,
                    vertex.normal.y,
                    vertex.normal.z
                )
                let end = start + normal * configuration.length
                lines.append(MetalDebugLineVertex(position: start, color: color))
                lines.append(MetalDebugLineVertex(position: end, color: color))
            }
        }
        return lines
    }

    private static let selectedBoundsColor = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
}
