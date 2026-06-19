import Metal
import MetalKit
import RenderCoreMetal
import SwiftUI

@MainActor
final class TelluricMetalDebugCoordinator {
    private var renderer: MetalDebugRenderer?
    private var lastMeshHash: UInt64?

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
        meshHash: UInt64,
        renderErrorMessage: Binding<String?>
    ) {
        do {
            let renderer = try ensureRenderer(for: view)

            guard meshDescriptors.isEmpty == false else {
                renderer.clearMeshes()
                lastMeshHash = nil
                renderErrorMessage.wrappedValue = "No terrain mesh payloads are available for Metal debug rendering."
                return
            }

            if lastMeshHash != meshHash {
                try renderer.updateMeshes(meshDescriptors)
                lastMeshHash = meshHash
            }

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
