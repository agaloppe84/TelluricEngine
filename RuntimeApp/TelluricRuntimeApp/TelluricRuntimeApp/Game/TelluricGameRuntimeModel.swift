import Combine
import EngineCore
import RenderCoreMetal
import SwiftUI

@MainActor
final class TelluricGameRuntimeModel: ObservableObject {
    @Published private(set) var playerPosition: TerrainWorldPosition
    @Published private(set) var playerWalkability: TerrainWalkability
    @Published private(set) var isGrounded: Bool
    @Published private(set) var centerChunkCoord: WorldChunkCoord
    @Published private(set) var playerChunkCoord: WorldChunkCoord
    @Published private(set) var snapshot: ResidentWorldSnapshot?
    @Published private(set) var lastResidencyRequest: WorldResidencyRequest?
    @Published private(set) var lastPlan: WorldResidencyPlan?
    @Published private(set) var lastBuildResult: ChunkBuildResult?
    @Published private(set) var cameraState: MetalDebugCameraState
    @Published private(set) var cameraMode: TelluricGameCameraMode
    @Published private(set) var lastInputSource: TelluricGameInputSource
    @Published private(set) var lastInputState: TelluricGameInputState
    @Published private(set) var playerProbe: TerrainProbe?
    @Published private(set) var rebuildCount: Int
    @Published private(set) var centerChunkChangeCount: Int
    @Published private(set) var lastStreamingUpdate: TelluricRuntimeStreamingUpdateSummary
    @Published var isDebugOverlayEnabled: Bool
    @Published var isWireframeEnabled: Bool
    @Published var showsBounds: Bool
    @Published var showsNormals: Bool
    @Published var showsChunkGrid: Bool
    @Published private(set) var errorMessage: String?

    let seed: UInt64
    let generatorVersion: TerrainGeneratorVersion
    let layout: TerrainChunkLayout
    let profile: TerrainGenerationProfile
    let config: WorldResidencyConfig
    let playerStepMeters: Float

    private let planner = WorldResidencyPlanner()
    private let pipeline = ChunkBuildPipeline()
    private let cameraController = MetalDebugCameraController()
    private var cache = InMemoryWorldCache()

