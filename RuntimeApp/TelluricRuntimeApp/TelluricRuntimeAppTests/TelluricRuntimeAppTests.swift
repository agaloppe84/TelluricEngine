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
        #expect(model.debugDisplayOptions.colorMode == .mixed)
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
        model.debugNormalLength = 4
        model.setDebugTerrainColorMode(.altitude)

        #expect(model.debugTerrainMeshDescriptors.isEmpty == false)
        #expect(model.debugDisplayOptions.isWireframeEnabled)
        #expect(model.debugDisplayOptions.showsBounds)
        #expect(model.debugDisplayOptions.normals.isEnabled)
    }

}
