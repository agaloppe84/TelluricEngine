public struct MetalDebugPickingResult: Sendable, Hashable {
    public let screenPoint: MetalDebugScreenPoint
    public let viewportSize: MetalDebugScreenPoint
    public let ray: MetalDebugRay?
    public let hit: MetalDebugPickingHit?
    public let missReason: MetalDebugPickingMissReason?

    public init(
        screenPoint: MetalDebugScreenPoint,
        viewportSize: MetalDebugScreenPoint,
        ray: MetalDebugRay?,
        hit: MetalDebugPickingHit?,
        missReason: MetalDebugPickingMissReason?
    ) {
        self.screenPoint = screenPoint
        self.viewportSize = viewportSize
        self.ray = ray
        self.hit = hit
        self.missReason = missReason
    }

    public var isHit: Bool {
        hit != nil
    }

    public var stableDebugID: UInt64 {
        var state: UInt64 = 0x7E11_571C_91C8_0001
        for value in [screenPoint.x, screenPoint.y, viewportSize.x, viewportSize.y] {
            state = (state &* 0x9E37_79B9_7F4A_7C15) ^ UInt64(value.bitPattern)
        }
        state = (state &* 0x9E37_79B9_7F4A_7C15) ^ (hit?.stableDebugID ?? 0)
        state = (state &* 0x9E37_79B9_7F4A_7C15) ^ (missReason?.stableDebugID ?? 0)
        return state
    }
}
