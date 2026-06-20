import EngineCore
import RenderCoreMetal

typealias TelluricRuntimeSceneController = TelluricGameRuntimeModel

struct TelluricRuntimeWorldScale: Hashable {
    let metersPerSample: Float
    let chunkSampleSpan: Int

    init(
        layout: TerrainChunkLayout,
        metersPerSample: Float = 1
    ) {
        self.metersPerSample = metersPerSample.isFinite ? max(metersPerSample, 0.05) : 1
        self.chunkSampleSpan = layout.chunkSampleSpan
    }

    var chunkWorldSizeMeters: Float {
        Float(chunkSampleSpan) * metersPerSample
    }

    static func playableCloseFollowScale(for layout: TerrainChunkLayout) -> Float {
        let worldScale = TelluricRuntimeWorldScale(layout: layout)
        return max(34, min(worldScale.chunkWorldSizeMeters * 1.65, 72))
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
