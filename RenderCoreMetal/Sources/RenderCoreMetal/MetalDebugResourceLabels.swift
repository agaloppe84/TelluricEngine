public enum MetalDebugResourceLabels {
    public static func terrainVertexBuffer(debugName: String) -> String {
        "\(debugName)-terrain-vertices"
    }

    public static func terrainIndexBuffer(debugName: String) -> String {
        "\(debugName)-terrain-indices"
    }

    public static func lineBuffer(debugName: String) -> String {
        debugName
    }

    public static func commandBuffer(frameIndex: UInt64) -> String {
        "telluric-debug-frame-\(frameIndex)-command-buffer"
    }

    public static let renderEncoder = "telluric-debug-terrain-render-encoder"
    public static let terrainDrawGroup = "telluric terrain meshes"
    public static let debugLineDrawGroup = "telluric debug line overlays"
}
