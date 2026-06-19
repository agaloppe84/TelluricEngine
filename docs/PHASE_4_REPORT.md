# Phase 4 Report - Chunk Build Pipeline + In-Memory World Cache

## Summary

Phase 4 adds a pure EngineCore chunk build layer that turns a `WorldResidencyPlan` into deterministic in-memory terrain payload records and a stable read-only snapshot.

Pipeline implemented:

```text
WorldResidencyRequest
  -> WorldResidencyPlanner.makePlan()
  -> ChunkBuildPipeline.apply(plan, cache)
  -> InMemoryWorldCache
  -> ResidentWorldSnapshot
```

No rendering, Metal integration, disk cache, async runtime, Xcode project edit, RenderCoreMetal edit, or AudioRuntime edit was added.

## Files Created

EngineCore sources:

- `EngineCore/Sources/EngineCore/CachedChunkPayloadState.swift`
- `EngineCore/Sources/EngineCore/CachedChunkRecord.swift`
- `EngineCore/Sources/EngineCore/ChunkBuildRequest.swift`
- `EngineCore/Sources/EngineCore/ChunkBuildResult.swift`
- `EngineCore/Sources/EngineCore/ChunkBuildPipeline.swift`
- `EngineCore/Sources/EngineCore/ChunkBuildError.swift`
- `EngineCore/Sources/EngineCore/InMemoryWorldCache.swift`
- `EngineCore/Sources/EngineCore/ResidentWorldSnapshot.swift`
- `EngineCore/Sources/EngineCore/ResidentWorldSnapshotBuilder.swift`
- `EngineCore/Sources/EngineCore/WorldCacheMutationSummary.swift`
- `EngineCore/Sources/EngineCore/WorldCacheStats.swift`

EngineCore tests:

- `EngineCore/Tests/EngineCoreTests/ChunkBuildImportGuardTests.swift`
- `EngineCore/Tests/EngineCoreTests/ChunkBuildPipelineTests.swift`
- `EngineCore/Tests/EngineCoreTests/InMemoryWorldCacheTests.swift`
- `EngineCore/Tests/EngineCoreTests/ResidentWorldSnapshotTests.swift`
- `EngineCore/Tests/EngineCoreTests/WorldCacheDeterminismTests.swift`
- `EngineCore/Tests/EngineCoreTests/WorldCacheStatsTests.swift`
- `EngineCore/Tests/EngineCoreTests/WorldCacheTestSupport.swift`

Documentation:

- `docs/PHASE_4_REPORT.md`

No safe scripts were modified.

## Contracts Added

- `ChunkBuildRequest`: stable per-target build request tied to a plan hash.
- `ChunkBuildPipeline`: stateless synchronous CPU-only builder.
- `ChunkBuildResult`: stable result containing the plan hash, mutation summary, and snapshot.
- `ChunkBuildError`: reserved local error contract for unsupported build states.
- `CachedChunkPayloadState`: cache reality state, separate from lifecycle intent.
- `CachedChunkRecord`: cached chunk data and optional payloads.
- `InMemoryWorldCache`: local mutable in-memory store with stable sorted record exposure.
- `ResidentWorldSnapshot`: stable read-only value snapshot of cached world state.
- `ResidentWorldSnapshotBuilder`: deterministic snapshot construction helper.
- `WorldCacheMutationSummary`: deterministic mutation counters.
- `WorldCacheStats`: deterministic cache and payload counters.

## Responsibility Separation

- `WorldResidencyPlanner` decides what should exist. It was not changed into a builder or cache.
- `ChunkBuildPipeline` consumes plan targets and constructs terrain samples, mesh payloads, and CPU-only render candidates.
- `InMemoryWorldCache` stores local records only. It has no singleton state, disk I/O, threads, async, GPU object, or renderer dependency.
- `ResidentWorldSnapshot` exposes sorted value-type arrays and does not mutate the cache.

## Payload State Strategy

`ChunkLifecycleState` remains the plan intent.

`CachedChunkPayloadState` represents what the cache currently contains:

- `empty`
- `sampled`
- `meshed`
- `resident`
- `active`
- `evictionCandidate`

The separation keeps residency planning independent from cache contents.

## Build Strategy By Lifecycle Target

- `sampleRequested` and `sampled`: build or reuse `ChunkTerrainSamplePayload` only.
- `meshRequested` and `meshed`: build or reuse sample payload plus `TerrainMeshPayload`.
- `resident`: build or reuse sample payload, mesh payload, and `RenderCandidateDescriptor`.
- `active`: build or reuse sample payload, mesh payload, and `RenderCandidateDescriptor`.
- `evictionCandidate`: remove from cache.
- `unloaded`: remove from cache.

Render candidates remain CPU-only descriptors and include mesh bounds plus mesh/surface stable hashes when a mesh payload exists.

## Eviction Strategy

Phase 4 uses a simple deterministic strategy:

- targets marked `evictionCandidate` are removed from the cache;
- targets marked `unloaded` are removed from the cache;
- records absent from the latest plan are removed during a stable sweep over sorted cache records.

This prevents stale chunks from remaining resident after the streaming center moves.

## Reuse Strategy

The pipeline reuses existing sample and mesh payloads when a compatible record for the same `WorldChunkID` already exists. Applying the same plan twice:

