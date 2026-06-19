import EngineCore
import Foundation
import Metal
import MetalKit
import simd

public final class MetalDebugRenderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    public let configuration: MetalDebugRendererConfiguration

    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let depthStencilState: MTLDepthStencilState
    private let uploader: MetalTerrainMeshUploader
    private var meshBuffers: [MetalTerrainMeshBuffers] = []
    private var camera = MetalDebugCamera()

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
        let result = try uploader.upload(descriptors: descriptors)
        meshBuffers = result.buffers
        camera = MetalDebugCamera.fitting(bounds: result.buffers.map(\.bounds))
    }

    public func clearMeshes() {
        meshBuffers = []
        camera = MetalDebugCamera()
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
        var uniforms = MetalDebugUniforms(
            mvp: camera.viewProjectionMatrix(aspectRatio: aspectRatio)
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)
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

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
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
    """
}

private struct MetalDebugUniforms {
    var mvp: simd_float4x4
}
