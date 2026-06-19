import Combine
import EngineCore
import RenderCoreMetal
import SwiftUI

struct TelluricDebugChunkCell: Identifiable, Hashable {
    let coord: WorldChunkCoord
    let lifecycleState: ChunkLifecycleState
    let payloadState: CachedChunkPayloadState?
    let priorityRank: Int?
    let isCached: Bool
    let isCenter: Bool
    let isSelected: Bool

    var id: String {
        "\(coord.x):\(coord.z)"
    }

    var stateLabel: String {
        switch lifecycleState {
        case .active:
            return "active"
        case .resident:
            return "resident"
        case .meshed, .meshRequested:
            return "meshed"
        case .sampled, .sampleRequested:
            return "sampled"
        case .evictionCandidate:
            return "evict"
        case .unloaded:
            return "none"
        }
    }

    var payloadLabel: String {
        guard let payloadState else {
            return isCached ? "cached" : "absent"
        }

        switch payloadState {
        case .empty:
            return "empty"
        case .sampled:
            return "sample"
        case .meshed:
            return "mesh"
        case .resident:
            return "resident"
        case .active:
            return "active"
        case .evictionCandidate:
            return "evict"
        }
    }
}

struct TelluricDebugChunkGridRow: Identifiable, Hashable {
    let z: Int32
    let cells: [TelluricDebugChunkCell]

    var id: Int32 {
        z
    }
}

@MainActor
final class TelluricDebugRuntimeModel: ObservableObject {
    @Published private(set) var seed: UInt64
    @Published private(set) var centerChunkCoord: WorldChunkCoord
    @Published private(set) var lastPlan: WorldResidencyPlan?
    @Published private(set) var lastBuildResult: ChunkBuildResult?
    @Published private(set) var snapshot: ResidentWorldSnapshot?
    @Published private(set) var errorMessage: String?
    @Published var debugTerrainColorMode: MetalDebugTerrainColorMode
    @Published var isWireframeEnabled: Bool
    @Published var showsBounds: Bool
    @Published var showsNormals: Bool
    @Published var showsGrid: Bool
    @Published var showsPickedPoint: Bool
    @Published var showsPlayerProbe: Bool
    @Published var isViewportPickingEnabled: Bool
    @Published var debugNormalLength: Float
    @Published var debugVerticalScale: Float
    @Published var playerProbeStepMeters: Float
    @Published private(set) var currentCameraPreset: TelluricDebugCameraPreset
    @Published private(set) var debugCameraState: MetalDebugCameraState
    @Published private(set) var selectedChunkCoord: WorldChunkCoord?
    @Published private(set) var terrainInspectionState: TelluricTerrainInspectionState?
    @Published private(set) var playerProbe: TerrainProbe?

    let generatorVersion: TerrainGeneratorVersion
    let layout: TerrainChunkLayout
    let config: WorldResidencyConfig

    private let planner: WorldResidencyPlanner
    private let pipeline: ChunkBuildPipeline
    private let cameraController: MetalDebugCameraController
    private let debugWalkabilityConfig: TerrainWalkabilityConfig
    private var cache: InMemoryWorldCache

    init(
        seed: UInt64 = 20_260_619,
        generatorVersion: TerrainGeneratorVersion = .phase1,
        layout: TerrainChunkLayout = TerrainChunkLayout(samplesPerAxis: 9),
        config: WorldResidencyConfig = WorldResidencyConfig(
            activeRadiusChunks: 0,
            residentRadiusChunks: 1,
            meshRadiusChunks: 2,
            sampleRadiusChunks: 3,
            evictionRadiusChunks: 4
        ),
        centerChunkCoord: WorldChunkCoord = WorldChunkCoord(x: 0, z: 0)
    ) {
        self.seed = seed
        self.generatorVersion = generatorVersion
        self.layout = layout
        self.config = config
        self.centerChunkCoord = centerChunkCoord
        self.planner = WorldResidencyPlanner()
        self.pipeline = ChunkBuildPipeline()
        self.cameraController = MetalDebugCameraController()
        self.cache = InMemoryWorldCache()
        self.debugTerrainColorMode = .mixed
        self.isWireframeEnabled = false
        self.showsBounds = false
        self.showsNormals = false
        self.showsGrid = false
        self.showsPickedPoint = true
        self.showsPlayerProbe = true
        self.isViewportPickingEnabled = true
        self.debugNormalLength = 2.0
        self.debugVerticalScale = 0.25
        self.playerProbeStepMeters = 1.0
        self.currentCameraPreset = .isometric
        self.debugWalkabilityConfig = TerrainWalkabilityConfig(
            maxWalkableSlopeDegrees: 88,
            mudIsWalkable: true,
            shallowWaterIsWalkable: false
        )
        self.debugCameraState = MetalDebugCameraState()

        rebuild(fitCamera: true)
    }

