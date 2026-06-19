import Foundation

public struct TerrainQueryEngine: Sendable {
    public let snapshot: ResidentWorldSnapshot
    public let walkabilityConfig: TerrainWalkabilityConfig

    public init(
        snapshot: ResidentWorldSnapshot,
        walkabilityConfig: TerrainWalkabilityConfig = .default
    ) {
        self.snapshot = snapshot
        self.walkabilityConfig = walkabilityConfig
    }

    public func query(_ request: TerrainQueryRequest) -> TerrainQueryResult {
        guard request.worldX.isFinite, request.worldZ.isFinite else {
            return TerrainQueryResult.outsideKnownTerrain(
                worldX: request.worldX,
                worldZ: request.worldZ,
                walkabilityConfig: walkabilityConfig
            )
        }

        guard let record = recordContaining(worldX: request.worldX, worldZ: request.worldZ),
              let meshPayload = record.meshPayload
        else {
            return TerrainQueryResult.outsideKnownTerrain(
                worldX: request.worldX,
                worldZ: request.worldZ,
                walkabilityConfig: walkabilityConfig
            )
        }

        switch request.queryMode {
        case .nearestVertex:
            return nearestVertexResult(
                request: request,
                record: record,
                meshPayload: meshPayload
            )
        case .bilinearHeightfield:
            return bilinearResult(
                request: request,
                record: record,
                meshPayload: meshPayload
            ) ?? nearestVertexResult(
                request: request,
                record: record,
                meshPayload: meshPayload
            )
        }
    }

    public func recordsWithMeshPayload() -> [CachedChunkRecord] {
        snapshot.records.filter { $0.meshPayload != nil }
    }

    public func recordContaining(worldX: Float, worldZ: Float) -> CachedChunkRecord? {
        recordsWithMeshPayload().first { record in
            guard let bounds = record.meshPayload?.bounds else {
                return false
            }
            return worldX >= bounds.min.x && worldX <= bounds.max.x
                && worldZ >= bounds.min.z && worldZ <= bounds.max.z
        }
    }

    private func bilinearResult(
        request: TerrainQueryRequest,
        record: CachedChunkRecord,
        meshPayload: TerrainMeshPayload
    ) -> TerrainQueryResult? {
        let samplesPerAxis = meshPayload.layout.samplesPerAxis
        guard samplesPerAxis >= 2 else {
            return nil
        }

        let origin = meshPayload.vertex(localX: 0, localZ: 0).position
        let east = meshPayload.vertex(localX: samplesPerAxis - 1, localZ: 0).position
        let north = meshPayload.vertex(localX: 0, localZ: samplesPerAxis - 1).position
        let stepX = (east.x - origin.x) / Float(samplesPerAxis - 1)
        let stepZ = (north.z - origin.z) / Float(samplesPerAxis - 1)

        guard stepX.isFinite, stepX > 0, stepZ.isFinite, stepZ > 0 else {
            return nil
        }

        let gridX = clamp(
            (request.worldX - origin.x) / stepX,
            min: 0,
            max: Float(samplesPerAxis - 1)
        )
        let gridZ = clamp(
            (request.worldZ - origin.z) / stepZ,
            min: 0,
            max: Float(samplesPerAxis - 1)
        )

        let x0 = min(max(Int(gridX.rounded(.down)), 0), samplesPerAxis - 2)
        let z0 = min(max(Int(gridZ.rounded(.down)), 0), samplesPerAxis - 2)
        let x1 = x0 + 1
        let z1 = z0 + 1
        let tx = clamp(gridX - Float(x0), min: 0, max: 1)
        let tz = clamp(gridZ - Float(z0), min: 0, max: 1)

        let v00 = meshPayload.vertex(localX: x0, localZ: z0)
        let v10 = meshPayload.vertex(localX: x1, localZ: z0)
        let v01 = meshPayload.vertex(localX: x0, localZ: z1)
        let v11 = meshPayload.vertex(localX: x1, localZ: z1)

        let height = bilerp(
            v00.heightMeters,
            v10.heightMeters,
            v01.heightMeters,
            v11.heightMeters,
            tx: tx,
            tz: tz
        )
        let normal = (
            v00.normal * ((1 - tx) * (1 - tz))
            + v10.normal * (tx * (1 - tz))
            + v01.normal * ((1 - tx) * tz)
            + v11.normal * (tx * tz)
        ).normalized
        let safeNormal = normal.lengthSquared > 0 ? normal : .up
        let nearest = nearestVertex(
            candidates: [v00, v10, v01, v11],
            worldX: request.worldX,
            worldZ: request.worldZ
        )

        return makeResult(
            worldX: request.worldX,
            worldZ: request.worldZ,
            height: height,
            normal: safeNormal,
            nearestVertex: nearest,
            record: record,
            meshPayload: meshPayload
        )
    }

