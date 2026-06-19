public struct MetalDebugTerrainDisplayOptions: Sendable, Hashable {
    public var colorMode: MetalDebugTerrainColorMode
    public var isWireframeEnabled: Bool
    public var showsBounds: Bool
    public var verticalScale: Float
    public var normals: MetalDebugNormalsConfiguration
    public var grid: MetalDebugGridConfiguration
    public var pickedPointMarker: MetalDebugPickedPointMarkerConfiguration
    public var probeMarker: MetalDebugProbeMarkerConfiguration

    public init(
        colorMode: MetalDebugTerrainColorMode = .mixed,
        isWireframeEnabled: Bool = false,
        showsBounds: Bool = false,
        verticalScale: Float = 0.25,
        normals: MetalDebugNormalsConfiguration = MetalDebugNormalsConfiguration(),
        grid: MetalDebugGridConfiguration = MetalDebugGridConfiguration(),
        pickedPointMarker: MetalDebugPickedPointMarkerConfiguration = MetalDebugPickedPointMarkerConfiguration(),
        probeMarker: MetalDebugProbeMarkerConfiguration = MetalDebugProbeMarkerConfiguration()
    ) {
        self.colorMode = colorMode
        self.isWireframeEnabled = isWireframeEnabled
        self.showsBounds = showsBounds
        self.verticalScale = verticalScale.isFinite ? max(verticalScale, 0.05) : 0.25
        self.normals = normals
        self.grid = grid
        self.pickedPointMarker = pickedPointMarker
        self.probeMarker = probeMarker
    }

    public static let `default` = MetalDebugTerrainDisplayOptions()

    public var stableDebugID: UInt64 {
        var state = colorMode.stableDebugID
        for value in [
            UInt64(isWireframeEnabled ? 1 : 0),
            UInt64(showsBounds ? 1 : 0),
            UInt64(verticalScale.bitPattern),
            normals.stableDebugID,
            grid.stableDebugID,
            pickedPointMarker.stableDebugID,
            probeMarker.stableDebugID
        ] {
            state = (state &* 0x9E37_79B9_7F4A_7C15) ^ value
        }
        return state
    }
}