    var centerLabel: String {
        "(\(centerChunkCoord.x), \(centerChunkCoord.z))"
    }

    var generatorVersionLabel: String {
        "\(generatorVersion.major).\(generatorVersion.minor).\(generatorVersion.patch)"
    }

    var planHashLabel: String {
        Self.hashLabel(lastPlan?.stableHash)
    }

    var snapshotHashLabel: String {
        Self.hashLabel(snapshot?.stableHash)
    }

    var cacheHashLabel: String {
        Self.hashLabel(snapshot?.cacheHash)
    }

    var totalRecords: Int {
        snapshot?.stats.totalRecords ?? 0
    }

    var sampleOnlyRecords: Int {
        snapshot?.records.filter { $0.samplePayload != nil && $0.meshPayload == nil }.count ?? 0
    }

    var meshedRecords: Int {
        snapshot?.stats.meshPayloadRecords ?? 0
    }

    var residentRecords: Int {
        snapshot?.stats.residentRecords ?? 0
    }

    var activeRecords: Int {
        snapshot?.stats.activeRecords ?? 0
    }

    var debugDisplayOptions: MetalDebugTerrainDisplayOptions {
        MetalDebugTerrainDisplayOptions(
            colorMode: debugTerrainColorMode,
            isWireframeEnabled: isWireframeEnabled,
            showsBounds: showsBounds,
            verticalScale: safeDebugVerticalScale,
            normals: MetalDebugNormalsConfiguration(
                isEnabled: showsNormals,
                stride: 8,
                length: debugNormalLength
            ),
            grid: MetalDebugGridConfiguration(
                isEnabled: showsGrid
            ),
            pickedPointMarker: MetalDebugPickedPointMarkerConfiguration(
                isEnabled: showsPickedPoint
            ),
            probeMarker: MetalDebugProbeMarkerConfiguration(
                isEnabled: showsPlayerProbe,
                radius: 3.5,
                height: 20
            )
        )
    }

    var selectedChunkRecord: CachedChunkRecord? {
        guard let selectedChunkCoord else {
            return nil
        }
        return snapshot?.records.first { $0.chunkCoord == selectedChunkCoord }
    }

    var selectedChunkTarget: ChunkLifecycleTarget? {
        guard let selectedChunkCoord else {
            return nil
        }
        return lastPlan?.target(for: selectedChunkCoord)
    }

    var selectedChunkLabel: String {
        guard let selectedChunkCoord else {
            return "none"
        }
        return "(\(selectedChunkCoord.x), \(selectedChunkCoord.z))"
    }

    var pickedWorldPoint: MetalDebugWorldPoint? {
        terrainInspectionState?.pickedWorldPoint
    }

    var playerProbeWorldPoint: MetalDebugWorldPoint? {
        guard showsPlayerProbe, let playerProbe else {
            return nil
        }
        return MetalDebugWorldPoint(
            x: playerProbe.worldPosition.x,
            y: playerProbe.worldPosition.y,
            z: playerProbe.worldPosition.z
        )
    }

    var playerProbePositionLabel: String {
        guard let probe = playerProbe else {
            return "none"
        }
        return String(
            format: "%.2f, %.2f, %.2f",
            Double(probe.worldPosition.x),
            Double(probe.worldPosition.y),
            Double(probe.worldPosition.z)
        )
    }

    var currentCameraPresetLabel: String {
        currentCameraPreset.label
    }

    var sanityDebugPresetLabel: String {
        String(format: "on, vertical %.2f", Double(safeDebugVerticalScale))
    }

    var isTerrainVisible: Bool {
        debugTerrainMeshCount > 0
    }

