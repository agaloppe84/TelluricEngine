import MetalKit
import RenderCoreMetal
import SwiftUI

struct TelluricMetalViewRepresentable: NSViewRepresentable {
    let meshDescriptors: [MetalTerrainMeshDescriptor]
    let meshHash: UInt64
    @Binding var renderErrorMessage: String?

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
            meshHash: meshHash,
            renderErrorMessage: $renderErrorMessage
        )
    }
}
