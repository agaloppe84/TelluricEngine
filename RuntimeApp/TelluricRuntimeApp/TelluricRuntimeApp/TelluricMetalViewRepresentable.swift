import Foundation
import MetalKit
import RenderCoreMetal
import SwiftUI

struct TelluricMetalViewRepresentable: NSViewRepresentable {
    let meshDescriptors: [MetalTerrainMeshDescriptor]
    let uploadHash: UInt64
    let displayOptions: MetalDebugTerrainDisplayOptions
    let cameraState: MetalDebugCameraState
    let statsTick: Date
    @Binding var renderErrorMessage: String?
    @Binding var frameStats: MetalDebugFrameStats

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
            renderErrorMessage: $renderErrorMessage,
            frameStats: $frameStats
        )
    }
}
