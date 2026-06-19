public enum ChunkBuildError: Error, Hashable, Codable, Sendable {
    case unsupportedLifecycleState(ChunkLifecycleState)
}
