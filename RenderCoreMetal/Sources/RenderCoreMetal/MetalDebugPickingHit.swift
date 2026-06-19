import EngineCore
import simd

public struct MetalDebugPickingHit: Sendable, Hashable {
    public let chunkID: WorldChunkID?
    public let chunkCoord: WorldChunkCoord
    public let distance: Float
    public let worldPosition: MetalDebugWorldPoint
    public let nearestVertexPosition: SIMD3<Float>?
    public let nearestVertexNormal: SIMD3<Float>?
    public let nearestVertexIndex: Int?
    public let nearestSampleCoord: TerrainSampleCoord?
    public let heightMeters: Float?
    public let surface: TerrainSurfaceSample?
    public let meshStableHash: UInt64?

    public init(
        chunkID: WorldChunkID?,
        chunkCoord: WorldChunkCoord,
        distance: Float,
        worldPosition: MetalDebugWorldPoint,
        nearestVertexPosition: SIMD3<Float>? = nil,
        nearestVertexNormal: SIMD3<Float>? = nil,
        nearestVertexIndex: Int? = nil,
        nearestSampleCoord: TerrainSampleCoord? = nil,
        heightMeters: Float? = nil,
        surface: TerrainSurfaceSample? = nil,
        meshStableHash: UInt64? = nil
    ) {
        self.chunkID = chunkID
        self.chunkCoord = chunkCoord
        self.distance = distance.isFinite ? max(distance, 0) : 0
        self.worldPosition = worldPosition
        self.nearestVertexPosition = nearestVertexPosition
        self.nearestVertexNormal = nearestVertexNormal
        self.nearestVertexIndex = nearestVertexIndex
        self.nearestSampleCoord = nearestSampleCoord
        self.heightMeters = heightMeters
        self.surface = surface
        self.meshStableHash = meshStableHash
    }

    public var stableDebugID: UInt64 {
        var state = chunkCoord.stableHash
        state = mix(state, chunkID?.stableHash ?? 0)
        state = mix(state, UInt64(distance.bitPattern))
        for value in [worldPosition.position.x, worldPosition.position.y, worldPosition.position.z] {
            state = mix(state, UInt64(value.bitPattern))
        }
        if let nearestVertexPosition {
            state = mix(state, 1)
            for value in [nearestVertexPosition.x, nearestVertexPosition.y, nearestVertexPosition.z] {
                state = mix(state, UInt64(value.bitPattern))
            }
        } else {
            state = mix(state, 0)
        }
        if let nearestVertexIndex {
            state = mix(state, 1)
            state = mix(state, UInt64(nearestVertexIndex))
        } else {
            state = mix(state, 0)
        }
        state = mix(state, meshStableHash ?? 0)
        return state
    }

    private func mix(_ state: UInt64, _ value: UInt64) -> UInt64 {
        (state &* 0x9E37_79B9_7F4A_7C15) ^ value
    }
}
