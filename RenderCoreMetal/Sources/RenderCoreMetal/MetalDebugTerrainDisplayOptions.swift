public struct MetalDebugTerrainDisplayOptions: Sendable, Hashable {
    public var colorMode: MetalDebugTerrainColorMode
    public var renderMode: MetalTerrainRenderMode
    public var isWireframeEnabled: Bool
    public var showsBounds: Bool
    public var verticalScale: Float
    public var normals: MetalDebugNormalsConfiguration
    public var grid: MetalDebugGridConfiguration
    public var pickedPointMarker: MetalDebugPickedPointMarkerConfiguration
    public var probeMarker: MetalDebugProbeMarkerConfiguration
    public var playerMarker: MetalDebugPlayerMarkerConfiguration

    public init(
        colorMode: MetalDebugTerrainColorMode = .mixed,
        renderMode: MetalTerrainRenderMode = .debug,
        isWireframeEnabled: Bool = false,
        showsBounds: Bool = false,
        verticalScale: Float = 0.25,
        normals: MetalDebugNormalsConfiguration = MetalDebugNormalsConfiguration(),
        grid: MetalDebugGridConfiguration = MetalDebugGridConfiguration(),
        pickedPointMarker: MetalDebugPickedPointMarkerConfiguration = MetalDebugPickedPointMarkerConfiguration(),
        probeMarker: MetalDebugProbeMarkerConfiguration = MetalDebugProbeMarkerConfiguration(),
        playerMarker: MetalDebugPlayerMarkerConfiguration = MetalDebugPlayerMarkerConfiguration(isEnabled: false)
    ) {
        self.colorMode = colorMode
        self.renderMode = renderMode
        self.isWireframeEnabled = isWireframeEnabled
        self.showsBounds = showsBounds
        self.verticalScale = verticalScale.isFinite ? max(verticalScale, 0.05) : 0.25
        self.normals = normals
        self.grid = grid
        self.pickedPointMarker = pickedPointMarker
        self.probeMarker = probeMarker
        self.playerMarker = playerMarker
    }

    public static let `default` = MetalDebugTerrainDisplayOptions()
    public static let gamePreview = MetalDebugTerrainDisplayOptions(
        colorMode: .surface,
        renderMode: .gamePreview,
        isWireframeEnabled: false,
        showsBounds: false,
        verticalScale: 1.0,
        normals: MetalDebugNormalsConfiguration(isEnabled: false),
        grid: MetalDebugGridConfiguration(isEnabled: false),
        pickedPointMarker: MetalDebugPickedPointMarkerConfiguration(isEnabled: false),
        probeMarker: MetalDebugProbeMarkerConfiguration(isEnabled: false),
        playerMarker: MetalDebugPlayerMarkerConfiguration(isEnabled: true)
    )

    public var stableDebugID: UInt64 {
        var state = StableHasherFallback.combine(colorMode.stableDebugID, renderMode.stableDebugID)
        for value in [
            UInt64(isWireframeEnabled ? 1 : 0),
            UInt64(showsBounds ? 1 : 0),
            UInt64(verticalScale.bitPattern),
            normals.stableDebugID,
            grid.stableDebugID,
            pickedPointMarker.stableDebugID,
            probeMarker.stableDebugID,
            playerMarker.stableDebugID
        ] {
            state = (state &* 0x9E37_79B9_7F4A_7C15) ^ value
        }
        return state
    }
}

private enum StableHasherFallback {
    static func combine(_ lhs: UInt64, _ rhs: UInt64) -> UInt64 {
        (lhs &* 0x9E37_79B9_7F4A_7C15) ^ rhs
    }
}