    private func nearestVertexResult(
        request: TerrainQueryRequest,
        record: CachedChunkRecord,
        meshPayload: TerrainMeshPayload
    ) -> TerrainQueryResult {
        let nearest = nearestVertex(
            candidates: meshPayload.vertices,
            worldX: request.worldX,
            worldZ: request.worldZ
        )
        return makeResult(
            worldX: request.worldX,
            worldZ: request.worldZ,
            height: nearest.heightMeters,
            normal: nearest.normal.lengthSquared > 0 ? nearest.normal.normalized : .up,
            nearestVertex: nearest,
            record: record,
            meshPayload: meshPayload
        )
    }

    private func makeResult(
        worldX: Float,
        worldZ: Float,
        height: Float,
        normal: TEVec3f,
        nearestVertex: TerrainMeshVertex,
        record: CachedChunkRecord,
        meshPayload: TerrainMeshPayload
    ) -> TerrainQueryResult {
        let safeNormal = normal.lengthSquared > 0 ? normal.normalized : .up
        let slopeRadians = slopeRadians(for: safeNormal)
        let slopeDegrees = slopeRadians * 180 / Float.pi
        let slope01 = clamp(slopeDegrees / 90, min: 0, max: 1)
        let surface = TerrainQuerySurfaceResult(sample: nearestVertex.surface)
        let walkability = TerrainWalkability.evaluate(
            surface: surface,
            slopeDegrees: slopeDegrees,
            isInsideKnownTerrain: true,
            config: walkabilityConfig
        )

        return TerrainQueryResult(
            worldPosition: TerrainWorldPosition(x: worldX, y: height, z: worldZ),
            sampleCoord: nearestVertex.sampleCoord,
            heightMeters: height,
            normal: safeNormal,
            surface: surface,
            slopeRadians: slopeRadians,
            slopeDegrees: slopeDegrees,
            slope01: slope01,
            slopeClassification: TerrainSlopeClassification.classify(slopeDegrees: slopeDegrees),
            walkability: walkability,
            isInsideKnownTerrain: true,
            sourceChunkID: record.chunkID,
            sourceMeshHash: meshPayload.stableHash
        )
    }

    private func nearestVertex(
        candidates: [TerrainMeshVertex],
        worldX: Float,
        worldZ: Float
    ) -> TerrainMeshVertex {
        candidates.min { lhs, rhs in
            let lhsDistance = distanceSquaredXZ(lhs.position, worldX: worldX, worldZ: worldZ)
            let rhsDistance = distanceSquaredXZ(rhs.position, worldX: worldX, worldZ: worldZ)
            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }
            if lhs.sampleCoord.x != rhs.sampleCoord.x {
                return lhs.sampleCoord.x < rhs.sampleCoord.x
            }
            return lhs.sampleCoord.z < rhs.sampleCoord.z
        } ?? TerrainMeshVertex(
            position: TEVec3f(x: worldX, y: 0, z: worldZ),
            normal: .up,
            uv: TEVec2f(x: 0, y: 0),
            sampleCoord: TerrainSampleCoord(x: 0, z: 0),
            heightMeters: 0,
            surface: TerrainSurfaceSample(
                material: .soil,
                physicalTag: .looseSoil,
                audioTag: .dirt,
                slope01: 0,
                moisture01: 0.5,
                heightMeters: 0
            )
        )
    }

    private func distanceSquaredXZ(_ position: TEVec3f, worldX: Float, worldZ: Float) -> Float {
        let dx = position.x - worldX
        let dz = position.z - worldZ
        return dx * dx + dz * dz
    }

    private func slopeRadians(for normal: TEVec3f) -> Float {
        let y = clamp(normal.normalized.y, min: -1, max: 1)
        return Float(acos(Double(y)))
    }

    private func bilerp(
        _ v00: Float,
        _ v10: Float,
        _ v01: Float,
        _ v11: Float,
        tx: Float,
        tz: Float
    ) -> Float {
        let x0 = lerp(v00, v10, tx)
        let x1 = lerp(v01, v11, tx)
        return lerp(x0, x1, tz)
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    private func clamp(_ value: Float, min minValue: Float, max maxValue: Float) -> Float {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}