    init(
        seed: UInt64 = 20_260_696,
        generatorVersion: TerrainGeneratorVersion = .phase1,
        layout: TerrainChunkLayout = TerrainChunkLayout(samplesPerAxis: 33),
        profile: TerrainGenerationProfile = .debugPlayable,
        config: WorldResidencyConfig = WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        ),
        startX: Float = 16,
        startZ: Float = 16,
        playerStepMeters: Float = 4
    ) {
        self.seed = seed
        self.generatorVersion = generatorVersion
        self.layout = layout
        self.profile = profile
        self.config = config
        self.playerStepMeters = playerStepMeters
        self.playerPosition = TerrainWorldPosition(x: startX, y: 0, z: startZ)
        self.playerWalkability = .unknown
        self.isGrounded = false
        let chunkCoord = Self.chunkCoord(forWorldX: startX, worldZ: startZ, layout: layout)
        self.centerChunkCoord = chunkCoord
        self.playerChunkCoord = chunkCoord
        self.cameraMode = .playableCloseFollow
        self.lastInputSource = .none
        self.lastInputState = .idle
        self.playerProbe = nil
        self.rebuildCount = 0
        self.centerChunkChangeCount = 0
        self.lastStreamingUpdate = TelluricRuntimeStreamingUpdateSummary(currentCenterChunkCoord: chunkCoord)
        self.isDebugOverlayEnabled = false
        self.isWireframeEnabled = false
        self.showsBounds = false
        self.showsNormals = false
        self.showsChunkGrid = false
        self.cameraState = Self.makeCameraState(
            mode: .playableCloseFollow,
            playerPosition: TerrainWorldPosition(x: startX, y: 0, z: startZ),
            orthographicScale: TelluricRuntimeWorldScale.playableCloseFollowScale(for: layout)
        )

        rebuildWorldAroundPlayer()
        snapPlayerToTerrain(worldX: startX, worldZ: startZ)
        updateCameraForPlayer()
    }

    var displayOptions: MetalDebugTerrainDisplayOptions {
        let worldScale = worldScale
        return MetalDebugTerrainDisplayOptions(
            colorMode: .surface,
            renderMode: .gamePreview,
            isWireframeEnabled: isDebugOverlayEnabled && isWireframeEnabled,
            showsBounds: isDebugOverlayEnabled && showsBounds,
            verticalScale: worldScale.renderVerticalScale,
            normals: MetalDebugNormalsConfiguration(
                isEnabled: isDebugOverlayEnabled && showsNormals,
                stride: 8,
                length: max(1.4, worldScale.playerHeightMeters * 1.2)
            ),
            grid: MetalDebugGridConfiguration(isEnabled: isDebugOverlayEnabled && showsChunkGrid),
            pickedPointMarker: MetalDebugPickedPointMarkerConfiguration(isEnabled: false),
            probeMarker: MetalDebugProbeMarkerConfiguration(isEnabled: false),
            playerMarker: MetalDebugPlayerMarkerConfiguration(
                isEnabled: true,
                radius: max(2.4, worldScale.playerRadiusMeters * 6),
                height: max(6.5, worldScale.playerHeightMeters * 4)
            )
        )
    }

    var runtimeScene: TelluricRuntimeScene {
        TelluricRuntimeScene(state: runtimeSceneState)
    }

    var runtimeSceneState: TelluricRuntimeSceneState {
        TelluricRuntimeSceneState(
            playerPosition: playerPosition,
            playerWalkability: playerWalkability,
            isGrounded: isGrounded,
            centerChunkCoord: centerChunkCoord,
            playerChunkCoord: playerChunkCoord,
            lastResidencyRequest: lastResidencyRequest,
            lastPlan: lastPlan,
            lastBuildResult: lastBuildResult,
            snapshot: snapshot,
            cameraState: cameraState,
            inputState: lastInputState,
            renderMeshDescriptors: meshDescriptors,
            worldScale: worldScale,
            rebuildCount: rebuildCount,
            centerChunkChangeCount: centerChunkChangeCount,
            streamingUpdateSummary: lastStreamingUpdate,
            isDebugOverlayEnabled: isDebugOverlayEnabled
        )
    }

    var worldScale: TelluricRuntimeWorldScale {
        TelluricRuntimeWorldScale(layout: layout)
    }

    var chunkWorldSizeMeters: Float {
        worldScale.chunkWorldSizeMeters
    }

    var metersPerSample: Float {
        worldScale.metersPerSample
    }

    var meshDescriptors: [MetalTerrainMeshDescriptor] {
        (snapshot?.records ?? []).compactMap { record in
            guard let meshPayload = record.meshPayload else {
                return nil
            }

            return MetalTerrainMeshDescriptor(
                meshPayload: meshPayload,
                chunkID: record.chunkID,
                lifecycleState: record.lifecycleState,
                payloadState: record.payloadState,
                colorMode: .surface,
                renderMode: .gamePreview,
                isSelected: record.chunkCoord == playerChunkCoord,
                debugName: "game-chunk-\(record.chunkCoord.x)-\(record.chunkCoord.z)"
            )
        }
    }

    var uploadHash: UInt64 {
        var state = StableHasher.hash(seed: 0x7E11_571C_9A6A_0001, displayOptions.stableDebugID)
        for descriptor in meshDescriptors {
            state = StableHasher.combine(state, descriptor.meshPayload.stableHash)
            state = StableHasher.combine(state, descriptor.lifecycleState.stableHash)
            state = StableHasher.combine(state, descriptor.isSelected ? 1 : 0)
        }
        state = StableHasher.combine(state, playerPosition.stableHash)
        return StableHasher.combine(state, UInt64(meshDescriptors.count))
    }

    var playerPoint: MetalDebugWorldPoint {
        MetalDebugWorldPoint(
            x: playerPosition.x,
            y: playerPosition.y,
            z: playerPosition.z
        )
    }

    var meshCount: Int {
        meshDescriptors.count
    }

    var residentChunkCount: Int {
        snapshot?.stats.residentRecords ?? 0
    }

    var activeChunkCount: Int {
        snapshot?.stats.activeRecords ?? 0
    }

    var visibleMeshChunkCount: Int {
        meshCount
    }

    var playerPositionLabel: String {
        String(
            format: "%.2f, %.2f, %.2f",
            Double(playerPosition.x),
            Double(playerPosition.y),
            Double(playerPosition.z)
        )
    }

    var centerChunkLabel: String {
        "(\(centerChunkCoord.x), \(centerChunkCoord.z))"
    }

    var playerChunkLabel: String {
        "(\(playerChunkCoord.x), \(playerChunkCoord.z))"
    }

    var walkabilityLabel: String {
        if isGrounded == false {
            return "outside"
        }
        return playerWalkability.isWalkable ? "walkable" : "\(playerWalkability.reason)"
    }

    var streamingUpdateLabel: String {
        lastStreamingUpdate.label
    }

    var debugOverlayStatusLabel: String {
        isDebugOverlayEnabled ? "on" : "off"
    }

    func toggleDebugOverlay() {
        isDebugOverlayEnabled.toggle()
    }

    func toggleWireframe() {
        isDebugOverlayEnabled = true
        isWireframeEnabled.toggle()
    }

    func toggleBounds() {
        isDebugOverlayEnabled = true
        showsBounds.toggle()
    }

    func toggleNormals() {
        isDebugOverlayEnabled = true
        showsNormals.toggle()
    }

    func toggleChunkGrid() {
        isDebugOverlayEnabled = true
        showsChunkGrid.toggle()
    }

    func applyKeyboardInput(_ input: TelluricGameInputState) {
        guard input.hasMovement else {
            lastInputSource = .keyboard
            lastInputState = TelluricGameInputState(moveX: 0, moveZ: 0, source: .keyboard)
            return
        }
        movePlayer(input: input)
    }

    func applyControllerInput(moveX: Float, moveZ: Float) {
        let input = TelluricGameInputState(
            moveX: moveX,
            moveZ: moveZ,
            source: .controller
        )
        guard input.hasMovement else {
            return
        }
        movePlayer(input: input)
    }

    func resetPlayer() {
        let startX = Float(Int(centerChunkCoord.x) * layout.chunkSampleSpan) + Float(layout.chunkSampleSpan) * 0.5
        let startZ = Float(Int(centerChunkCoord.z) * layout.chunkSampleSpan) + Float(layout.chunkSampleSpan) * 0.5
        snapPlayerToTerrain(worldX: startX, worldZ: startZ)
        updateCenterIfNeeded()
        updateCameraForPlayer()
    }

    func resetCamera() {
        cameraMode = .playableCloseFollow
        updateCameraForPlayer()
    }

    func setCameraMode(_ mode: TelluricGameCameraMode) {
        cameraMode = mode
        updateCameraForPlayer()
    }

    func zoomCameraIn() {
        cameraMode = .freeOrbit
        cameraState = cameraController.zoom(cameraState, delta: -0.15)
    }

    func zoomCameraOut() {
        cameraMode = .freeOrbit
        cameraState = cameraController.zoom(cameraState, delta: 0.18)
    }

    func rotateCameraLeft() {
        cameraMode = .freeOrbit
        cameraState = cameraController.orbit(cameraState, deltaYaw: -0.16, deltaPitch: 0)
    }

    func rotateCameraRight() {
        cameraMode = .freeOrbit
        cameraState = cameraController.orbit(cameraState, deltaYaw: 0.16, deltaPitch: 0)
    }

    func focusCameraOnPlayer() {
        cameraMode = .playableCloseFollow
        updateCameraForPlayer()
    }

    private func movePlayer(input: TelluricGameInputState) {
        let length = max(0.0001, (input.moveX * input.moveX + input.moveZ * input.moveZ).squareRoot())
        let dx = input.moveX / length * playerStepMeters
        let dz = input.moveZ / length * playerStepMeters
        movePlayer(deltaX: dx, deltaZ: dz, source: input.source)
    }

    func movePlayer(deltaX: Float, deltaZ: Float, source: TelluricGameInputSource) {
        let targetX = playerPosition.x + deltaX
        let targetZ = playerPosition.z + deltaZ
        let targetChunk = Self.chunkCoord(forWorldX: targetX, worldZ: targetZ, layout: layout)
        if targetChunk != centerChunkCoord {
            centerChunkCoord = targetChunk
            centerChunkChangeCount += 1
            rebuildWorldAroundPlayer()
        }

        snapPlayerToTerrain(worldX: targetX, worldZ: targetZ)
        lastInputSource = source
        lastInputState = TelluricGameInputState(moveX: deltaX, moveZ: deltaZ, source: source)
        updateCenterIfNeeded()
        updateCameraForPlayer()
    }

    func movePlayerTo(worldX: Float, worldZ: Float, source: TelluricGameInputSource) {
        let targetChunk = Self.chunkCoord(forWorldX: worldX, worldZ: worldZ, layout: layout)
        if targetChunk != centerChunkCoord {
            centerChunkCoord = targetChunk
            centerChunkChangeCount += 1
            rebuildWorldAroundPlayer()
        }
        snapPlayerToTerrain(worldX: worldX, worldZ: worldZ)
        lastInputSource = source
        lastInputState = TelluricGameInputState(moveX: 0, moveZ: 0, source: source)
        updateCenterIfNeeded()
        updateCameraForPlayer()
    }

    func resetRuntimeSlice() {
        centerChunkCoord = WorldChunkCoord(x: 0, z: 0)
        playerChunkCoord = centerChunkCoord
        centerChunkChangeCount = 0
        rebuildCount = 0
        lastStreamingUpdate = TelluricRuntimeStreamingUpdateSummary(currentCenterChunkCoord: centerChunkCoord)
        rebuildWorldAroundPlayer()
        resetPlayer()
        resetCamera()
    }

    private func snapPlayerToTerrain(worldX: Float, worldZ: Float) {
        guard let terrain = makeTerrainQueryEngine() else {
            playerPosition = TerrainWorldPosition(x: worldX, y: playerPosition.y, z: worldZ)
            playerWalkability = .unknown
            isGrounded = false
            return
        }

        let result = terrain.query(TerrainQueryRequest(worldX: worldX, worldZ: worldZ))
        playerPosition = result.worldPosition
        playerWalkability = result.walkability
        isGrounded = result.isInsideKnownTerrain
        playerProbe = TerrainProbe(
            id: 1,
            worldPosition: result.worldPosition,
            lastQueryResult: result,
            isGrounded: result.isInsideKnownTerrain,
            walkability: result.walkability
        )
        playerChunkCoord = Self.chunkCoord(forWorldX: worldX, worldZ: worldZ, layout: layout)
    }

    private func updateCenterIfNeeded() {
        let nextCenter = Self.chunkCoord(forWorldX: playerPosition.x, worldZ: playerPosition.z, layout: layout)
        guard nextCenter != centerChunkCoord else {
            return
        }
        centerChunkCoord = nextCenter
        centerChunkChangeCount += 1
        rebuildWorldAroundPlayer()
    }

    func rebuildWorldAroundPlayer() {
        do {
            let previousChunkIDs = Set(cache.records.map(\.chunkID))
            let previousCenter = lastResidencyRequest?.centerChunkCoord
            let request = WorldResidencyRequest(
                worldSeed: WorldSeed(seed),
                generatorVersion: generatorVersion,
                centerWorldPosition: TEVec3f(
                    x: playerPosition.x,
                    y: playerPosition.y,
                    z: playerPosition.z
                ),
                centerChunkCoord: centerChunkCoord,
                layout: layout,
                profile: profile,
                config: config
            )
            let plan = try planner.makePlan(request)
            let result = try pipeline.apply(plan: plan, cache: &cache)
            let currentChunkIDs = Set(result.snapshot.records.map(\.chunkID))
            lastResidencyRequest = request
            lastPlan = plan
            lastBuildResult = result
            snapshot = result.snapshot
            lastStreamingUpdate = TelluricRuntimeStreamingUpdateSummary(
                previousCenterChunkCoord: previousCenter,
                currentCenterChunkCoord: centerChunkCoord,
                previousChunkIDs: previousChunkIDs,
                currentChunkIDs: currentChunkIDs,
                mutationSummary: result.mutationSummary
            )
            rebuildCount += 1
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func makeTerrainQueryEngine() -> TerrainQueryEngine? {
        guard let snapshot else {
            return nil
        }
        return TerrainQueryEngine(snapshot: snapshot)
    }

    private func updateCameraForPlayer() {
        let scale = cameraState.orthographicScale.isFinite ? cameraState.orthographicScale : 72
        cameraState = Self.makeCameraState(
            mode: cameraMode,
            playerPosition: playerPosition,
            orthographicScale: scale
        )
    }

    private static func makeCameraState(
        mode: TelluricGameCameraMode,
        playerPosition: TerrainWorldPosition,
        orthographicScale: Float
    ) -> MetalDebugCameraState {
        let target = SIMD3<Float>(
            playerPosition.x,
            playerPosition.y,
            playerPosition.z
        )
        let scale = max(26, min(orthographicScale, 112))

        switch mode {
        case .playableCloseFollow:
            return MetalDebugCameraState(
                target: target,
                distance: max(scale * 1.05, 42),
                yawRadians: Float.pi * 0.25,
                pitchRadians: 0.72,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 5, 700)
            )
        case .followIso:
            return MetalDebugCameraState(
                target: target,
                distance: max(scale * 1.25, 58),
                yawRadians: Float.pi * 0.25,
                pitchRadians: 0.62,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 7, 1_000)
            )
        case .topDown:
            return MetalDebugCameraState(
                target: target,
                distance: max(scale * 1.18, 54),
                yawRadians: 0,
                pitchRadians: 1.28,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 7, 1_000)
            )
        case .freeOrbit:
            return MetalDebugCameraState(
                target: target,
                distance: max(scale * 1.25, 58),
                yawRadians: Float.pi * 0.25,
                pitchRadians: 0.62,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 7, 1_000)
            )
        }
    }

    private static func chunkCoord(
        forWorldX worldX: Float,
        worldZ: Float,
        layout: TerrainChunkLayout
    ) -> WorldChunkCoord {
        let span = Int64(layout.chunkSampleSpan)
        let sampleX = Int64(floor(Double(worldX)))
        let sampleZ = Int64(floor(Double(worldZ)))
        return WorldChunkCoord(
            x: Int32(clamping: floorDiv(sampleX, span)),
            z: Int32(clamping: floorDiv(sampleZ, span))
        )
    }

    private static func floorDiv(_ value: Int64, _ divisor: Int64) -> Int64 {
        var quotient = value / divisor
        let remainder = value % divisor
        if remainder < 0 {
            quotient -= 1
        }
        return quotient
    }
}
