public struct MetalDebugTerrainDisplayOptions: Sendable, Hashable {
    public var colorMode: MetalDebugTerrainColorMode
    public var isWireframeEnabled: Bool
    public var showsBounds: Bool
    public var normals: MetalDebugNormalsConfiguration
    public var grid: MetalDebugGridConfiguration
    public var pickedPointMarker: MetalDebugPickedPointMarkerConfiguration

    public init(
        colorMode: MetalDebugTerrainColorMode = .mixed,
        isWireframeEnabled: Bool = false,
        showsBounds: Bool = false,
        normals: MetalDebugNormalsConfiguration = MetalDebugNormalsConfiguration(),
        grid: MetalDebugGridConfiguration = MetalDebugGridConfiguration(),
        pickedPointMarker: MetalDebugPickedPointMarkerConfiguration = MetalDebugPickedPointMarkerConfiguration()
    ) {
        self.colorMode = colorMode
        self.isWireframeEnabled = isWireframeEnabled
        self.showsBounds = showsBounds
        self.normals = normals
        self.grid = grid
        self.pickedPointMarker = pickedPointMarker
    }

    public static let `default` = MetalDebugTerrainDisplayOptions()

    public var stableDebugID: UInt64 {
        var state = colorMode.stableDebugID
        for value in [
            UInt64(isWireframeEnabled ? 1 : 0),
            UInt64(showsBounds ? 1 : 0),
            normals.stableDebugID,
            grid.stableDebugID,
            pickedPointMarker.stableDebugID
        ] {
            state = (state &* 0x9E37_79B9_7F4A_7C15) ^ value
        }
        return state
    }
}
