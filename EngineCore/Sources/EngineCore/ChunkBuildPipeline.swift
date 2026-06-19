public struct ChunkBuildPipeline: Sendable {
    public init() {}

    public func apply(
        plan: WorldResidencyPlan,
        cache: inout InMemoryWorldCache
    ) throws -> ChunkBuildResult {
        var summary = WorldCacheMutationSummary()
        let plannedIDs = Set(plan.targets.map(\.chunkID))

        for target in plan.targets {
            let request = ChunkBuildRequest(target: target, planHash: plan.stableHash)

            if shouldRemoveRecord(for: target.targetState) {
                if cache.remove(target.chunkID) != nil {
                    summary.evictedCount += 1
                }
                continue
            }

            let existingRecord = cache.record(for: target.chunkID)
            let record = try makeRecord(request: request, existingRecord: existingRecord)

            if let existingRecord {
                if existingRecord == record {
                    summary.reusedCount += 1
                } else {
                    summary.updatedCount += 1
                }
            } else {
                summary.createdCount += 1
            }

            cache.upsert(record)
        }

        for record in cache.records where !plannedIDs.contains(record.chunkID) {
            cache.remove(record.chunkID)
            summary.evictedCount += 1
        }

        let snapshot = cache.snapshot(planHash: plan.stableHash)
        summary.samplePayloadCount = snapshot.stats.samplePayloadRecords
        summary.meshPayloadCount = snapshot.stats.meshPayloadRecords
        summary.renderCandidateCount = snapshot.stats.renderCandidateRecords

        return ChunkBuildResult(
            planHash: plan.stableHash,
            mutationSummary: summary,
            snapshot: snapshot
        )
    }

    private func shouldRemoveRecord(for state: ChunkLifecycleState) -> Bool {
        state == .unloaded || state == .evictionCandidate
    }

    private func makeRecord(
        request: ChunkBuildRequest,
        existingRecord: CachedChunkRecord?
    ) throws -> CachedChunkRecord {
        let target = request.target
        let payloadState = try payloadState(for: target.targetState)
        let samplePayload = try makeSamplePayload(
            target: target,
            existingRecord: existingRecord,
            payloadState: payloadState
        )
        let meshPayload = makeMeshPayload(
            samplePayload: samplePayload,
            existingRecord: existingRecord,
            payloadState: payloadState
        )
        let renderCandidate = makeRenderCandidate(
            target: target,
            meshPayload: meshPayload,
            payloadState: payloadState
        )

        return CachedChunkRecord(
            chunkID: target.chunkID,
            chunkCoord: target.chunkCoord,
            lifecycleState: target.targetState,
            payloadState: payloadState,
            priority: target.priority,
            samplePayload: samplePayload,
            meshPayload: meshPayload,
            renderCandidate: renderCandidate,
            lastPlanHash: request.planHash
        )
    }

    private func payloadState(for lifecycleState: ChunkLifecycleState) throws -> CachedChunkPayloadState {
        switch lifecycleState {
        case .sampleRequested, .sampled:
            return .sampled
        case .meshRequested, .meshed:
            return .meshed
        case .resident:
            return .resident
        case .active:
            return .active
        case .unloaded:
            return .empty
        case .evictionCandidate:
            return .evictionCandidate
        }
    }

    private func makeSamplePayload(
        target: ChunkLifecycleTarget,
        existingRecord: CachedChunkRecord?,
        payloadState: CachedChunkPayloadState
    ) throws -> ChunkTerrainSamplePayload? {
        guard payloadState != .empty && payloadState != .evictionCandidate else {
            return nil
        }

        if let samplePayload = existingRecord?.samplePayload {
            return samplePayload
        }

        return TerrainChunkSampler.makePayload(
            worldSeed: target.chunkID.worldSeed,
            chunkCoord: target.chunkCoord.chunkCoord,
            generatorVersion: target.chunkID.generatorVersion,
            layout: target.chunkID.layout
        )
    }

    private func makeMeshPayload(
        samplePayload: ChunkTerrainSamplePayload?,
        existingRecord: CachedChunkRecord?,
        payloadState: CachedChunkPayloadState
    ) -> TerrainMeshPayload? {
        guard payloadState == .meshed || payloadState == .resident || payloadState == .active else {
            return nil
        }

        if let meshPayload = existingRecord?.meshPayload {
            return meshPayload
        }

        guard let samplePayload else {
            return nil
        }

        return TerrainMeshBuilder.makePayload(from: samplePayload)
    }

    private func makeRenderCandidate(
        target: ChunkLifecycleTarget,
        meshPayload: TerrainMeshPayload?,
        payloadState: CachedChunkPayloadState
    ) -> RenderCandidateDescriptor? {
        guard payloadState == .resident || payloadState == .active else {
            return nil
        }

        return RenderCandidateDescriptor(
            chunkID: target.chunkID,
            chunkCoord: target.chunkCoord,
            priority: target.priority,
            targetState: target.targetState,
            bounds: meshPayload?.bounds,
            meshStableHash: meshPayload?.stableHash,
            surfaceStableHash: meshPayload?.surfacePayload.stableHash
        )
    }
}
