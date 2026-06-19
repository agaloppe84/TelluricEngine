import Metal
import MetalKit
import RenderCoreMetal
import SwiftUI
import Dispatch
import simd

@MainActor
final class TelluricMetalDebugCoordinator {
    private var renderer: MetalDebugRenderer?
    private var lastUploadHash: UInt64?
    private var lastCameraState: MetalDebugCameraState?
    private var currentMeshDescriptors: [MetalTerrainMeshDescriptor] = []
    private var currentCameraState = MetalDebugCameraState()
    private var isViewportPickingEnabled = true
    private var onPickResult: ((MetalDebugPickingResult) -> Void)?
    private var onHoverResult: ((MetalDebugPickingResult) -> Void)?
    private var onScrollZoom: ((Float) -> Void)?
    private var onOrbitDrag: ((Float, Float) -> Void)?
    private var onPanDrag: ((Float, Float) -> Void)?
    private let pickingController = MetalDebugPickingController()

    func makeView() -> MTKView {
        let view = TelluricInteractiveMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.clearColor = MTLClearColorMake(0.035, 0.04, 0.048, 1)
        view.depthStencilPixelFormat = .depth32Float
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.onClick = { [weak self] point, viewportSize in
            self?.handleClick(point: point, viewportSize: viewportSize)
        }
        view.onHover = { [weak self] point, viewportSize in
            self?.handleHover(point: point, viewportSize: viewportSize)
        }
        view.onScroll = { [weak self] deltaY in
            self?.onScrollZoom?(deltaY)
        }
        view.onOrbitDrag = { [weak self] deltaX, deltaY in
            self?.onOrbitDrag?(deltaX, deltaY)
        }
        view.onPanDrag = { [weak self] deltaX, deltaY in
            self?.onPanDrag?(deltaX, deltaY)
        }
        return view
    }

    func update(
        view: MTKView,
        meshDescriptors: [MetalTerrainMeshDescriptor],
        uploadHash: UInt64,
        displayOptions: MetalDebugTerrainDisplayOptions,
        cameraState: MetalDebugCameraState,
        pickedPoint: MetalDebugWorldPoint?,
        probePoint: MetalDebugWorldPoint?,
        isViewportPickingEnabled: Bool,
        renderErrorMessage: Binding<String?>,
        frameStats: Binding<MetalDebugFrameStats>,
        onPickResult: @escaping (MetalDebugPickingResult) -> Void,
        onHoverResult: @escaping (MetalDebugPickingResult) -> Void,
        onScrollZoom: @escaping (Float) -> Void,
        onOrbitDrag: @escaping (Float, Float) -> Void,
        onPanDrag: @escaping (Float, Float) -> Void
    ) {
        do {
            let renderer = try ensureRenderer(for: view)
            currentMeshDescriptors = meshDescriptors
            currentCameraState = cameraState
            self.isViewportPickingEnabled = isViewportPickingEnabled
            self.onPickResult = onPickResult
            self.onHoverResult = onHoverResult
            self.onScrollZoom = onScrollZoom
            self.onOrbitDrag = onOrbitDrag
            self.onPanDrag = onPanDrag

            guard meshDescriptors.isEmpty == false else {
                renderer.clearMeshes()
                lastUploadHash = nil
                lastCameraState = nil
                set(frameStats, to: renderer.currentFrameStats)
                set(renderErrorMessage, to: "No terrain mesh payloads are available for Metal debug rendering.")
                return
            }

            if lastUploadHash != uploadHash {
                try renderer.updateMeshes(
                    meshDescriptors,
                    displayOptions: displayOptions,
                    pickedPoint: pickedPoint,
                    probePoint: probePoint
                )
                lastUploadHash = uploadHash
            }

            if lastCameraState != cameraState {
                renderer.updateCamera(cameraState)
                lastCameraState = cameraState
            }

            set(frameStats, to: renderer.currentFrameStats)
            set(renderErrorMessage, to: nil)
        } catch {
            set(renderErrorMessage, to: String(describing: error))
        }
    }

    private func handleClick(point: SIMD2<Float>, viewportSize: SIMD2<Float>) {
        guard isViewportPickingEnabled else {
            return
        }
        let result = pickingController.pick(
            screenPoint: point,
            viewportSize: viewportSize,
            cameraState: currentCameraState,
            descriptors: currentMeshDescriptors
        )
        onPickResult?(result)
    }

    private func handleHover(point: SIMD2<Float>, viewportSize: SIMD2<Float>) {
        guard isViewportPickingEnabled else {
            return
        }
        let result = pickingController.pick(
            screenPoint: point,
            viewportSize: viewportSize,
            cameraState: currentCameraState,
            descriptors: currentMeshDescriptors
        )
        onHoverResult?(result)
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

    private func set<Value>(_ binding: Binding<Value>, to value: Value) {
        DispatchQueue.main.async {
            binding.wrappedValue = value
        }
    }
}
