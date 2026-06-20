//
//  TelluricRuntimeAppTests.swift
//  TelluricRuntimeAppTests
//
//  Created by Work on 19/06/2026.
//

import EngineCore
import RenderCoreMetal
import Testing
@testable import TelluricRuntimeApp

@MainActor
struct TelluricRuntimeAppTests {

    @Test func initialRebuildProducesNonEmptySnapshot() {
        let model = TelluricDebugRuntimeModel()

        #expect(model.snapshot != nil)
        #expect(model.totalRecords > 0)
        #expect(model.activeRecords == 1)
        #expect(model.gridRows.isEmpty == false)
    }

    @Test func moveEastChangesCenterChunk() {
        let model = TelluricDebugRuntimeModel()

        model.moveEast()

        #expect(model.centerLabel == "(1, 0)")
        #expect(model.snapshot != nil)
    }

    @Test func resetReturnsToOrigin() {
        let model = TelluricDebugRuntimeModel()

        model.moveNorth()
        model.moveEast()
        model.reset()

        #expect(model.centerLabel == "(0, 0)")
        #expect(model.activeRecords == 1)
    }

    @Test func repeatedRebuildIsDeterministic() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.snapshot?.stableHash

        model.rebuild()
        let secondHash = model.snapshot?.stableHash

