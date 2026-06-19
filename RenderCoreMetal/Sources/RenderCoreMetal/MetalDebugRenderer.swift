import EngineCore
import Foundation
import Metal
import MetalKit
import QuartzCore
import simd

public final class MetalDebugRenderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    public let configuration: MetalDebugRendererConfiguration
    public private(set) var currentFrameStats = MetalDebugFrameStats.zero

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let linePipelineState: MTLRenderPipelineState
    private let depthStencilState: MTLDepthStencilState
    private let uploader: MetalTerrainMeshUploader
    private var meshBuffers: [MetalTerrainMeshBuffers] = []
    private var camera = MetalDebugCamera()
    private var displayOptions = MetalDebugTerrainDisplayOptions.default
    private var boundsLineBuffers: MetalDebugLineBuffers?
    private var normalLineBuffers: MetalDebugLineBuffers?
    private var gridLineBuffers: MetalDebugLineBuffers?
    private var pickedPointLineBuffers: MetalDebugLineBuffers?
    private var probePointLineBuffers: MetalDebugLineBuffers?
    private var frameStats = MetalDebugFrameStats.zero
    private var frameIndex: UInt64 = 0
    private var lastFrameTimestamp: CFTimeInterval?
    private var lastStatsTimestamp: CFTimeInterval?
    private var framesSinceStatsPublish: UInt64 = 0

    public init(
        device: MTLDevice,
        configuration: MetalDebugRendererConfiguration = MetalDebugRendererConfiguration()
    ) throws {
        self.device = device
        self.configuration = configuration

        guard let commandQueue = device.makeCommandQueue() else {
            throw MetalDebugRenderError.commandQueueCreationFailed
        }
        self.commandQueue = commandQueue
        self.uploader = MetalTerrainMeshUploader(device: device)

        let library = try Self.makeShaderLibrary(device: device)
        let vertexFunction = library.makeFunction(name: "telluric_debug_terrain_vertex")
        let fragmentFunction = library.makeFunction(name: "telluric_debug_terrain_fragment")
        let lineVertexFunction = library.makeFunction(name: "telluric_debug_line_vertex")
        let lineFragmentFunction = library.makeFunction(name: "telluric_debug_line_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Telluric Debug Terrain Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = Self.makeVertexDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = configuration.depthPixelFormat

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            throw MetalDebugRenderError.pipelineCreationFailed(error.localizedDescription)
        }

        let linePipelineDescriptor = MTLRenderPipelineDescriptor()
        linePipelineDescriptor.label = "Telluric Debug Line Pipeline"
        linePipelineDescriptor.vertexFunction = lineVertexFunction
        linePipelineDescriptor.fragmentFunction = lineFragmentFunction
        linePipelineDescriptor.vertexDescriptor = Self.makeLineVertexDescriptor()
        linePipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
        linePipelineDescriptor.depthAttachmentPixelFormat = configuration.depthPixelFormat

        do {
            self.linePipelineState = try device.makeRenderPipelineState(descriptor: linePipelineDescriptor)
        } catch {
            throw MetalDebugRenderError.pipelineCreationFailed("line pipeline: \(error.localizedDescription)")
        }

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
            throw MetalDebugRenderError.pipelineCreationFailed("depth stencil state")
        }
        self.depthStencilState = depthStencilState

        super.init()
    }

    @MainActor
    public func attach(to view: MTKView) {
        view.device = device
        view.colorPixelFormat = configuration.colorPixelFormat
        view.depthStencilPixelFormat = configuration.depthPixelFormat
        view.clearColor = configuration.clearColor
        view.delegate = self
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
    }

    public func updateMeshes(_ descriptors: [MetalTerrainMeshDescriptor]) throws {
        try updateMeshes(descriptors, displayOptions: .default)
    }

    public func updateMeshes(
        _ descriptors: [MetalTerrainMeshDescriptor],
        displayOptions: MetalDebugTerrainDisplayOptions
    ) throws {
        try updateMeshes(
            descriptors,
            displayOptions: displayOptions,
            pickedPoint: nil
        )
    }

    public func updateMeshes(
        _ descriptors: [MetalTerrainMeshDescriptor],
        displayOptions: MetalDebugTerrainDisplayOptions,
        pickedPoint: MetalDebugWorldPoint?
    ) throws {
        try updateMeshes(
            descriptors,
            displayOptions: displayOptions,
            pickedPoint: pickedPoint,
            probePoint: nil
        )
    }

    public func updateMeshes(
        _ descriptors: [MetalTerrainMeshDescriptor],
        displayOptions: MetalDebugTerrainDisplayOptions,
        pickedPoint: MetalDebugWorldPoint?,
        probePoint: MetalDebugWorldPoint?
    ) throws {
        let effectiveDescriptors = descriptors.map { descriptor in
            MetalTerrainMeshDescriptor(
                meshPayload: descriptor.meshPayload,
                chunkID: descriptor.chunkID,
                lifecycleState: descriptor.lifecycleState,
                payloadState: descriptor.payloadState,
                colorMode: displayOptions.colorMode,
                isSelected: descriptor.isSelected,
                debugName: descriptor.debugName
            )
        }
        let result = try uploader.upload(
            descriptors: effectiveDescriptors,
            verticalScale: displayOptions.verticalScale
        )
        meshBuffers = result.buffers
        self.displayOptions = displayOptions
        boundsLineBuffers = displayOptions.showsBounds
            ? try makeLineBuffers(
                vertices: MetalDebugLineBuilder.makeBoundsLineVertices(
                    descriptors: effectiveDescriptors,
                    verticalScale: displayOptions.verticalScale
                ),
                debugName: "telluric-debug-bounds-lines"
            )
            : nil
        normalLineBuffers = displayOptions.normals.isEnabled
            ? try makeLineBuffers(
                vertices: MetalDebugLineBuilder.makeNormalLineVertices(
                    descriptors: effectiveDescriptors,
                    configuration: displayOptions.normals,
                    verticalScale: displayOptions.verticalScale
                ),
                debugName: "telluric-debug-normal-lines"
            )
            : nil
        gridLineBuffers = displayOptions.grid.isEnabled
            ? try makeLineBuffers(
                vertices: MetalDebugLineBuilder.makeGridLineVertices(
                    descriptors: effectiveDescriptors,
                    configuration: displayOptions.grid,
                    verticalScale: displayOptions.verticalScale
                ),
                debugName: "telluric-debug-grid-lines"
            )
            : nil
        pickedPointLineBuffers = displayOptions.pickedPointMarker.isEnabled
            ? try makeLineBuffers(
                vertices: MetalDebugLineBuilder.makePickedPointMarkerLineVertices(
                    point: pickedPoint,
                    configuration: displayOptions.pickedPointMarker,
                    verticalScale: displayOptions.verticalScale
                ),
                debugName: "telluric-debug-picked-point-lines"
            )
            : nil
        probePointLineBuffers = displayOptions.probeMarker.isEnabled
            ? try makeLineBuffers(
                vertices: MetalDebugLineBuilder.makeProbeMarkerLineVertices(
                    point: probePoint,
                    configuration: displayOptions.probeMarker,
                    verticalScale: displayOptions.verticalScale
                ),
                debugName: "telluric-debug-probe-point-lines"
            )
            : nil
    }

    public func updateCamera(_ state: MetalDebugCameraState) {
        camera = MetalDebugCamera(state: state)
    }

    public func clearMeshes() {
        meshBuffers = []
        camera = MetalDebugCamera()
        boundsLineBuffers = nil
        normalLineBuffers = nil
        gridLineBuffers = nil
        pickedPointLineBuffers = nil
        probePointLineBuffers = nil
        frameStats = MetalDebugFrameStats.zero
        currentFrameStats = .zero
    }

    public func draw(in view: MTKView) {
        guard meshBuffers.isEmpty == false,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }

        let drawableSize = view.drawableSize
        let aspectRatio = drawableSize.height > 0 ? Float(drawableSize.width / drawableSize.height) : 1
        let now = CACurrentMediaTime()
        let frameDelta = lastFrameTimestamp.map { now - $0 } ?? 0
        lastFrameTimestamp = now
        frameIndex += 1
        framesSinceStatsPublish += 1

        var uniforms = MetalDebugUniforms(mvp: camera.viewProjectionMatrix(aspectRatio: aspectRatio))

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setTriangleFillMode(displayOptions.isWireframeEnabled ? .lines : .fill)
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<MetalDebugUniforms>.stride,
            index: 1
        )

        for mesh in meshBuffers {
            encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: mesh.indexCount,
                indexType: .uint32,
                indexBuffer: mesh.indexBuffer,
                indexBufferOffset: 0
            )
        }

        encoder.setTriangleFillMode(.fill)
        drawLineBuffers(boundsLineBuffers, encoder: encoder, uniforms: &uniforms)
        drawLineBuffers(normalLineBuffers, encoder: encoder, uniforms: &uniforms)
        drawLineBuffers(gridLineBuffers, encoder: encoder, uniforms: &uniforms)
        drawLineBuffers(pickedPointLineBuffers, encoder: encoder, uniforms: &uniforms)
        drawLineBuffers(probePointLineBuffers, encoder: encoder, uniforms: &uniforms)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        updateFrameStats(now: now, frameDelta: frameDelta)
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    private static func makeShaderLibrary(device: MTLDevice) throws -> MTLLibrary {
        let shaderName = "TelluricDebugTerrain"
        let shaderSource: String

        if let url = Bundle.module.url(
            forResource: shaderName,
            withExtension: "metal",
            subdirectory: "Shaders"
        ) {
            do {
                shaderSource = try String(contentsOf: url, encoding: .utf8)
            } catch {
                throw MetalDebugRenderError.shaderResourceMissing(shaderName)
            }
        } else {
            shaderSource = fallbackShaderSource
        }

        do {
            return try device.makeLibrary(source: shaderSource, options: nil)
        } catch {
            throw MetalDebugRenderError.shaderCompilationFailed(error.localizedDescription)
        }
    }

    private static func makeVertexDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].offset = MemoryLayout<MetalTerrainVertex>.offset(of: \.position) ?? 0
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[1].format = .float3
        descriptor.attributes[1].offset = MemoryLayout<MetalTerrainVertex>.offset(of: \.normal) ?? 16
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[2].format = .float4
        descriptor.attributes[2].offset = MemoryLayout<MetalTerrainVertex>.offset(of: \.color) ?? 32
        descriptor.attributes[2].bufferIndex = 0
        descriptor.layouts[0].stride = MemoryLayout<MetalTerrainVertex>.stride
        descriptor.layouts[0].stepRate = 1
        descriptor.layouts[0].stepFunction = .perVertex
        return descriptor
    }

    private static func makeLineVertexDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].offset = MemoryLayout<MetalDebugLineVertex>.offset(of: \.position) ?? 0
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[1].format = .float4
        descriptor.attributes[1].offset = MemoryLayout<MetalDebugLineVertex>.offset(of: \.color) ?? 16
        descriptor.attributes[1].bufferIndex = 0
        descriptor.layouts[0].stride = MemoryLayout<MetalDebugLineVertex>.stride
        descriptor.layouts[0].stepRate = 1
        descriptor.layouts[0].stepFunction = .perVertex
        return descriptor
    }

    private func makeLineBuffers(
        vertices: [MetalDebugLineVertex],
        debugName: String
    ) throws -> MetalDebugLineBuffers? {
        guard vertices.isEmpty == false else {
            return nil
        }

        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<MetalDebugLineVertex>.stride,
            options: [.storageModeShared]
        ) else {
            throw MetalDebugRenderError.bufferAllocationFailed(debugName)
        }

        vertexBuffer.label = debugName
        return MetalDebugLineBuffers(
            vertexBuffer: vertexBuffer,
            vertexCount: vertices.count,
            debugName: debugName
        )
    }

    private func drawLineBuffers(
        _ lineBuffers: MetalDebugLineBuffers?,
        encoder: MTLRenderCommandEncoder,
        uniforms: inout MetalDebugUniforms
    ) {
        guard let lineBuffers else {
            return
        }

        encoder.setRenderPipelineState(linePipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<MetalDebugUniforms>.stride,
            index: 1
        )
        encoder.setVertexBuffer(lineBuffers.vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(
            type: .line,
            vertexStart: 0,
            vertexCount: lineBuffers.vertexCount
        )
    }

    private func updateFrameStats(now: CFTimeInterval, frameDelta: CFTimeInterval) {
        let publishInterval: CFTimeInterval = 0.35
        let previousPublish = lastStatsTimestamp ?? now
        let elapsed = max(now - previousPublish, 0.0001)

        guard lastStatsTimestamp == nil || elapsed >= publishInterval else {
            return
        }

        let fps = Double(framesSinceStatsPublish) / elapsed
        frameStats = MetalDebugFrameStats(
            framesPerSecond: fps.isFinite ? fps : 0,
            frameTimeMilliseconds: frameDelta > 0 ? frameDelta * 1_000 : 0,
            renderedMeshCount: meshBuffers.count,
            renderedVertexCount: meshBuffers.reduce(0) { $0 + $1.vertexCount },
            renderedIndexCount: meshBuffers.reduce(0) { $0 + $1.indexCount },
            renderedLineVertexCount: (boundsLineBuffers?.vertexCount ?? 0)
                + (normalLineBuffers?.vertexCount ?? 0)
                + (gridLineBuffers?.vertexCount ?? 0)
                + (pickedPointLineBuffers?.vertexCount ?? 0)
                + (probePointLineBuffers?.vertexCount ?? 0),
            frameIndex: frameIndex
        )
        currentFrameStats = frameStats
        lastStatsTimestamp = now
        framesSinceStatsPublish = 0
    }

    private static let fallbackShaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float3 position [[attribute(0)]];
        float3 normal [[attribute(1)]];
        float4 color [[attribute(2)]];
    };

    struct Uniforms {
        float4x4 mvp;
    };

    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };

    vertex VertexOut telluric_debug_terrain_vertex(
        VertexIn in [[stage_in]],
        constant Uniforms& uniforms [[buffer(1)]]
    ) {
        VertexOut out;
        out.position = uniforms.mvp * float4(in.position, 1.0);
        out.color = in.color;
        return out;
    }

    fragment float4 telluric_debug_terrain_fragment(VertexOut in [[stage_in]]) {
        return in.color;
    }

    struct LineVertexIn {
        float3 position [[attribute(0)]];
        float4 color [[attribute(1)]];
    };

    vertex VertexOut telluric_debug_line_vertex(
        LineVertexIn in [[stage_in]],
        constant Uniforms& uniforms [[buffer(1)]]
    ) {
        VertexOut out;
        out.position = uniforms.mvp * float4(in.position, 1.0);
        out.color = in.color;
        return out;
    }

    fragment float4 telluric_debug_line_fragment(VertexOut in [[stage_in]]) {
        return in.color;
    }
    """
}

private struct MetalDebugUniforms {
    var mvp: simd_float4x4
}
