public enum MetalDebugCameraInput: Sendable, Hashable {
    case pan(dx: Float, dz: Float)
    case zoom(delta: Float)
    case orbit(deltaYaw: Float, deltaPitch: Float)
    case reset
    case fitTerrain
}
