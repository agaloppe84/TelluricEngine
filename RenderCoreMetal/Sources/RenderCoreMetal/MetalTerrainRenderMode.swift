public enum MetalTerrainRenderMode: String, CaseIterable, Sendable, Hashable {
    case debug
    case gamePreview

    public var stableDebugID: UInt64 {
        switch self {
        case .debug:
            return 1
        case .gamePreview:
            return 2
        }
    }
}
