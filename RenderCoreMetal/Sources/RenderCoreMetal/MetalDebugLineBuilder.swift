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

    public static func makeGridLineVertices(
        descriptors: [MetalTerrainMeshDescriptor],
        configuration: MetalDebugGridConfiguration
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled,
              let first = descriptors.first?.meshPayload.bounds
        else {
            return []
        }

        var minX = first.min.x
        var maxX = first.max.x
        var minZ = first.min.z
        var maxZ = first.max.z
        var maxY = first.max.y
        var xBoundaries = [first.min.x, first.max.x]
        var zBoundaries = [first.min.z, first.max.z]

        for descriptor in descriptors.dropFirst() {
            let bounds = descriptor.meshPayload.bounds
            minX = min(minX, bounds.min.x)
            maxX = max(maxX, bounds.max.x)
            minZ = min(minZ, bounds.min.z)
            maxZ = max(maxZ, bounds.max.z)
            maxY = max(maxY, bounds.max.y)
            xBoundaries.append(bounds.min.x)
            xBoundaries.append(bounds.max.x)
            zBoundaries.append(bounds.min.z)
            zBoundaries.append(bounds.max.z)
        }

        let y = maxY + configuration.heightOffset
        let uniqueX = stableUniqueFloats(xBoundaries)
        let uniqueZ = stableUniqueFloats(zBoundaries)
        var lines: [MetalDebugLineVertex] = []

        for x in uniqueX {
            lines.append(MetalDebugLineVertex(position: SIMD3<Float>(x, y, minZ), color: configuration.color))
            lines.append(MetalDebugLineVertex(position: SIMD3<Float>(x, y, maxZ), color: configuration.color))
        }

        for z in uniqueZ {
            lines.append(MetalDebugLineVertex(position: SIMD3<Float>(minX, y, z), color: configuration.color))
            lines.append(MetalDebugLineVertex(position: SIMD3<Float>(maxX, y, z), color: configuration.color))
        }

        return lines
    }

    public static func makePickedPointMarkerLineVertices(
        point: MetalDebugWorldPoint?,
        configuration: MetalDebugPickedPointMarkerConfiguration
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled, let point else {
            return []
        }

        let center = point.position
        let size = configuration.size
        let color = configuration.color

        let endpoints = [
            (center + SIMD3<Float>(-size, 0, 0), center + SIMD3<Float>(size, 0, 0)),
            (center + SIMD3<Float>(0, -size, 0), center + SIMD3<Float>(0, size, 0)),
            (center + SIMD3<Float>(0, 0, -size), center + SIMD3<Float>(0, 0, size))
        ]

        return endpoints.flatMap { start, end in
            [
                MetalDebugLineVertex(position: start, color: color),
                MetalDebugLineVertex(position: end, color: color)
            ]
        }
    }

    public static func makeProbeMarkerLineVertices(
        point: MetalDebugWorldPoint?,
        configuration: MetalDebugProbeMarkerConfiguration
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled, let point else {
            return []
        }

        let center = point.position
        let radius = configuration.radius
        let height = configuration.height
        let color = configuration.color
        let raisedCenter = center + SIMD3<Float>(0, radius, 0)

        let endpoints = [
            (center, center + SIMD3<Float>(0, height, 0)),
            (raisedCenter + SIMD3<Float>(-radius, 0, 0), raisedCenter + SIMD3<Float>(radius, 0, 0)),
            (raisedCenter + SIMD3<Float>(0, 0, -radius), raisedCenter + SIMD3<Float>(0, 0, radius))
        ]

        return endpoints.flatMap { start, end in
            [
                MetalDebugLineVertex(position: start, color: color),
                MetalDebugLineVertex(position: end, color: color)
            ]
        }
    }

    private static func stableUniqueFloats(_ values: [Float]) -> [Float] {
        var seen = Set<UInt32>()
        return values
            .filter(\.isFinite)
            .sorted {
                if $0 != $1 {
                    return $0 < $1
                }
                return $0.bitPattern < $1.bitPattern
            }
            .filter { value in
                seen.insert(value.bitPattern).inserted
            }
    }

    private static let selectedBoundsColor = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
}
