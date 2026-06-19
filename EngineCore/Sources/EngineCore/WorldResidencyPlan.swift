public struct WorldResidencyPlan: Hashable, Codable, Sendable, StableHashable {
    public let request: WorldResidencyRequest
    public let targets: [ChunkLifecycleTarget]
    public let simulationChunks: [SimulationChunkDescriptor]
    public let streamingCells: [StreamingCellDescriptor]
    public let renderCandidates: [RenderCandidateDescriptor]
    public let stableHash: UInt64

    public init(
        request: WorldResidencyRequest,
        targets: [ChunkLifecycleTarget],
        simulationChunks: [SimulationChunkDescriptor],
        streamingCells: [StreamingCellDescriptor],
        renderCandidates: [RenderCandidateDescriptor]
    ) {
        self.request = request
        self.targets = targets
        self.simulationChunks = simulationChunks
        self.streamingCells = streamingCells
        self.renderCandidates = renderCandidates
        self.stableHash = Self.computeStableHash(
            request: request,
            targets: targets,
            simulationChunks: simulationChunks,
            streamingCells: streamingCells,
            renderCandidates: renderCandidates
        )
    }

    public func target(for coord: WorldChunkCoord) -> ChunkLifecycleTarget? {
        targets.first { $0.chunkCoord == coord }
    }

    private static func computeStableHash(
        request: WorldResidencyRequest,
        targets: [ChunkLifecycleTarget],
        simulationChunks: [SimulationChunkDescriptor],
        streamingCells: [StreamingCellDescriptor],
        renderCandidates: [RenderCandidateDescriptor]
    ) -> UInt64 {
        var state = StableHasher.hash(seed: 0x7E11_571C_91A9_0001, request.stableHash)

        for target in targets {
            state = StableHasher.combine(state, target.stableHash)
        }
        for simulationChunk in simulationChunks {
            state = StableHasher.combine(state, simulationChunk.stableHash)
        }
        for streamingCell in streamingCells {
            state = StableHasher.combine(state, streamingCell.stableHash)
        }
        for renderCandidate in renderCandidates {
            state = StableHasher.combine(state, renderCandidate.stableHash)
        }

        state = StableHasher.combine(state, UInt64(targets.count))
        state = StableHasher.combine(state, UInt64(simulationChunks.count))
        state = StableHasher.combine(state, UInt64(streamingCells.count))
        return StableHasher.combine(state, UInt64(renderCandidates.count))
    }
}

