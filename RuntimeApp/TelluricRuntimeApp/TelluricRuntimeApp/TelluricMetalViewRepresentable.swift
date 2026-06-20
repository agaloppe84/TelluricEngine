import Foundation
import MetalKit
import RenderCoreMetal
import SwiftUI

struct TelluricMetalViewRepresentable: NSViewRepresentable {
    let meshDescriptors: [MetalTerrainMeshDescriptor]
    let uploadHash: UInt64
    let displayOptions: MetalDebugTerrainDisplayOptions
    let cameraState: MetalDebugCameraState
    let pickedPoint: MetalDebugWorldPoint?
    let probePoint: MetalDebugWorldPoint?
    let playerPoint: MetalDebugWorldPoint?
    let isViewportPickingEnabled: Bool
    let statsTick: Date
    @Binding var renderErrorMessage: String?
    @Binding var frameStats: MetalDebugFrameStats
    let onPickResult: (MetalDebugPickingResult) -> Void
    let onHoverResult: (MetalDebugPickingResult) -> Void
    let onScrollZoom: (Float) -> Void
    let onOrbitDrag: (Float, Float) -> Void
    let onPanDrag: (Float, Float) -> Void

    func makeCoordinator() -> TelluricMetalDebugCoordinator {
        TelluricMetalDebugCoordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        context.coordinator.makeView()
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.update(
            view: nsView,
            meshDescriptors: meshDescriptors,
            uploadHash: uploadHash,
            displayOptions: displayOptions,
            cameraState: cameraState,
            pickedPoint: pickedPoint,
            probePoint: probePoint,
            playerPoint: playerPoint,
            isViewportPickingEnabled: isViewportPickingEnabled,
            renderErrorMessage: $renderErrorMessage,
            frameStats: $frameStats,
            onPickResult: onPickResult,
            onHoverResult: onHoverResult,
            onScrollZoom: onScrollZoom,
            onOrbitDrag: onOrbitDrag,
            onPanDrag: onPanDrag
        )
    }
}
