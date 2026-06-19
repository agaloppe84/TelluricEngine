public struct ChunkLifecycleTransition: Hashable, Codable, Sendable, StableHashable {
    public let chunkID: WorldChunkID
    public let fromState: ChunkLifecycleState
    public let toState: ChunkLifecycleState
    public let reason: WorldResidencyReason
    public let priority: WorldResidencyPriority

    public init(
        chunkID: WorldChunkID,
        fromState: ChunkLifecycleState,
        toState: ChunkLifecycleState,
        reason: WorldResidencyReason,
        priority: WorldResidencyPriority
    ) {
        self.chunkID = chunkID
        self.fromState = fromState
        self.toState = toState
        self.reason = reason
        self.priority = priority
    }

    public var stableHash: UInt64 {
        StableHasher.hash(
            seed: 0x7E11_571C_7A45_0001,
            chunkID.stableHash,
            fromState.stableHash,
            toState.stableHash,
            reason.stableHash,
            priority.stableHash
        )
    }

    public static func makeTransitions(
        currentStates: [WorldChunkID: ChunkLifecycleState],
        plan: WorldResidencyPlan
    ) -> [ChunkLifecycleTransition] {
        var transitions: [ChunkLifecycleTransition] = []
        transitions.reserveCapacity(plan.targets.count)

        for target in plan.targets {
            let currentState = currentStates[target.chunkID] ?? .unloaded
            if currentState == target.targetState {
                continue
            }

            transitions.append(
                ChunkLifecycleTransition(
                    chunkID: target.chunkID,
                    fromState: currentState,
                    toState: target.targetState,
                    reason: target.reason,
                    priority: target.priority
                )
            )
        }

        return transitions.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            return lhs.chunkID < rhs.chunkID
        }
    }
}