    var isProbeVisible: Bool {
        showsPlayerProbe && playerProbeWorldPoint != nil
    }

    var probeWalkabilityLabel: String {
        guard let playerProbe else {
            return "none"
        }
        return Self.walkabilityLabel(playerProbe.walkability)
    }

    var pickedTerrainPointLabel: String {
        guard let pickedWorldPoint else {
            return "none"
        }
        return String(
            format: "%.2f, %.2f, %.2f",
            Double(pickedWorldPoint.position.x),
            Double(pickedWorldPoint.position.y),
            Double(pickedWorldPoint.position.z)
        )
    }

    var selectedChunkStatusLabel: String {
        selectedChunkLabel
    }

    var isCameraPossiblyEdgeOn: Bool {
        debugCameraState.pitchRadians < 0.28
    }

    var debugWarnings: [String] {
        var warnings: [String] = []

        if isTerrainVisible == false {
            warnings.append("No terrain mesh visible")
        }

        if let result = playerProbe?.lastQueryResult {
            if result.isInsideKnownTerrain == false || result.walkability.reason == .outsideKnownTerrain {
                warnings.append("Probe outside known terrain")
            }
            if result.slopeDegrees > 60 {
                warnings.append("Extreme slope - terrain not playable here")
            }
        } else if showsPlayerProbe {
            warnings.append("Probe outside known terrain")
        }

        if isCameraPossiblyEdgeOn {
            warnings.append("Camera angle may hide terrain")
        }

        return warnings
    }

    var debugTerrainMeshDescriptors: [MetalTerrainMeshDescriptor] {
        (snapshot?.records ?? []).compactMap { record in
            guard let meshPayload = record.meshPayload else {
                return nil
            }

            return MetalTerrainMeshDescriptor(
                meshPayload: meshPayload,
                chunkID: record.chunkID,
                lifecycleState: record.lifecycleState,
                payloadState: record.payloadState,
                colorMode: debugTerrainColorMode,
                isSelected: record.chunkCoord == selectedChunkCoord,
                debugName: "chunk-\(record.chunkCoord.x)-\(record.chunkCoord.z)"
            )
        }
    }

    var debugTerrainMeshCount: Int {
        debugTerrainMeshDescriptors.count
    }

    var debugTerrainMeshHash: UInt64 {
        let records = snapshot?.records ?? []
        var state = StableHasher.hash(seed: 0x7E11_571C_D3B6_0001, UInt64(records.count))

        for record in records {
            guard let meshPayload = record.meshPayload else {
                continue
            }

            state = StableHasher.combine(state, record.chunkID.stableHash)
            state = StableHasher.combine(state, record.lifecycleState.stableHash)
            state = StableHasher.combine(state, record.payloadState.stableHash)
            state = StableHasher.combine(state, meshPayload.stableHash)
            state = StableHasher.combine(state, record.chunkCoord == selectedChunkCoord ? 1 : 0)
        }

        return StableHasher.combine(state, UInt64(debugTerrainMeshCount))
    }

    var debugMeshUploadHash: UInt64 {
        var state = StableHasher.combine(debugTerrainMeshHash, debugDisplayOptions.stableDebugID)
        state = StableHasher.combine(state, selectedChunkCoord?.stableHash ?? 0)
        state = StableHasher.combine(state, selectedChunkCoord == nil ? 0 : 1)
        state = StableHasher.combine(state, terrainInspectionState?.stableDebugID ?? 0)
        state = StableHasher.combine(state, playerProbe?.stableHash ?? 0)
        state = StableHasher.combine(state, playerProbe == nil ? 0 : 1)
        state = StableHasher.combine(state, showsPlayerProbe ? 1 : 0)
        return state
    }

