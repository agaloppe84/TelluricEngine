public struct WorldResidencyPlanner: Sendable {
    public init() {}

    public func makePlan(_ request: WorldResidencyRequest) throws -> WorldResidencyPlan {
        try request.config.validate()

        let targets = makeTargets(request)
        let simulationChunks = targets.map(SimulationChunkDescriptor.init(target:))
        let streamingCells = makeStreamingCells(targets: targets, cellSizeChunks: request.config.streamingCellSizeChunks)
        let renderCandidates = targets
            .filter { $0.targetState == .active || $0.targetState == .resident }
            .map {
                RenderCandidateDescriptor(
                    chunkID: $0.chunkID,
                    chunkCoord: $0.chunkCoord,
                    priority: $0.priority,
                    targetState: $0.targetState
                )
            }

        return WorldResidencyPlan(
            request: request,
            targets: targets,
            simulationChunks: simulationChunks,
            streamingCells: streamingCells,
            renderCandidates: renderCandidates
        )
    }

    private func makeTargets(_ request: WorldResidencyRequest) -> [ChunkLifecycleTarget] {
        let radius = request.config.evictionRadiusChunks
        var targets: [ChunkLifecycleTarget] = []
        targets.reserveCapacity((radius * 2 + 1) * (radius * 2 + 1))

        for dz in (-radius)...radius {
            for dx in (-radius)...radius {
                let coord = makeCoord(center: request.centerChunkCoord, dx: dx, dz: dz)
                let distance = coord.chebyshevDistance(to: request.centerChunkCoord)
                let targetState = state(forDistance: distance, config: request.config)
                let reason = reason(forDistance: distance, config: request.config)
                let priority = WorldResidencyPriority(
                    distanceChunks: distance,
                    targetState: targetState,
                    reason: reason
                )
                let chunkID = WorldChunkID(
                    worldSeed: request.worldSeed,
                    generatorVersion: request.generatorVersion,
                    layout: request.layout,
                    profile: request.profile,
                    coord: coord
                )

                targets.append(
                    ChunkLifecycleTarget(
                        chunkID: chunkID,
                        chunkCoord: coord,
                        targetState: targetState,
                        reason: reason,
                        priority: priority
                    )
                )
            }
        }

        let sortedTargets = targets.sorted(by: Self.isTargetOrderedBefore)
        if let maxChunksPerPlan = request.config.maxChunksPerPlan {
            return Array(sortedTargets.prefix(maxChunksPerPlan))
        }
        return sortedTargets
    }

    private func makeStreamingCells(
        targets: [ChunkLifecycleTarget],
        cellSizeChunks: Int
    ) -> [StreamingCellDescriptor] {
        var grouped: [StreamingCellCoord: [ChunkLifecycleTarget]] = [:]
        for target in targets {
            let cellCoord = StreamingCellCoord(
                chunkCoord: target.chunkCoord,
                cellSizeChunks: cellSizeChunks
            )
            grouped[cellCoord, default: []].append(target)
        }

        return grouped.keys.sorted().map { cellCoord in
            let cellTargets = grouped[cellCoord, default: []].sorted(by: Self.isTargetOrderedBefore)
            let bestTarget = cellTargets[0]
            return StreamingCellDescriptor(
                cellCoord: cellCoord,
                chunkIDs: cellTargets.map(\.chunkID).sorted(),
                targetState: bestTarget.targetState,
                reason: bestTarget.reason,
                priority: bestTarget.priority
            )
        }
    }

    private func makeCoord(center: WorldChunkCoord, dx: Int, dz: Int) -> WorldChunkCoord {
        let x = Int(center.x) + dx
        let z = Int(center.z) + dz
        precondition(x >= Int(Int32.min) && x <= Int(Int32.max), "World chunk x is outside Int32 range.")
        precondition(z >= Int(Int32.min) && z <= Int(Int32.max), "World chunk z is outside Int32 range.")

        return WorldChunkCoord(x: Int32(x), z: Int32(z))
    }

    private func state(forDistance distance: Int, config: WorldResidencyConfig) -> ChunkLifecycleState {
        if distance <= config.activeRadiusChunks {
            return .active
        }
        if distance <= config.residentRadiusChunks {
            return .resident
        }
        if distance <= config.meshRadiusChunks {
            return .meshRequested
        }
        if distance <= config.sampleRadiusChunks {
            return .sampleRequested
        }
        if distance <= config.evictionRadiusChunks {
            return .evictionCandidate
        }
        return .unloaded
    }

    private func reason(forDistance distance: Int, config: WorldResidencyConfig) -> WorldResidencyReason {
        if distance <= config.activeRadiusChunks {
            return .activeRadius
        }
        if distance <= config.residentRadiusChunks {
            return .residentRadius
        }
        if distance <= config.meshRadiusChunks {
            return .meshRadius
        }
        if distance <= config.sampleRadiusChunks {
            return .sampleRadius
        }
        if distance <= config.evictionRadiusChunks {
            return .evictionRadius
        }
        return .outsideEvictionRadius
    }

    private static func isTargetOrderedBefore(
        _ lhs: ChunkLifecycleTarget,
        _ rhs: ChunkLifecycleTarget
    ) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }
        return lhs.chunkCoord < rhs.chunkCoord
    }
}
