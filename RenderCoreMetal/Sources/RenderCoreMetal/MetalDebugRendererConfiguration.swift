import Metal

public struct MetalDebugRendererConfiguration {
    public let colorPixelFormat: MTLPixelFormat
    public let depthPixelFormat: MTLPixelFormat
    public let clearColor: MTLClearColor

    public init(
        colorPixelFormat: MTLPixelFormat = .bgra8Unorm,
        depthPixelFormat: MTLPixelFormat = .depth32Float,
        clearColor: MTLClearColor = MTLClearColor(red: 0.06, green: 0.07, blue: 0.08, alpha: 1)
    ) {
        self.colorPixelFormat = colorPixelFormat
        self.depthPixelFormat = depthPixelFormat
        self.clearColor = clearColor
    }
}