    var gridRows: [TelluricDebugChunkGridRow] {
        let radius = config.evictionRadiusChunks
        let targetsByCoord = Dictionary(uniqueKeysWithValues: (lastPlan?.targets ?? []).map { ($0.chunkCoord, $0) })
        let recordsByCoord = Dictionary(uniqueKeysWithValues: (snapshot?.records ?? []).map { ($0.chunkCoord, $0) })
        let centerX = Int(centerChunkCoord.x)
        let centerZ = Int(centerChunkCoord.z)

        return stride(from: centerZ + radius, through: centerZ - radius, by: -1).map { z in
            let cells = ((centerX - radius)...(centerX + radius)).map { x in
                let coord = WorldChunkCoord(x: Int32(x), z: Int32(z))
                let target = targetsByCoord[coord]
                let record = recordsByCoord[coord]
                return TelluricDebugChunkCell(
                    coord: coord,
                    lifecycleState: record?.lifecycleState ?? target?.targetState ?? .unloaded,
                    payloadState: record?.payloadState,
                    priorityRank: record?.priority.rank ?? target?.priority.rank,
                    isCached: record != nil,
                    isCenter: coord == centerChunkCoord,
                    isSelected: coord == selectedChunkCoord
                )
            }

            return TelluricDebugChunkGridRow(z: Int32(z), cells: cells)
        }
    }

    func rebuild() {
        rebuild(fitCamera: false)
    }

