import EngineCore
import simd

public enum MetalDebugLineBuilder {
    public static let boundsColor = SIMD4<Float>(1.0, 0.92, 0.22, 1.0)
    public static let normalColor = SIMD4<Float>(0.35, 0.85, 1.0, 1.0)

    public static func makeBoundsLineVertices(
        descriptors: [MetalTerrainMeshDescriptor],
        color: SIMD4<Float> = boundsColor,
        verticalScale: Float = 1
    ) -> [MetalDebugLineVertex] {
        descriptors.flatMap {
            makeBoundsLineVertices(
                bounds: $0.meshPayload.bounds,
                color: $0.isSelected ? selectedBoundsColor : color,
                verticalScale: verticalScale
            )
        }
    }

    public static func makeBoundsLineVertices(
        bounds: TerrainMeshBounds,
        color: SIMD4<Float> = boundsColor,
        verticalScale: Float = 1
    ) -> [MetalDebugLineVertex] {
        let yScale = sanitizedVerticalScale(verticalScale)
        let min = SIMD3<Float>(bounds.min.x, bounds.min.y * yScale, bounds.min.z)
        let max = SIMD3<Float>(bounds.max.x, bounds.max.y * yScale, bounds.max.z)
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
        color: SIMD4<Float> = normalColor,
        verticalScale: Float = 1
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled else {
            return []
        }

        let yScale = sanitizedVerticalScale(verticalScale)
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
                    vertex.position.y * yScale,
                    vertex.position.z
                )
                let scaledNormal = SIMD3<Float>(
                    vertex.normal.x,
                    vertex.normal.y * yScale,
                    vertex.normal.z
                )
                let length = simd_length(scaledNormal)
                let normal = length > 0 && length.isFinite
                    ? scaledNormal / length
                    : SIMD3<Float>(0, 1, 0)
                let end = start + normal * configuration.length
                lines.append(MetalDebugLineVertex(position: start, color: color))
                lines.append(MetalDebugLineVertex(position: end, color: color))
            }
        }
        return lines
    }

    public static func makeGridLineVertices(
        descriptors: [MetalTerrainMeshDescriptor],
        configuration: MetalDebugGridConfiguration,
        verticalScale: Float = 1
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled,
              let first = descriptors.first?.meshPayload.bounds
        else {
            return []
        }

        let yScale = sanitizedVerticalScale(verticalScale)
        var minX = first.min.x
        var maxX = first.max.x
        var minZ = first.min.z
        var maxZ = first.max.z
        var maxY = first.max.y * yScale
        var xBoundaries = [first.min.x, first.max.x]
        var zBoundaries = [first.min.z, first.max.z]

        for descriptor in descriptors.dropFirst() {
            let bounds = descriptor.meshPayload.bounds
            minX = min(minX, bounds.min.x)
            maxX = max(maxX, bounds.max.x)
            minZ = min(minZ, bounds.min.z)
            maxZ = max(maxZ, bounds.max.z)
            maxY = max(maxY, bounds.max.y * yScale)
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
        configuration: MetalDebugPickedPointMarkerConfiguration,
        verticalScale: Float = 1
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled, let point else {
            return []
        }

        let center = scaledPosition(point.position, verticalScale: verticalScale)
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
        configuration: MetalDebugProbeMarkerConfiguration,
        verticalScale: Float = 1
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled, let point else {
            return []
        }

        let center = scaledPosition(point.position, verticalScale: verticalScale)
        let radius = configuration.radius
        let height = configuration.height
        let color = configuration.color
        let base = center + SIMD3<Float>(0, radius * 0.2, 0)
        let top = center + SIMD3<Float>(0, height, 0)
        let haloY = center.y + height * 0.72
        let east = SIMD3<Float>(center.x + radius, haloY, center.z)
        let north = SIMD3<Float>(center.x, haloY, center.z + radius)
        let west = SIMD3<Float>(center.x - radius, haloY, center.z)
        let south = SIMD3<Float>(center.x, haloY, center.z - radius)

        let endpoints = [
            (center, top),
            (base + SIMD3<Float>(-radius, 0, 0), base + SIMD3<Float>(radius, 0, 0)),
            (base + SIMD3<Float>(0, 0, -radius), base + SIMD3<Float>(0, 0, radius)),
            (top, east),
            (top, north),
            (top, west),
            (top, south),
            (east, north),
            (north, west),
            (west, south),
            (south, east)
        ]

        return endpoints.flatMap { start, end in
            [
                MetalDebugLineVertex(position: start, color: color),
                MetalDebugLineVertex(position: end, color: color)
            ]
        }
    }

    public static func makePlayerMarkerLineVertices(
        point: MetalDebugWorldPoint?,
        configuration: MetalDebugPlayerMarkerConfiguration,
        verticalScale: Float = 1
    ) -> [MetalDebugLineVertex] {
        guard configuration.isEnabled, let point else {
            return []
        }

        let center = scaledPosition(point.position, verticalScale: verticalScale)
        let radius = configuration.radius
        let height = configuration.height
        let color = configuration.color
        let baseY = center.y + radius * 0.15
        let shoulderY = center.y + height * 0.62
        let headY = center.y + height

        let base = SIMD3<Float>(center.x, baseY, center.z)
        let head = SIMD3<Float>(center.x, headY, center.z)
        let eastBase = SIMD3<Float>(center.x + radius, baseY, center.z)
        let westBase = SIMD3<Float>(center.x - radius, baseY, center.z)
        let northBase = SIMD3<Float>(center.x, baseY, center.z + radius)
        let southBase = SIMD3<Float>(center.x, baseY, center.z - radius)
        let eastShoulder = SIMD3<Float>(center.x + radius * 0.75, shoulderY, center.z)
        let westShoulder = SIMD3<Float>(center.x - radius * 0.75, shoulderY, center.z)
        let northShoulder = SIMD3<Float>(center.x, shoulderY, center.z + radius * 0.75)
        let southShoulder = SIMD3<Float>(center.x, shoulderY, center.z - radius * 0.75)
        let headingEnd = SIMD3<Float>(center.x, shoulderY, center.z + radius * 1.8)

        let endpoints = [
            (base, head),
            (eastBase, eastShoulder),
            (westBase, westShoulder),
            (northBase, northShoulder),
            (southBase, southShoulder),
            (eastBase, northBase),
            (northBase, westBase),
            (westBase, southBase),
            (southBase, eastBase),
            (eastShoulder, head),
            (northShoulder, head),
            (westShoulder, head),
            (southShoulder, head),
            (base, headingEnd)
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

    private static func scaledPosition(
        _ position: SIMD3<Float>,
        verticalScale: Float
    ) -> SIMD3<Float> {
        SIMD3<Float>(
            position.x,
            position.y * sanitizedVerticalScale(verticalScale),
            position.z
        )
    }

    private static func sanitizedVerticalScale(_ value: Float) -> Float {
        value.isFinite ? max(value, 0.05) : 1
    }

    private static let selectedBoundsColor = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
}
