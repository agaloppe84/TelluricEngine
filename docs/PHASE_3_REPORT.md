# Phase 3 Report - World Residency + Chunk Lifecycle

Date: 2026-06-19

## Summary

Phase 3 adds a pure `EngineCore` world residency planner. It answers which chunks should be targeted for sampling, CPU mesh generation, residency, activation, eviction, or future render consideration from a deterministic request.

Pipeline added:

```text
WorldResidencyRequest
  -> WorldResidencyPlanner
  -> WorldResidencyPlan
  -> ChunkLifecycleTarget[]
  -> RenderCandidateDescriptor[]
```

No rendering, Metal integration, Xcode project editing, runtime cache, async system, thread scheduling, or disk cache was added.

## Files Created Or Modified

Modified:

- `EngineCore/Sources/EngineCore/StableHasher.swift`

Created:

- `EngineCore/Sources/EngineCore/WorldChunkCoord.swift`
- `EngineCore/Sources/EngineCore/WorldChunkID.swift`
- `EngineCore/Sources/EngineCore/WorldResidencyConfig.swift`
- `EngineCore/Sources/EngineCore/WorldResidencyRequest.swift`
- `EngineCore/Sources/EngineCore/WorldResidencyPlanner.swift`
- `EngineCore/Sources/EngineCore/WorldResidencyPlan.swift`
- `EngineCore/Sources/EngineCore/WorldResidencyReason.swift`
- `EngineCore/Sources/EngineCore/WorldResidencyPriority.swift`
- `EngineCore/Sources/EngineCore/ChunkLifecycleState.swift`
- `EngineCore/Sources/EngineCore/ChunkLifecycleTarget.swift`
- `EngineCore/Sources/EngineCore/ChunkLifecycleTransition.swift`
- `EngineCore/Sources/EngineCore/SimulationChunkDescriptor.swift`
- `EngineCore/Sources/EngineCore/StreamingCellCoord.swift`
- `EngineCore/Sources/EngineCore/StreamingCellDescriptor.swift`
- `EngineCore/Sources/EngineCore/RenderCandidateDescriptor.swift`
- `EngineCore/Tests/EngineCoreTests/WorldResidencyConfigTests.swift`
- `EngineCore/Tests/EngineCoreTests/WorldResidencyPlannerTests.swift`
- `EngineCore/Tests/EngineCoreTests/WorldResidencyDeterminismTests.swift`
- `EngineCore/Tests/EngineCoreTests/ChunkLifecycleTransitionTests.swift`
- `EngineCore/Tests/EngineCoreTests/RenderCandidateDescriptorTests.swift`
- `EngineCore/Tests/EngineCoreTests/WorldResidencyImportGuardTests.swift`

## Contracts Added

- `WorldChunkCoord`
- `WorldChunkID`
- `WorldResidencyConfig`
- `WorldResidencyConfigError`
- `WorldResidencyRequest`
- `WorldResidencyPlanner`
- `WorldResidencyPlan`
- `WorldResidencyReason`
- `WorldResidencyPriority`
- `ChunkLifecycleState`
- `ChunkLifecycleTarget`
- `ChunkLifecycleTransition`
- `SimulationChunkDescriptor`
- `StreamingCellCoord`
- `StreamingCellDescriptor`
- `RenderCandidateDescriptor`

## Separation Of Concepts

`SimulationChunkDescriptor`

- deterministic generation unit;
- references `WorldChunkID`, `WorldSeed`, `TerrainGeneratorVersion`, `TerrainChunkLayout`;
- carries target lifecycle and priority;
- can later drive sample and mesh payload construction.

`StreamingCellDescriptor`

- CPU residency grouping unit;
- groups chunk IDs by `StreamingCellCoord`;
- represents residency planning only;
- contains no render or GPU state.

`RenderCandidateDescriptor`

- future rendering descriptor;
- references chunks already important enough for future rendering;
- contains optional CPU bounds and stable hashes only;
- contains no Metal object, buffer, device, pipeline, or RenderCoreMetal dependency.

## Distance Convention

Phase 3 uses Chebyshev distance:

```text
distance = max(abs(chunk.x - center.x), abs(chunk.z - center.z))
```

This keeps the initial residency region a stable square around the player/camera chunk.

## Lifecycle Strategy

The target state is selected by distance:

```text
distance <= activeRadiusChunks   -> active
distance <= residentRadiusChunks -> resident
distance <= meshRadiusChunks     -> meshRequested
distance <= sampleRadiusChunks   -> sampleRequested
distance <= evictionRadiusChunks -> evictionCandidate
else                             -> unloaded
```