    private func rebuild(fitCamera: Bool) {
        do {
            let request = WorldResidencyRequest(
                worldSeed: WorldSeed(seed),
                generatorVersion: generatorVersion,
                centerWorldPosition: TEVec3f(
                    x: Float(Int(centerChunkCoord.x) * layout.chunkSampleSpan),
                    y: 0,
                    z: Float(Int(centerChunkCoord.z) * layout.chunkSampleSpan)
                ),
                centerChunkCoord: centerChunkCoord,
                layout: layout,
                config: config
            )
            let plan = try planner.makePlan(request)
            let result = try pipeline.apply(plan: plan, cache: &cache)

            lastPlan = plan
            lastBuildResult = result
            snapshot = result.snapshot
            refreshPlayerProbe(resetIfMissing: true)
            if fitCamera {
                fitDebugCameraToTerrain()
            }
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func moveNorth() {
        move(dx: 0, dz: 1)
    }

    func moveSouth() {
        move(dx: 0, dz: -1)
    }

    func moveEast() {
        move(dx: 1, dz: 0)
    }

    func moveWest() {
        move(dx: -1, dz: 0)
    }

    func reset() {
        centerChunkCoord = WorldChunkCoord(x: 0, z: 0)
        selectedChunkCoord = nil
        terrainInspectionState = nil
        playerProbe = nil
        cache = InMemoryWorldCache()
        rebuild(fitCamera: true)
    }

    func selectChunk(_ coord: WorldChunkCoord) {
        selectedChunkCoord = coord
        terrainInspectionState = TelluricTerrainInspectionState(
            source: .grid,
            result: nil,
            selectedCoord: coord
        )
    }

    func clearSelection() {
        selectedChunkCoord = nil
        terrainInspectionState = nil
    }

    func setDebugTerrainColorMode(_ colorMode: MetalDebugTerrainColorMode) {
        debugTerrainColorMode = colorMode
    }

    func applyDebugCameraPreset(_ preset: TelluricDebugCameraPreset) {
        currentCameraPreset = preset
        debugCameraState = makeReadableCameraState(preset: preset)
    }

    func resetPlayerProbe() {
        guard let terrain = makeTerrainQueryEngine() else {
            placePlayerProbe(
                worldX: centerWorldX + Float(layout.chunkSampleSpan) * 0.5,
                worldZ: centerWorldZ + Float(layout.chunkSampleSpan) * 0.5
            )
            return
        }
        let coordinate = defaultProbeStartCoordinate(terrain: terrain)
        placePlayerProbe(worldX: coordinate.x, worldZ: coordinate.z)
    }

    func movePlayerProbeNorth() {
        movePlayerProbe(deltaX: 0, deltaZ: playerProbeStepMeters)
    }

    func movePlayerProbeSouth() {
        movePlayerProbe(deltaX: 0, deltaZ: -playerProbeStepMeters)
    }

    func movePlayerProbeEast() {
        movePlayerProbe(deltaX: playerProbeStepMeters, deltaZ: 0)
    }

    func movePlayerProbeWest() {
        movePlayerProbe(deltaX: -playerProbeStepMeters, deltaZ: 0)
    }

    func movePlayerProbeToPickedPoint() {
        guard let pickedWorldPoint else {
            return
        }
        placePlayerProbe(
            worldX: pickedWorldPoint.position.x,
            worldZ: pickedWorldPoint.position.z
        )
    }

    func zoomDebugCameraIn() {
        currentCameraPreset = .custom
        debugCameraState = cameraController.zoom(debugCameraState, delta: -0.18)
    }

    func zoomDebugCameraOut() {
        currentCameraPreset = .custom
        debugCameraState = cameraController.zoom(debugCameraState, delta: 0.22)
    }

    func rotateDebugCameraLeft() {
        currentCameraPreset = .custom
        debugCameraState = cameraController.orbit(debugCameraState, deltaYaw: -0.18, deltaPitch: 0)
    }

    func rotateDebugCameraRight() {
        currentCameraPreset = .custom
        debugCameraState = cameraController.orbit(debugCameraState, deltaYaw: 0.18, deltaPitch: 0)
    }

    func pitchDebugCameraUp() {
        currentCameraPreset = .custom
        debugCameraState = cameraController.orbit(debugCameraState, deltaYaw: 0, deltaPitch: 0.10)
    }

    func pitchDebugCameraDown() {
        currentCameraPreset = .custom
        debugCameraState = cameraController.orbit(debugCameraState, deltaYaw: 0, deltaPitch: -0.10)
    }

    func panDebugCameraNorth() {
        panDebugCamera(dx: 0, dz: cameraPanStep)
    }

    func panDebugCameraSouth() {
        panDebugCamera(dx: 0, dz: -cameraPanStep)
    }

    func panDebugCameraEast() {
        panDebugCamera(dx: cameraPanStep, dz: 0)
    }

    func panDebugCameraWest() {
        panDebugCamera(dx: -cameraPanStep, dz: 0)
    }

    func resetDebugCamera() {
        currentCameraPreset = .isometric
        debugCameraState = makeReadableCameraState(preset: .isometric)
    }

    func fitDebugCameraToTerrain() {
        let preset = currentCameraPreset == .custom ? TelluricDebugCameraPreset.isometric : currentCameraPreset
        currentCameraPreset = preset
        debugCameraState = makeReadableCameraState(preset: preset)
    }

    func focusDebugCameraOnProbe() {
        guard let playerProbe else {
            return
        }

        var next = debugCameraState
        next.target = SIMD3<Float>(
            playerProbe.worldPosition.x,
            playerProbe.worldPosition.y * safeDebugVerticalScale,
            playerProbe.worldPosition.z
        )
        next.orthographicScale = max(24, min(debugCameraState.orthographicScale, 64))
        next.distance = max(next.orthographicScale * 1.8, 96)
        next.farZ = max(next.orthographicScale * 8, 2_000)
        currentCameraPreset = .custom
        debugCameraState = next
    }

    func applyViewportPick(_ result: MetalDebugPickingResult) {
        terrainInspectionState = TelluricTerrainInspectionState(
            source: .click,
            result: result,
            selectedCoord: result.hit?.chunkCoord ?? selectedChunkCoord
        )

        if let coord = result.hit?.chunkCoord {
            selectedChunkCoord = coord
        }
    }

    func applyViewportHover(_ result: MetalDebugPickingResult) {
        terrainInspectionState = TelluricTerrainInspectionState(
            source: .hover,
            result: result,
            selectedCoord: selectedChunkCoord
        )
    }

    func zoomDebugCameraFromScroll(deltaY: Float) {
        currentCameraPreset = .custom
        debugCameraState = cameraController.zoom(debugCameraState, delta: -deltaY * 0.035)
    }

    func orbitDebugCameraFromDrag(deltaX: Float, deltaY: Float) {
        currentCameraPreset = .custom
        debugCameraState = cameraController.orbit(
            debugCameraState,
            deltaYaw: deltaX * 0.008,
            deltaPitch: -deltaY * 0.006
        )
    }

    func panDebugCameraFromDrag(deltaX: Float, deltaY: Float) {
        let scale = max(debugCameraState.orthographicScale, 1) * 0.004
        currentCameraPreset = .custom
        panDebugCamera(dx: -deltaX * scale, dz: deltaY * scale)
    }

    private func move(dx: Int, dz: Int) {
        let nextX = Int(centerChunkCoord.x) + dx
        let nextZ = Int(centerChunkCoord.z) + dz

        guard nextX >= Int(Int32.min), nextX <= Int(Int32.max),
              nextZ >= Int(Int32.min), nextZ <= Int(Int32.max)
        else {
            errorMessage = "Center chunk coordinate is outside Int32 range."
            return
        }

        centerChunkCoord = WorldChunkCoord(x: Int32(nextX), z: Int32(nextZ))
        rebuild(fitCamera: true)
    }

    private var cameraPanStep: Float {
        max(1, debugCameraState.orthographicScale * 0.12)
    }

    private func panDebugCamera(dx: Float, dz: Float) {
        currentCameraPreset = .custom
        debugCameraState = cameraController.pan(debugCameraState, dx: dx, dz: dz)
    }

    private var centerWorldX: Float {
        Float(Int(centerChunkCoord.x) * layout.chunkSampleSpan)
    }

    private var centerWorldZ: Float {
        Float(Int(centerChunkCoord.z) * layout.chunkSampleSpan)
    }

    private func makeTerrainQueryEngine() -> TerrainQueryEngine? {
        guard let snapshot else {
            return nil
        }
        return TerrainQueryEngine(
            snapshot: snapshot,
            walkabilityConfig: debugWalkabilityConfig
        )
    }

    private func refreshPlayerProbe(resetIfMissing: Bool) {
        guard let terrain = makeTerrainQueryEngine() else {
            playerProbe = nil
            return
        }

        let controller = TerrainProbeController()
        if let playerProbe {
            self.playerProbe = controller.place(
                id: playerProbe.id,
                worldX: playerProbe.worldPosition.x,
                worldZ: playerProbe.worldPosition.z,
                terrain: terrain
            ).probe
        } else if resetIfMissing {
            let coordinate = defaultProbeStartCoordinate(terrain: terrain)
            self.playerProbe = controller.place(
                worldX: coordinate.x,
                worldZ: coordinate.z,
                terrain: terrain
            ).probe
        }
    }

    private func placePlayerProbe(worldX: Float, worldZ: Float) {
        guard let terrain = makeTerrainQueryEngine() else {
            errorMessage = "No resident snapshot is available for terrain probe queries."
            return
        }

        let controller = TerrainProbeController()
        let result = controller.place(
            id: playerProbe?.id ?? 1,
            worldX: worldX,
            worldZ: worldZ,
            terrain: terrain
        )
        playerProbe = result.probe
        errorMessage = nil
    }

    private func movePlayerProbe(deltaX: Float, deltaZ: Float) {
        guard let terrain = makeTerrainQueryEngine() else {
            errorMessage = "No resident snapshot is available for terrain probe queries."
            return
        }

        let controller = TerrainProbeController()
        let probe: TerrainProbe
        if let playerProbe {
            probe = playerProbe
        } else {
            let coordinate = defaultProbeStartCoordinate(terrain: terrain)
            probe = controller.place(
                worldX: coordinate.x,
                worldZ: coordinate.z,
                terrain: terrain
            ).probe
        }
        let result = controller.move(
            probe: probe,
            request: TerrainProbeMoveRequest(deltaX: deltaX, deltaZ: deltaZ),
            terrain: terrain
        )
        playerProbe = result.probe
        errorMessage = nil
    }

    private func makeReadableCameraState(preset: TelluricDebugCameraPreset) -> MetalDebugCameraState {
        let bounds = displayScaledTerrainBounds()
        let base = cameraController.reset(bounds: bounds.isEmpty ? nil : bounds)
        let effectivePreset = preset == .custom ? TelluricDebugCameraPreset.isometric : preset
        let scale = max(base.orthographicScale, 48)

        switch effectivePreset {
        case .isometric:
            return MetalDebugCameraState(
                target: base.target,
                distance: max(scale * 1.7, 120),
                yawRadians: Float.pi * 0.25,
                pitchRadians: 0.72,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 8, 2_000)
            )
        case .topDown:
            return MetalDebugCameraState(
                target: base.target,
                distance: max(scale * 1.7, 120),
                yawRadians: 0,
                pitchRadians: 1.28,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 8, 2_000)
            )
        case .side:
            return MetalDebugCameraState(
                target: base.target,
                distance: max(scale * 1.9, 140),
                yawRadians: Float.pi * 0.5,
                pitchRadians: 0.24,
                zoomScale: 1,
                orthographicScale: scale,
                nearZ: 0.1,
                farZ: max(scale * 8, 2_000)
            )
        case .custom:
            return makeReadableCameraState(preset: .isometric)
        }
    }

