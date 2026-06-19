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
    @Published var isViewportPickingEnabled: Bool
    @Published var debugNormalLength: Float
    @Published private(set) var debugCameraState: MetalDebugCameraState
    @Published private(set) var selectedChunkCoord: WorldChunkCoord?
    @Published private(set) var terrainInspectionState: TelluricTerrainInspectionState?

    let generatorVersion: TerrainGeneratorVersion
    let layout: TerrainChunkLayout
    let config: WorldResidencyConfig

    private let planner: WorldResidencyPlanner
    private let pipeline: ChunkBuildPipeline
    private let cameraController: MetalDebugCameraController
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
        self.isViewportPickingEnabled = true
        self.debugNormalLength = 2.0
        self.debugCameraState = cameraController.reset(bounds: nil)

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

    func zoomDebugCameraIn() {
        debugCameraState = cameraController.zoom(debugCameraState, delta: -0.18)
    }

    func zoomDebugCameraOut() {
        debugCameraState = cameraController.zoom(debugCameraState, delta: 0.22)
    }

    func rotateDebugCameraLeft() {
        debugCameraState = cameraController.orbit(debugCameraState, deltaYaw: -0.18, deltaPitch: 0)
    }

    func rotateDebugCameraRight() {
        debugCameraState = cameraController.orbit(debugCameraState, deltaYaw: 0.18, deltaPitch: 0)
    }

    func pitchDebugCameraUp() {
        debugCameraState = cameraController.orbit(debugCameraState, deltaYaw: 0, deltaPitch: 0.10)
    }

    func pitchDebugCameraDown() {
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
        debugCameraState = cameraController.reset(bounds: nil)
    }

    func fitDebugCameraToTerrain() {
        let bounds = debugTerrainMeshDescriptors.map(\.meshPayload.bounds)
        debugCameraState = cameraController.reset(bounds: bounds.isEmpty ? nil : bounds)
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
        debugCameraState = cameraController.zoom(debugCameraState, delta: -deltaY * 0.035)
    }

    func orbitDebugCameraFromDrag(deltaX: Float, deltaY: Float) {
        debugCameraState = cameraController.orbit(
            debugCameraState,
            deltaYaw: deltaX * 0.008,
            deltaPitch: -deltaY * 0.006
        )
    }

    func panDebugCameraFromDrag(deltaX: Float, deltaY: Float) {
        let scale = max(debugCameraState.orthographicScale, 1) * 0.004
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
        debugCameraState = cameraController.pan(debugCameraState, dx: dx, dz: dz)
    }

    private static func hashLabel(_ value: UInt64?) -> String {
        guard let value else {
            return "none"
        }
        return "0x" + String(value, radix: 16, uppercase: true)
    }
}
