import Metal
import MetalKit
import RenderCoreMetal
import SwiftUI

@MainActor
final class TelluricMetalDebugCoordinator {
    private var renderer: MetalDebugRenderer?
    private var lastUploadHash: UInt64?
    private var lastCameraState: MetalDebugCameraState?

    func makeView() -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.clearColor = MTLClearColorMake(0.035, 0.04, 0.048, 1)
        view.depthStencilPixelFormat = .depth32Float
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        return view
    }

    func update(
        view: MTKView,
        meshDescriptors: [MetalTerrainMeshDescriptor],
        uploadHash: UInt64,
        displayOptions: MetalDebugTerrainDisplayOptions,
        cameraState: MetalDebugCameraState,
        renderErrorMessage: Binding<String?>,
        frameStats: Binding<MetalDebugFrameStats>
    ) {
        do {
            let renderer = try ensureRenderer(for: view)

            guard meshDescriptors.isEmpty == false else {
                renderer.clearMeshes()
                lastUploadHash = nil
                lastCameraState = nil
                frameStats.wrappedValue = renderer.currentFrameStats
                renderErrorMessage.wrappedValue = "No terrain mesh payloads are available for Metal debug rendering."
                return
            }

            if lastUploadHash != uploadHash {
                try renderer.updateMeshes(meshDescriptors, displayOptions: displayOptions)
                lastUploadHash = uploadHash
            }

            if lastCameraState != cameraState {
                renderer.updateCamera(cameraState)
                lastCameraState = cameraState
            }

            frameStats.wrappedValue = renderer.currentFrameStats
            renderErrorMessage.wrappedValue = nil
        } catch {
            renderErrorMessage.wrappedValue = String(describing: error)
        }
    }

    private func ensureRenderer(for view: MTKView) throws -> MetalDebugRenderer {
        if let renderer {
            return renderer
        }

        guard let device = view.device ?? MTLCreateSystemDefaultDevice() else {
            throw MetalDebugRenderError.missingDevice
        }

        let renderer = try MetalDebugRenderer(device: device)
        renderer.attach(to: view)
        self.renderer = renderer
        return renderer
    }
}