Phase 3 produces targets and transitions only. It does not store real payloads or mutate a cache.

## Priority Strategy

`WorldResidencyPriority` is deterministic and comparable. Lower `rank` means higher planning priority.

Priority rank is derived from:

- Chebyshev distance;
- target lifecycle state;
- residency reason.

## Stable Ordering Strategy

Targets are sorted by:

```text
priority ASC
chunk x ASC
chunk z ASC
```

Transitions are sorted by:

```text
priority ASC
chunk ID ASC
```

Dictionary-backed grouping is normalized by sorting keys and IDs before returning descriptors.

## Stable Hash Strategy

All new persisted-style hashes use `StableHasher`. No Swift `Hasher` is used for truth hashes.

Stable hashes were added for:

- chunk coordinates and IDs;
- residency config and request;
- lifecycle states and reasons;
- priorities;
- lifecycle targets;
- simulation descriptors;
- streaming cell descriptors;
- render candidates;
- full residency plans.

`StableHasher` gained a minimal `Int` bit conversion helper for config and priority hashing.

## Render Candidate Strategy

Phase 3 creates `RenderCandidateDescriptor` values only for:

- `active`
- `resident`

It does not create render candidates for `meshRequested`, `sampleRequested`, or `evictionCandidate`.

The descriptors are CPU-only and carry no GPU resources.

## Tests Added

New tests cover:

- valid config accepted;
- equal radii accepted;
- negative radius rejected;
- inconsistent radii rejected;
- invalid `maxChunksPerPlan` rejected;
- same request produces identical plan, ordering and hash;
- different center chunk changes plan hash;
- lifecycle state selection by radius;
- Chebyshev target count `(2R + 1)^2`;
- stable order tie-breaks;
- `maxChunksPerPlan` stable cap;
- lifecycle transitions from current states to plan targets;
- no transition when state is identical;
- transition output sorted stably;
- render candidates only for active/resident chunks;
- render candidates remain CPU-only with nil GPU-related payloads;
- EngineCore import guard remains platform-free and rejects Metal, SwiftUI, AppKit, UIKit, RealityKit, SceneKit, SpriteKit, GameController, GameplayKit, AVFoundation and simd.

## Commands Run

`./scripts/swift-test-engine-safe.sh`

- Passed with approved non-sandboxed execution of the local safe script because SwiftPM uses `sandbox-exec`, which is blocked inside the Codex sandbox.
- Result: 38 tests, 0 failures.

`./scripts/swift-build-all-safe.sh`

- Passed with approved non-sandboxed execution of the local safe script for the same SwiftPM sandbox reason.
- Built:
  - `EngineCore`
  - `RenderCoreMetal`
  - `AudioRuntime`

`./scripts/verify-no-global-mutations.sh`

- Passed.
- No forbidden global mutation patterns detected.
- EngineCore import scan passed.

`./scripts/xcodebuild-safe.sh build`

- Passed.
- Project: `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj`
- Scheme: `TelluricRuntimeApp`
- DerivedData: `.derivedData/TelluricRuntimeApp`
- Xcode emitted the existing multiple matching macOS destinations warning, then built successfully.

## Known Limits

- The planner is purely CPU/data and does not maintain a real memory cache.
- No async work scheduling.
- No payload construction is performed by the planner.
- No disk cache.
- No GPU residency.
- No RenderCoreMetal integration.
- `StreamingCellDescriptor` currently groups chunks for planning only; no allocator or memory budget is attached.
- Directional prioritization from `cameraForward` and `playerVelocity` is reserved in the request but not used yet.

## Technical Risks

- Chebyshev square residency is simple and stable, but future topology-aware residency will need semantic regions, paths, visibility and hydrology.
- `maxChunksPerPlan` truncates by stable priority. This is deterministic, but a future scheduler may need separate per-state budgets.
- Missing current state defaults to `unloaded` when calculating transitions. This is useful for full plans but should be revisited once Phase 4 introduces an explicit cache snapshot.

## Safety Confirmation

- `RuntimeApp` was not modified.
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj` was not modified.
- `RenderCoreMetal` was not modified.
- `AudioRuntime` was not modified.
- No Ruby/Rails/Bundler/Gem command was used.
- No Homebrew command was used.
- No `sudo` was used.
- No `xcode-select` command was used.
- No global shell profile or toolchain config was touched.

## Phase 4 Proposal

Phase 4 - Chunk Build Pipeline + In-Memory World Cache

Goal:

- introduce a pure `EngineCore` in-memory cache;
- build chunks according to the residency plan;
- store sample payloads and mesh payloads;
- produce a stable snapshot of the resident world;
- remain without Metal;
- remain without Xcode integration.

