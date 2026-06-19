public struct MetalDebugTerrainDisplayOptions: Sendable, Hashable {
    public var colorMode: MetalDebugTerrainColorMode
    public var isWireframeEnabled: Bool
    public var showsBounds: Bool
    public var normals: MetalDebugNormalsConfiguration

    public init(
        colorMode: MetalDebugTerrainColorMode = .mixed,
        isWireframeEnabled: Bool = false,
        showsBounds: Bool = false,
        normals: MetalDebugNormalsConfiguration = MetalDebugNormalsConfiguration()
    ) {
        self.colorMode = colorMode
        self.isWireframeEnabled = isWireframeEnabled
        self.showsBounds = showsBounds
        self.normals = normals
    }

    public static let `default` = MetalDebugTerrainDisplayOptions()

    public var stableDebugID: UInt64 {
        var state = colorMode.stableDebugID
        state = (state << 1) ^ UInt64(isWireframeEnabled ? 1 : 0)
        state = (state << 1) ^ UInt64(showsBounds ? 1 : 0)
        state = (state << 32) ^ normals.stableDebugID
        return state
    }
}
