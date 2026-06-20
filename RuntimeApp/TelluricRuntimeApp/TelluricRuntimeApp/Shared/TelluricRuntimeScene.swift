import EngineCore
import RenderCoreMetal

typealias TelluricRuntimeSceneController = TelluricGameRuntimeModel

struct TelluricRuntimeStreamingUpdateSummary: Hashable {
    let previousCenterChunkCoord: WorldChunkCoord?
    let currentCenterChunkCoord: WorldChunkCoord
    let addedChunkCount: Int
    let keptChunkCount: Int
    let evictedChunkCount: Int
    let createdRecordCount: Int
    let updatedRecordCount: Int
    let reusedRecordCount: Int
    let isFullRebuild: Bool

    init(
        previousCenterChunkCoord: WorldChunkCoord? = nil,
        currentCenterChunkCoord: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0),
        addedChunkCount: Int = 0,
        keptChunkCount: Int = 0,
        evictedChunkCount: Int = 0,
        createdRecordCount: Int = 0,
        updatedRecordCount: Int = 0,
        reusedRecordCount: Int = 0,
        isFullRebuild: Bool = false
    ) {
        self.previousCenterChunkCoord = previousCenterChunkCoord
        self.currentCenterChunkCoord = currentCenterChunkCoord
        self.addedChunkCount = max(0, addedChunkCount)
        self.keptChunkCount = max(0, keptChunkCount)
        self.evictedChunkCount = max(0, evictedChunkCount)
        self.createdRecordCount = max(0, createdRecordCount)
        self.updatedRecordCount = max(0, updatedRecordCount)
        self.reusedRecordCount = max(0, reusedRecordCount)
        self.isFullRebuild = isFullRebuild
    }

    init(
        previousCenterChunkCoord: WorldChunkCoord?,
        currentCenterChunkCoord: WorldChunkCoord,
        previousChunkIDs: Set<WorldChunkID>,
        currentChunkIDs: Set<WorldChunkID>,
        mutationSummary: WorldCacheMutationSummary
    ) {
        let kept = previousChunkIDs.intersection(currentChunkIDs).count
        self.init(
            previousCenterChunkCoord: previousCenterChunkCoord,
            currentCenterChunkCoord: currentCenterChunkCoord,
            addedChunkCount: currentChunkIDs.subtracting(previousChunkIDs).count,
            keptChunkCount: kept,
            evictedChunkCount: previousChunkIDs.subtracting(currentChunkIDs).count,
            createdRecordCount: mutationSummary.createdCount,
            updatedRecordCount: mutationSummary.updatedCount,
            reusedRecordCount: mutationSummary.reusedCount,
            isFullRebuild: previousChunkIDs.isEmpty ? true : kept == 0 && currentChunkIDs.isEmpty == false
        )
    }

    var label: String {
        "add \(addedChunkCount) keep \(keptChunkCount) evict \(evictedChunkCount)"
    }
}

struct TelluricRuntimeWorldScale: Hashable {
    let metersPerSample: Float
    let chunkSampleSpan: Int
    let terrainVerticalScale: Float
    let renderVerticalScale: Float
    let playerHeightMeters: Float
    let playerRadiusMeters: Float
    let defaultCameraDistance: Float
    let defaultCameraPitch: Float

    init(
        layout: TerrainChunkLayout,
        metersPerSample: Float = 1,
        terrainVerticalScale: Float = 1,
        renderVerticalScale: Float = 1,
        playerHeightMeters: Float = 1.8,
        playerRadiusMeters: Float = 0.45,
        defaultCameraDistance: Float = 42,
        defaultCameraPitch: Float = 0.72
    ) {
        self.metersPerSample = metersPerSample.isFinite ? max(metersPerSample, 0.05) : 1
        self.chunkSampleSpan = layout.chunkSampleSpan
        self.terrainVerticalScale = terrainVerticalScale.isFinite ? max(terrainVerticalScale, 0.05) : 1
        self.renderVerticalScale = renderVerticalScale.isFinite ? max(renderVerticalScale, 0.05) : 1
        self.playerHeightMeters = playerHeightMeters.isFinite ? max(playerHeightMeters, 0.5) : 1.8
        self.playerRadiusMeters = playerRadiusMeters.isFinite ? max(playerRadiusMeters, 0.1) : 0.45
        self.defaultCameraDistance = defaultCameraDistance.isFinite ? max(defaultCameraDistance, 8) : 42
        self.defaultCameraPitch = defaultCameraPitch.isFinite ? max(0.15, min(defaultCameraPitch, 1.35)) : 0.72
    }

    var chunkWorldSizeMeters: Float {
        Float(chunkSampleSpan) * metersPerSample
    }

    var chunkSizeMeters: Float {
        chunkWorldSizeMeters
    }

    static func playableCloseFollowScale(for layout: TerrainChunkLayout) -> Float {
        let worldScale = TelluricRuntimeWorldScale(layout: layout)
        return max(24, min(worldScale.chunkWorldSizeMeters * 1.15, 44))
    }
}

struct TelluricRuntimeSceneState {
    let playerPosition: TerrainWorldPosition
    let playerWalkability: TerrainWalkability
    let isGrounded: Bool
    let centerChunkCoord: WorldChunkCoord
    let playerChunkCoord: WorldChunkCoord
    let lastResidencyRequest: WorldResidencyRequest?
    let lastPlan: WorldResidencyPlan?
    let lastBuildResult: ChunkBuildResult?
    let snapshot: ResidentWorldSnapshot?
    let cameraState: MetalDebugCameraState
    let inputState: TelluricGameInputState
    let renderMeshDescriptors: [MetalTerrainMeshDescriptor]
    let worldScale: TelluricRuntimeWorldScale
    let rebuildCount: Int
    let centerChunkChangeCount: Int
    let streamingUpdateSummary: TelluricRuntimeStreamingUpdateSummary
    let isDebugOverlayEnabled: Bool
}

struct TelluricRuntimeScene {
    let state: TelluricRuntimeSceneState

    var hasVisibleTerrain: Bool {
        state.renderMeshDescriptors.isEmpty == false
    }

    var hasVisiblePlayer: Bool {
        state.isGrounded && state.playerPosition.y.isFinite
    }
}