- does not duplicate records;
- preserves snapshot hash and stats;
- reports reused records on the second pass.

## Snapshot Strategy

`ResidentWorldSnapshot` stores:

- `planHash`
- `cacheHash`
- sorted `records`
- sorted `activeRecords`
- sorted `residentRecords`
- sorted `renderCandidates`
- `stats`
- `stableHash`

Snapshots are value-type read-only views. Mutating the cache after snapshot creation does not mutate previous snapshots.

## Stats Strategy

`WorldCacheStats` tracks deterministic counts only:

- total records;
- records with sample payloads;
- records with mesh payloads;
- resident records;
- active records;
- render candidate records;
- estimated vertex count;
- estimated index count.

No system memory measurement or OS runtime metric is used in Phase 4.

## Stable Ordering Strategy

Cache records and render candidates are exposed in this order:

1. `WorldResidencyPriority` ascending;
2. `WorldChunkCoord` ascending;
3. `WorldChunkID` ascending.

Dictionary storage is allowed internally, but all public arrays and hashes are derived from sorted records.

## Stable Hash Strategy

All new persistent truth contracts use `StableHasher`; Swift `Hasher` is not used for stable truth.

Stable hashes include:

- chunk identity;
- lifecycle state;
- payload state;
- priority;
- optional payload hashes with explicit presence bits;
- optional render candidate hashes with explicit presence bits;
- optional plan hash presence bits;
- stats;
- sorted record/candidate order.

Existing payload stable hashes are reused for `ChunkTerrainSamplePayload`, `TerrainMeshPayload`, and `TerrainSurfacePayload`.

## Tests Added

Added tests cover:

- sample-only chunk builds;
- mesh chunk builds;
- resident and active chunk builds;
- render candidate creation for resident/active only;
- eviction-candidate removal;
- idempotent repeated plan application;
- deterministic repeated build output;
- different center producing different plan/snapshot;
- stale record eviction when center changes;
- stable cache ordering independent of dictionary insertion order;
- stable cache hash independent of insertion order;
- snapshot read-only behavior after cache mutation;
- stats correctness;
- empty cache stats;
- forbidden EngineCore imports guard.

## Commands Launched

Only repository safe scripts were used for validation.

### `./scripts/swift-test-engine-safe.sh`

Result: passed, exit code 0.

Exact relevant result:

```text
Executed 55 tests, with 0 failures (0 unexpected)
Test Suite 'All tests' passed
```

### `./scripts/swift-build-all-safe.sh`

Result: passed, exit code 0.

Exact relevant result:

```text
Building EngineCore
Build complete!
Building RenderCoreMetal
Build complete!
Building AudioRuntime
Build complete!
All Swift packages built.
```

### `./scripts/verify-no-global-mutations.sh`

Result: passed, exit code 0.

Exact relevant result:

```text
Checking safe scripts for forbidden global mutation commands.
Checking EngineCore forbidden imports.
Checking .gitignore local output coverage.
No global mutation patterns detected.
```

### `./scripts/xcodebuild-safe.sh build`

Result: passed, exit code 0.

Detected project:

```text
/Users/work/GamesByMe/TelluricEngine/RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj
```

Local DerivedData:

```text
/Users/work/GamesByMe/TelluricEngine/.derivedData/TelluricRuntimeApp
```

Exact relevant result:

```text
** BUILD SUCCEEDED **
```

## Known Limits

- The cache is in-memory only and synchronous.
- There is no disk persistence, memory budget, background job system, or async scheduling.
- There is no real render runtime; render candidates are CPU-only descriptors.
- Eviction is intentionally simple: remove records rather than keeping lightweight metadata.
- Payload compatibility is keyed by `WorldChunkID`; Phase 4 does not yet maintain a deeper invalidation graph.
- No LOD, remeshing, collision, biome runtime, vegetation, or hydrology system was added.

## Technical Risks

- Large radius plans can build many CPU meshes synchronously; future phases should add budgeted work scheduling before increasing world scale.
- Cache invalidation is simple and should be revisited when generator versions, layouts, and runtime quality levels grow.
- Render candidates now carry CPU mesh bounds and stable hashes, but no GPU upload contract exists yet.

## Confirmations

- Xcode project files were not modified.
- `RuntimeApp/` was not modified.
- `RenderCoreMetal/` was not modified.
- `AudioRuntime/` was not modified.
- `TelluricTools/`, `Shaders/`, and `LocalAssets/` were not modified.
- Ruby, Rails, Bundler, Gem, Homebrew, sudo, and global `xcode-select` commands were not used.
- No global shell or tool configuration was modified.
- EngineCore remains CPU/data-only and forbidden imports are guarded by tests.

## Recommended Phase 5

Phase 5 — Runtime Debug Visualization Bridge

Objective Phase 5:

- integrate EngineCore cleanly into `RuntimeApp` without breaking the architecture;
- display a first CPU/SwiftUI or very minimal Metal debug visualization, depending on the chosen integration decision;
- allow active/resident/meshed chunks to be inspected visually;
- keep EngineCore pure;
- avoid building the AAA renderer too early;
- avoid advanced systems until debug visualization is reliable.

Phase 5 may touch Xcode, but Phase 4 did not.
