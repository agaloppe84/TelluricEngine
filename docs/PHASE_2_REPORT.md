# Phase 2 Report - Terrain Mesh Payload + Surface Fields

Date: 2026-06-19

## Summary

Phase 2 converts the deterministic terrain samples from Phase 1 into a minimal CPU terrain mesh contract with surface fields. This is still pure `EngineCore`: no rendering, no Metal, no SwiftUI, no Xcode project integration, and no external dependency.

Pipeline added:

```text
ChunkTerrainSamplePayload
  -> TerrainMeshPayload
  -> TerrainSurfacePayload
```

## Files Created Or Modified

Modified:

- `EngineCore/Sources/EngineCore/StableHasher.swift`
- `EngineCore/Tests/EngineCoreTests/DeterminismProbeTests.swift`

Created:

- `EngineCore/Sources/EngineCore/TEVec2f.swift`
- `EngineCore/Sources/EngineCore/TEVec3f.swift`
- `EngineCore/Sources/EngineCore/TEBounds3f.swift`
- `EngineCore/Sources/EngineCore/TerrainMeshIndex.swift`
- `EngineCore/Sources/EngineCore/TerrainMeshBounds.swift`
- `EngineCore/Sources/EngineCore/TerrainMeshVertex.swift`
- `EngineCore/Sources/EngineCore/TerrainMeshPayload.swift`
- `EngineCore/Sources/EngineCore/TerrainMeshBuilder.swift`
- `EngineCore/Sources/EngineCore/TerrainSurfaceMaterial.swift`
- `EngineCore/Sources/EngineCore/PhysicalSurfaceTag.swift`
- `EngineCore/Sources/EngineCore/AudioSurfaceTag.swift`
- `EngineCore/Sources/EngineCore/TerrainSurfaceSample.swift`
- `EngineCore/Sources/EngineCore/TerrainSurfacePayload.swift`
- `EngineCore/Sources/EngineCore/TerrainSurfaceResolver.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainMeshPayloadDeterminismTests.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainMeshPayloadTopologyTests.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainMeshBoundsTests.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainMeshEdgeConsistencyTests.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainSurfacePayloadTests.swift`

## Contracts Added

- `TEVec2f`
- `TEVec3f`
- `TEBounds3f`
- `TerrainMeshIndex`
- `TerrainMeshBounds`
- `TerrainMeshVertex`
- `TerrainMeshPayload`
- `TerrainMeshBuilder`
- `TerrainSurfaceMaterial`
- `PhysicalSurfaceTag`
- `AudioSurfaceTag`
- `TerrainSurfaceSample`
- `TerrainSurfacePayload`
- `TerrainSurfaceResolver`

## Axis Convention

Telluric terrain mesh vertices use:

```text
x = east/west
y = altitude / height
z = north/south
```

Vertex positions are world-space CPU data:

```text
position.x = world sample x * horizontal spacing
position.y = height meters
position.z = world sample z * horizontal spacing
```

## Mesh Topology Strategy

For an `N x N` sample layout:

- `vertexCount = N * N`
- `quadCount = (N - 1) * (N - 1)`
- `triangleCount = quadCount * 2`
- `indexCount = triangleCount * 3`

Each quad emits indices in stable row-major order:

```text
topLeft, bottomLeft, topRight
topRight, bottomLeft, bottomRight
```

The winding produces upward normals for a flat `x/z` terrain reference.

## Normal Strategy

Normals are calculated with central differences against deterministic world-neighbor samples:

```text
left  = sample(x - 1, z)
right = sample(x + 1, z)
south = sample(x, z - 1)
north = sample(x, z + 1)
normal = normalize((-dh/dx, 1, -dh/dz))
```

This is intentionally independent of the local chunk edge. Two neighboring chunks compute the same normal for the same world sample coordinate.

## Bounds Strategy

`TEBounds3f` starts from the first vertex position and includes each vertex position in stable order. Tests verify:

- every vertex is contained in the bounds;
- min/max components are ordered;
- bounds min/max Y match the vertex height range.

