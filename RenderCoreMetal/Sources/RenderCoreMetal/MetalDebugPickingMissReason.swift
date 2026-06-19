public enum MetalDebugPickingMissReason: String, Sendable, Hashable {
    case invalidViewport
    case invalidRay
    case noMeshDescriptors
    case noBoundsHit

    public var stableDebugID: UInt64 {
        switch self {
        case .invalidViewport:
            return 1
        case .invalidRay:
            return 2
        case .noMeshDescriptors:
            return 3
        case .noBoundsHit:
            return 4
        }
    }
}
