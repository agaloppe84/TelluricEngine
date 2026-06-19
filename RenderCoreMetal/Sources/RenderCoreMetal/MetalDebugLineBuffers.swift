import Metal

public struct MetalDebugLineBuffers {
    public let vertexBuffer: MTLBuffer
    public let vertexCount: Int
    public let debugName: String

    public init(
        vertexBuffer: MTLBuffer,
        vertexCount: Int,
        debugName: String
    ) {
        self.vertexBuffer = vertexBuffer
        self.vertexCount = vertexCount
        self.debugName = debugName
    }
}