    private func displayScaledTerrainBounds() -> [TerrainMeshBounds] {
        debugTerrainMeshDescriptors.map { descriptor in
            let bounds = descriptor.meshPayload.bounds
            return TerrainMeshBounds(
                min: TEVec3f(
                    x: bounds.min.x,
                    y: bounds.min.y * safeDebugVerticalScale,
                    z: bounds.min.z
                ),
                max: TEVec3f(
                    x: bounds.max.x,
                    y: bounds.max.y * safeDebugVerticalScale,
                    z: bounds.max.z
                )
            )
        }
    }

    private var safeDebugVerticalScale: Float {
        debugVerticalScale.isFinite ? max(debugVerticalScale, 0.05) : 0.25
    }

    private func defaultProbeStartCoordinate(terrain: TerrainQueryEngine) -> (x: Float, z: Float) {
        let center = (
            x: centerWorldX + Float(layout.chunkSampleSpan) * 0.5,
            z: centerWorldZ + Float(layout.chunkSampleSpan) * 0.5
        )
        let centerQuery = terrain.query(
            TerrainQueryRequest(worldX: center.x, worldZ: center.z)
        )
        if isReadableProbeQuery(centerQuery) {
            return center
        }

        let vertices = (snapshot?.records ?? [])
            .compactMap(\.meshPayload)
            .flatMap(\.vertices)
            .sorted { lhs, rhs in
                let lhsDistance = squaredDistanceXZ(lhs.position.x, lhs.position.z, center.x, center.z)
                let rhsDistance = squaredDistanceXZ(rhs.position.x, rhs.position.z, center.x, center.z)
                if lhsDistance != rhsDistance {
                    return lhsDistance < rhsDistance
                }
                if lhs.sampleCoord.x != rhs.sampleCoord.x {
                    return lhs.sampleCoord.x < rhs.sampleCoord.x
                }
                return lhs.sampleCoord.z < rhs.sampleCoord.z
            }

        for vertex in vertices {
            let query = terrain.query(
                TerrainQueryRequest(worldX: vertex.position.x, worldZ: vertex.position.z)
            )
            if isReadableProbeQuery(query) {
                return (vertex.position.x, vertex.position.z)
            }
        }

        for vertex in vertices {
            let query = terrain.query(
                TerrainQueryRequest(worldX: vertex.position.x, worldZ: vertex.position.z)
            )
            if query.isInsideKnownTerrain && query.walkability.isWalkable {
                return (vertex.position.x, vertex.position.z)
            }
        }

        return center
    }