        #expect(firstHash != nil)
        #expect(firstHash == secondHash)
    }

    @Test func statsMatchSnapshot() {
        let model = TelluricDebugRuntimeModel()
        let stats = model.snapshot?.stats

        #expect(model.totalRecords == stats?.totalRecords)
        #expect(model.meshedRecords == stats?.meshPayloadRecords)
        #expect(model.residentRecords == stats?.residentRecords)
        #expect(model.activeRecords == stats?.activeRecords)
    }

    @Test func debugTerrainMeshesAreExposedAfterRebuild() {
        let model = TelluricDebugRuntimeModel()

        #expect(model.debugTerrainMeshDescriptors.isEmpty == false)
        #expect(model.debugTerrainMeshCount == model.meshedRecords)
        #expect(model.debugTerrainMeshDescriptors.allSatisfy { $0.meshPayload.indices.isEmpty == false })
    }

    @Test func debugTerrainMeshExportIsDeterministicAcrossRebuilds() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.debugTerrainMeshHash
        let firstCount = model.debugTerrainMeshCount

        model.rebuild()

        #expect(model.debugTerrainMeshHash == firstHash)
        #expect(model.debugTerrainMeshCount == firstCount)
    }

    @Test func movingCenterChangesDebugTerrainMeshHash() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.debugTerrainMeshHash

        model.moveEast()

        #expect(model.debugTerrainMeshHash != firstHash)
        #expect(model.debugTerrainMeshDescriptors.isEmpty == false)
    }

    @Test func runtimeTargetCanReferenceRenderCoreMetalTypes() {
        #expect(RenderCoreMetalInfo.moduleName == "RenderCoreMetal")
        #expect(RenderCoreMetalInfo.phase6Status == "metal-debug-terrain-renderer")
        #expect(RenderCoreMetalInfo.phase7Status == "runtime-camera-debug-controls")
        #expect(RenderCoreMetalInfo.phase8Status == "terrain-debug-picking-refinement")
        #expect(RenderCoreMetalInfo.phase9Status == "terrain-query-player-probe-debug-marker")
        #expect(RenderCoreMetalInfo.phase9_5Status == "debug-runtime-usability-fix")
        #expect(RenderCoreMetalInfo.phase9_6Status == "playable-runtime-slice-debug-separation")
    }

    @Test func renderCoreMetalCPUConversionMatchesDebugMeshPayload() throws {
        let model = TelluricDebugRuntimeModel()
        let descriptor = try #require(model.debugTerrainMeshDescriptors.first)

        let vertices = try MetalTerrainMeshUploader.makeMetalVertices(descriptor: descriptor)

        #expect(vertices.count == descriptor.meshPayload.vertices.count)
        #expect(descriptor.meshPayload.indices.isEmpty == false)
        #expect(vertices.first?.color.w == Float(1))
    }

    @Test func initialDebugModelHasDefaultRenderSettings() {
        let model = TelluricDebugRuntimeModel()

        #expect(model.debugTerrainColorMode == .mixed)
        #expect(model.isWireframeEnabled == false)
        #expect(model.showsBounds == false)
        #expect(model.showsNormals == false)
        #expect(model.currentCameraPreset == .isometric)
        #expect(model.debugDisplayOptions.verticalScale == 0.25)
        #expect(model.debugDisplayOptions.colorMode == .mixed)
    }

    @Test func defaultCameraPresetIsReadable() {
        let model = TelluricDebugRuntimeModel()

        #expect(model.currentCameraPreset == .isometric)
        #expect(model.debugCameraState.pitchRadians > 0.5)
        #expect(model.debugCameraState.pitchRadians < 1.1)
        #expect(model.debugCameraState.orthographicScale > 0)
        #expect(model.debugDisplayOptions.verticalScale <= 0.5)
    }

    @Test func cameraPresetChangesState() {
        let model = TelluricDebugRuntimeModel()
        let initial = model.debugCameraState

        model.applyDebugCameraPreset(.topDown)
        let topDown = model.debugCameraState

        #expect(model.currentCameraPreset == .topDown)
        #expect(topDown != initial)
        #expect(topDown.pitchRadians > initial.pitchRadians)

        model.applyDebugCameraPreset(.side)

        #expect(model.currentCameraPreset == .side)
        #expect(model.debugCameraState.pitchRadians < topDown.pitchRadians)
    }

    @Test func changingColorModeUpdatesDebugRenderSettings() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.debugMeshUploadHash

        model.setDebugTerrainColorMode(.surface)

        #expect(model.debugTerrainColorMode == .surface)
        #expect(model.debugDisplayOptions.colorMode == .surface)
        #expect(model.debugMeshUploadHash != firstHash)
    }

    @Test func selectingAndClearingChunkUpdatesInspectionState() throws {
        let model = TelluricDebugRuntimeModel()
        let coord = try #require(model.snapshot?.activeRecords.first?.chunkCoord)

        model.selectChunk(coord)

        #expect(model.selectedChunkCoord == coord)
        #expect(model.selectedChunkRecord?.chunkCoord == coord)
        #expect(model.debugTerrainMeshDescriptors.contains { $0.isSelected })

        model.clearSelection()

        #expect(model.selectedChunkCoord == nil)
        #expect(model.selectedChunkRecord == nil)
    }

    @Test func cameraControlsMutateCameraState() {
        let model = TelluricDebugRuntimeModel()
        let initial = model.debugCameraState

        model.zoomDebugCameraIn()
        #expect(model.debugCameraState != initial)

        let zoomed = model.debugCameraState
        model.rotateDebugCameraRight()
        #expect(model.debugCameraState.yawRadians != zoomed.yawRadians)

        let rotated = model.debugCameraState
        model.panDebugCameraNorth()
        #expect(model.debugCameraState.target.z != rotated.target.z)
    }

    @Test func meshListRemainsNonEmptyAfterDebugToggles() {
        let model = TelluricDebugRuntimeModel()

        model.isWireframeEnabled = true
        model.showsBounds = true
        model.showsNormals = true
        model.showsGrid = true
        model.showsPickedPoint = true
        model.debugNormalLength = 4
        model.setDebugTerrainColorMode(.altitude)

        #expect(model.debugTerrainMeshDescriptors.isEmpty == false)
        #expect(model.debugDisplayOptions.isWireframeEnabled)
        #expect(model.debugDisplayOptions.showsBounds)
        #expect(model.debugDisplayOptions.normals.isEnabled)
        #expect(model.debugDisplayOptions.grid.isEnabled)
        #expect(model.debugDisplayOptions.pickedPointMarker.isEnabled)
    }

    @Test func verticalScaleChangesDebugUploadHash() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.debugMeshUploadHash

        model.debugVerticalScale = 0.5

        #expect(model.debugDisplayOptions.verticalScale == 0.5)
        #expect(model.debugMeshUploadHash != firstHash)
    }

    @Test func playerProbeIsCreatedAfterInitialRebuild() throws {
        let model = TelluricDebugRuntimeModel()
        let probe = try #require(model.playerProbe)

        #expect(probe.isGrounded)
        #expect(probe.walkability.isWalkable)
        #expect(probe.lastQueryResult?.isInsideKnownTerrain == true)
        #expect(model.playerProbeWorldPoint != nil)
        #expect(model.debugDisplayOptions.probeMarker.isEnabled)
    }

    @Test func debugStatusReportsVisibleProbeAndTerrain() {
        let model = TelluricDebugRuntimeModel()

        #expect(model.isTerrainVisible)
        #expect(model.isProbeVisible)
        #expect(model.probeWalkabilityLabel.isEmpty == false)
        #expect(model.currentCameraPresetLabel == "Isometric")
        #expect(model.sanityDebugPresetLabel.contains("vertical"))
        #expect(model.selectedChunkStatusLabel == "none")
    }

    @Test func probeMarkerConfigIsVisibleByDefault() {
        let model = TelluricDebugRuntimeModel()
        let marker = model.debugDisplayOptions.probeMarker

        #expect(marker.isEnabled)
        #expect(marker.radius >= 3)
        #expect(marker.height >= 12)
    }

    @Test func focusProbeMovesCameraTargetToProbe() throws {
        let model = TelluricDebugRuntimeModel()
        let probe = try #require(model.playerProbe)

        model.focusDebugCameraOnProbe()

        #expect(model.currentCameraPreset == .custom)
        #expect(abs(model.debugCameraState.target.x - probe.worldPosition.x) < 0.0001)
        #expect(abs(model.debugCameraState.target.z - probe.worldPosition.z) < 0.0001)
    }

    @Test func movingPlayerProbeUpdatesPositionAndTerrainQuery() throws {
        let model = TelluricDebugRuntimeModel()
        let initial = try #require(model.playerProbe)

        model.movePlayerProbeEast()
        let moved = try #require(model.playerProbe)

        #expect(moved.worldPosition.x == initial.worldPosition.x + model.playerProbeStepMeters)
        #expect(moved.worldPosition.z == initial.worldPosition.z)
        #expect(moved.worldPosition.y == moved.lastQueryResult?.heightMeters)
        #expect(moved.lastQueryResult?.surface != nil)
    }

    @Test func resetPlayerProbeReturnsToCurrentCenterTerrain() throws {
        let model = TelluricDebugRuntimeModel()

        model.movePlayerProbeEast()
        model.movePlayerProbeNorth()
        model.resetPlayerProbe()

        let reset = try #require(model.playerProbe)
        #expect(reset.isGrounded)
        #expect(reset.lastQueryResult?.isInsideKnownTerrain == true)
    }

    @Test func movePlayerProbeToPickedPointUsesLastInspectionPoint() throws {
        let model = TelluricDebugRuntimeModel()
        let result = try makePickingResult(model: model)

        model.applyViewportPick(result)
        model.movePlayerProbeToPickedPoint()

        let probe = try #require(model.playerProbe)
        let picked = try #require(result.hit?.worldPosition.position)
        #expect(abs(probe.worldPosition.x - picked.x) < 0.0001)
        #expect(abs(probe.worldPosition.z - picked.z) < 0.0001)
        #expect(probe.lastQueryResult?.surface != nil)
    }

    @Test func togglingShowProbeUpdatesRenderOptions() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.debugMeshUploadHash

        model.showsPlayerProbe = false

        #expect(model.debugDisplayOptions.probeMarker.isEnabled == false)
        #expect(model.playerProbeWorldPoint == nil)
        #expect(model.debugMeshUploadHash != firstHash)
    }

    @Test func selectingChunkFromMetalPickingUpdatesSelection() throws {
        let model = TelluricDebugRuntimeModel()
        let result = try makePickingResult(model: model)
        let coord = try #require(result.hit?.chunkCoord)

        model.applyViewportPick(result)

        #expect(model.selectedChunkCoord == coord)
        #expect(model.selectedChunkRecord?.chunkCoord == coord)
        #expect(model.terrainInspectionState?.source == .click)
        #expect(model.pickedWorldPoint != nil)
    }

    @Test func hoverPickingExposesWorldPointWithoutChangingSelection() throws {
        let model = TelluricDebugRuntimeModel()
        let result = try makePickingResult(model: model)

        model.applyViewportHover(result)

        #expect(model.selectedChunkCoord == nil)
        #expect(model.terrainInspectionState?.source == .hover)
        #expect(model.terrainInspectionState?.pickedWorldPoint != nil)
        #expect(model.terrainInspectionState?.hit?.surface != nil)
    }

    @Test func clearingSelectionClearsGridAndMetalInspectionState() throws {
        let model = TelluricDebugRuntimeModel()
        let result = try makePickingResult(model: model)

        model.applyViewportPick(result)
        model.clearSelection()

        #expect(model.selectedChunkCoord == nil)
        #expect(model.selectedChunkRecord == nil)
        #expect(model.terrainInspectionState == nil)
    }

    @Test func togglingGridAndPickedPointUpdatesRenderOptions() {
        let model = TelluricDebugRuntimeModel()
        let firstHash = model.debugMeshUploadHash

        model.showsGrid = true
        model.showsPickedPoint = false

        #expect(model.debugDisplayOptions.grid.isEnabled)
        #expect(model.debugDisplayOptions.pickedPointMarker.isEnabled == false)
        #expect(model.debugMeshUploadHash != firstHash)
    }

    @Test func viewportScrollAndDragControlsMutateCameraState() {
        let model = TelluricDebugRuntimeModel()
        let initial = model.debugCameraState

        model.zoomDebugCameraFromScroll(deltaY: 2)
        #expect(model.debugCameraState != initial)

        let zoomed = model.debugCameraState
        model.orbitDebugCameraFromDrag(deltaX: 8, deltaY: 4)
        #expect(model.debugCameraState.yawRadians != zoomed.yawRadians)

        let orbited = model.debugCameraState
        model.panDebugCameraFromDrag(deltaX: 8, deltaY: 4)
        #expect(model.debugCameraState.target != orbited.target)
    }

    @Test func defaultRuntimeModeIsGameAndDebugRemainsAvailable() {
        #expect(TelluricRuntimeMode.defaultMode == .game)
        #expect(TelluricRuntimeMode.allCases.contains(.debug))
    }

    @Test func gameModelBuildsInitialPlayableSnapshot() {
        let model = TelluricGameRuntimeModel()

        #expect(model.profile == .debugPlayable)
        #expect(model.snapshot != nil)
        #expect(model.meshCount > 0)
        #expect(model.displayOptions.renderMode == .gamePreview)
        #expect(model.displayOptions.playerMarker.isEnabled)
        #expect(model.displayOptions.showsBounds == false)
        #expect(model.displayOptions.normals.isEnabled == false)
    }

    @Test func gamePlayerStartsGroundedAndWalkable() {
        let model = TelluricGameRuntimeModel()

        #expect(model.isGrounded)
        #expect(model.playerWalkability.isWalkable)
        #expect(model.playerPosition.y.isFinite)
        #expect(model.walkabilityLabel.isEmpty == false)
    }

    @Test func movingGamePlayerChangesXZAndUpdatesTerrainHeight() {
        let model = TelluricGameRuntimeModel()
        let initial = model.playerPosition

        model.movePlayer(deltaX: model.playerStepMeters, deltaZ: 0, source: .keyboard)

        #expect(model.playerPosition.x != initial.x)
        #expect(model.playerPosition.z == initial.z)
        #expect(model.playerPosition.y.isFinite)
        #expect(model.isGrounded)
        #expect(model.lastInputSource == .keyboard)
    }

    @Test func crossingChunkBoundaryUpdatesGameCenterAndSnapshot() {
        let model = TelluricGameRuntimeModel()
        let initialCenter = model.centerChunkCoord
        let initialHash = model.snapshot?.stableHash
        let distance = Float(model.layout.chunkSampleSpan) + 2

        model.movePlayer(deltaX: distance, deltaZ: 0, source: .keyboard)

        #expect(model.centerChunkCoord != initialCenter)
        #expect(model.playerChunkCoord == model.centerChunkCoord)
        #expect(model.snapshot?.stableHash != initialHash)
        #expect(model.meshCount > 0)
    }

    @Test func gameKeyboardInputStateMutatesMovementIntent() {
        let model = TelluricGameRuntimeModel()
        let initial = model.playerPosition
        let input = TelluricGameInputState(moveX: 0, moveZ: 1, source: .keyboard)

        #expect(input.hasMovement)
        model.applyKeyboardInput(input)

        #expect(model.playerPosition.z > initial.z)
        #expect(model.lastInputSource == .keyboard)
    }

    @Test func gameControllerInputLayerInitializesSafely() {
        let controllerInput = TelluricGameControllerInput()

        #expect(controllerInput.statusLabel.isEmpty == false)
    }

    @Test func gameHUDStatsAreNonEmpty() {
        let model = TelluricGameRuntimeModel()

        #expect(model.playerPositionLabel.isEmpty == false)
        #expect(model.centerChunkLabel.isEmpty == false)
        #expect(model.playerChunkLabel.isEmpty == false)
        #expect(model.walkabilityLabel.isEmpty == false)
        #expect(model.meshCount > 0)
        #expect(model.residentChunkCount > 0)
        #expect(model.activeChunkCount > 0)
    }

    private func makePickingResult(model: TelluricDebugRuntimeModel) throws -> MetalDebugPickingResult {
        let descriptor = try #require(model.debugTerrainMeshDescriptors.first)
        let bounds = descriptor.meshPayload.bounds
        let center = SIMD3<Float>(
            (bounds.min.x + bounds.max.x) * 0.5,
            (bounds.min.y + bounds.max.y) * 0.5,
            (bounds.min.z + bounds.max.z) * 0.5
        )
        let ray = MetalDebugRay(
            origin: SIMD3<Float>(center.x, bounds.max.y + 100, center.z),
            direction: SIMD3<Float>(0, -1, 0)
        )
        let result = MetalDebugPickingController().pick(
            ray: ray,
            descriptors: model.debugTerrainMeshDescriptors
        )

        _ = try #require(result.hit)
        return result
    }

}