## Stable Hash Strategy

No Swift `Hasher` is used for payload hashes.

Phase 2 uses `StableHasher` and adds stable `Float` hashing through `Float.bitPattern`. Hashes include ordered fields and ordered arrays:

- mesh metadata;
- bounds;
- surface payload hash;
- vertices in row-major order;
- indices in emitted order.

## Surface Fields Strategy

Surface fields are pure data. They do not import or depend on `AudioRuntime`.

Minimal enums:

- `TerrainSurfaceMaterial`: `rock`, `soil`, `grass`, `sand`, `gravel`, `mud`, `snow`, `shallowWater`
- `PhysicalSurfaceTag`: `hardRock`, `looseSoil`, `softGrass`, `looseSand`, `looseGravel`, `stickyMud`, `compactSnow`, `shallowWater`
- `AudioSurfaceTag`: `stone`, `dirt`, `grass`, `sand`, `gravel`, `mud`, `snow`, `water`

`TerrainSurfaceResolver` derives a simple deterministic material from:

- height;
- slope from the computed normal;
- deterministic moisture from stable sample hashes.

This is not a biome solver. It is the first minimal surface truth contract.

## Tests Added

Added or extended tests cover:

- same seed/chunk/layout/version gives the same mesh payload;
- different seeds produce different sample and mesh hashes;
- topology counts match `N x N`;
- every index is valid;
- triangles are non-degenerate in the nominal grid;
- flat reference winding points upward;
- bounds contain all vertices;
- bounds min/max are ordered;
- bounds Y covers vertex height range;
- east/west neighboring chunk edges match;
- z-neighbor chunk edges match;
- shared edge vertices match by sample coord, position, height, normal and surface tags;
- surface payload samples match mesh vertices;
- surface resolution is stable for the same sample;
- EngineCore import guard now rejects `GameplayKit` and `simd` in addition to the previous forbidden imports.

## Commands Run

`./scripts/swift-test-engine-safe.sh`

- Passed with approved non-sandboxed execution of the local safe script because SwiftPM uses `sandbox-exec`, which is blocked inside the Codex sandbox.
- Result: 22 tests, 0 failures.

`./scripts/swift-build-all-safe.sh`

- Passed with approved non-sandboxed execution of the local safe script for the same SwiftPM sandbox reason.
- Built:
  - `EngineCore`
  - `RenderCoreMetal`
  - `AudioRuntime`

`./scripts/verify-no-global-mutations.sh`

- Passed.
- No forbidden global mutation patterns detected.
- EngineCore import guard scan passed.

`./scripts/xcodebuild-safe.sh build`

- Passed.
- Project: `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj`
- Scheme: `TelluricRuntimeApp`
- DerivedData: `.derivedData/TelluricRuntimeApp`
- Xcode emitted the existing multiple matching macOS destinations warning, then built successfully.

## Known Limits

- The mesh is a simple heightfield grid.
- No caves, tunnels, overhangs, hydrology, adaptive tessellation, LOD, collision payload, or renderer integration yet.
- Surface material rules are intentionally coarse and deterministic.
- Moisture is derived from stable hashes, not from a climate/hydrology field.
- `TerrainMeshPayload` is CPU-only and not yet consumed by `RenderCoreMetal`.

## Technical Risks

- `Float.bitPattern` makes hashes exact, but future changes to numeric algorithms will intentionally change golden hashes.
- The current scalar field is hash-noise-like, so normals can be steep and visually noisy. This is acceptable for the contract phase and should be refined when terrain fields become coherent.
- The surface resolver is a placeholder contract, not the final Surface Forge.

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

## Phase 3 Proposal

Phase 3 - World Residency + Chunk Lifecycle

Goal:

- separate `SimulationChunk`, `StreamingCell`, and `RenderCandidate`;
- introduce lifecycle states such as `unloaded`, `sampled`, `meshed`, `resident`, `active`;
- create a pure CPU `WorldResidencyPlanner`;
- keep rendering out of scope.

