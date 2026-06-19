public struct MetalDebugFrameStats: Sendable, Equatable {
    public let framesPerSecond: Double
    public let frameTimeMilliseconds: Double
    public let renderedMeshCount: Int
    public let renderedVertexCount: Int
    public let renderedIndexCount: Int
    public let renderedLineVertexCount: Int
    public let frameIndex: UInt64

    public init(
        framesPerSecond: Double = 0,
        frameTimeMilliseconds: Double = 0,
        renderedMeshCount: Int = 0,
        renderedVertexCount: Int = 0,
        renderedIndexCount: Int = 0,
        renderedLineVertexCount: Int = 0,
        frameIndex: UInt64 = 0
    ) {
        self.framesPerSecond = framesPerSecond
        self.frameTimeMilliseconds = frameTimeMilliseconds
        self.renderedMeshCount = renderedMeshCount
        self.renderedVertexCount = renderedVertexCount
        self.renderedIndexCount = renderedIndexCount
        self.renderedLineVertexCount = renderedLineVertexCount
        self.frameIndex = frameIndex
    }

    public static let zero = MetalDebugFrameStats()
}