    private func isReadableProbeQuery(_ query: TerrainQueryResult) -> Bool {
        guard query.isInsideKnownTerrain,
              query.walkability.isWalkable,
              query.slopeDegrees <= 60
        else {
            return false
        }

        guard let material = query.surface?.material else {
            return false
        }

        switch material {
        case .grass, .soil, .sand, .gravel, .snow:
            return true
        case .rock, .mud, .shallowWater:
            return false
        }
    }

    private func squaredDistanceXZ(_ lhsX: Float, _ lhsZ: Float, _ rhsX: Float, _ rhsZ: Float) -> Float {
        let dx = lhsX - rhsX
        let dz = lhsZ - rhsZ
        return dx * dx + dz * dz
    }

    private static func hashLabel(_ value: UInt64?) -> String {
        guard let value else {
            return "none"
        }
        return "0x" + String(value, radix: 16, uppercase: true)
    }

    private static func walkabilityLabel(_ walkability: TerrainWalkability) -> String {
        switch walkability.reason {
        case .walkable:
            return walkability.isWalkable ? "walkable" : "not walkable"
        case .tooSteep:
            return "too steep"
        case .water:
            return "water"
        case .mud:
            return walkability.isWalkable ? "mud walkable" : "mud blocked"
        case .unknown:
            return "unknown"
        case .outsideKnownTerrain:
            return "outside known terrain"
        }
    }
}
