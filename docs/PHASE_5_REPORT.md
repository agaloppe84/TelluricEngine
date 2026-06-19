# Phase 5 Report - Runtime Debug Visualization Bridge

## Summary

Phase 5 integrates the pure `EngineCore` pipeline into `TelluricRuntimeApp` and replaces the placeholder app content with a SwiftUI debug visualization for the resident world snapshot.

The runtime app now performs:

```text
WorldResidencyRequest
  -> WorldResidencyPlanner.makePlan()
  -> ChunkBuildPipeline.apply(plan, cache)
  -> ResidentWorldSnapshot
  -> SwiftUI debug grid
```

This phase does not add a Metal renderer, GPU buffers, shaders, terrain lighting, vegetation, or RenderCoreMetal integration.

## Files Created Or Modified

Runtime app:

- Modified `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/ContentView.swift`
- Created `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugRuntimeModel.swift`
- Created `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugView.swift`
- Created `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricChunkGridView.swift`
- Created `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricChunkCellView.swift`
- Created `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricSnapshotStatsView.swift`
- Created `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricRuntimeControlsView.swift`

Runtime tests:

- Modified `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

Xcode project:

- Modified `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj/project.pbxproj`

Documentation:

- Created `docs/PHASE_5_REPORT.md`

No `EngineCore` source file was changed in Phase 5.

## Exact Xcode Modifications

The existing Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so new Swift files under `TelluricRuntimeApp/` and `TelluricRuntimeAppTests/` are picked up by the synchronized groups.

The project file was changed only to integrate the local package product:

- Added `XCLocalSwiftPackageReference` with `relativePath = ../../EngineCore`.
- Added `XCSwiftPackageProductDependency` entries for `EngineCore`.
- Added `EngineCore` to `PBXProject.packageReferences`.
- Added `EngineCore` to `TelluricRuntimeApp.packageProductDependencies`.
- Added `EngineCore` to `TelluricRuntimeAppTests.packageProductDependencies`.
- Added `EngineCore in Frameworks` to the app target Frameworks phase.
- Added `EngineCore in Frameworks` to the unit test target Frameworks phase.

`RenderCoreMetal` and `AudioRuntime` were not added to the Xcode project.

## EngineCore Integration

`RuntimeApp` imports `EngineCore` directly from the local Swift package.

`TelluricDebugRuntimeModel` owns the debug runtime state:

- current seed;
- generator version;
- terrain layout;
- residency config;
- center chunk coordinate;
- `WorldResidencyPlanner`;
- `InMemoryWorldCache`;
- latest `WorldResidencyPlan`;
- latest `ChunkBuildResult`;
- latest `ResidentWorldSnapshot`;
- rebuild and movement methods.

The app uses a lightweight debug config:

- `activeRadiusChunks = 0`
- `residentRadiusChunks = 1`
- `meshRadiusChunks = 2`
- `sampleRadiusChunks = 3`
- `evictionRadiusChunks = 4`
- `samplesPerAxis = 9`

## Debug Runtime Model Architecture

`TelluricDebugRuntimeModel` is a `@MainActor ObservableObject`.

It exposes:

- `rebuild()`
- `moveNorth()`
- `moveSouth()`
- `moveEast()`
- `moveWest()`
- `reset()`

Moving north increments chunk `z`. Moving south decrements chunk `z`. Moving east increments chunk `x`. Moving west decrements chunk `x`.

`reset()` returns to center chunk `(0, 0)`, clears the in-memory cache, and rebuilds the snapshot.

## Visualization Strategy

Phase 5 uses a SwiftUI 2D grid, not Metal.

`TelluricChunkGridView` displays a square grid around the current center chunk. Each cell comes from the latest plan and snapshot:

- cached chunks show their payload state;
- plan-only eviction candidates are visible as `evict`;
- absent/unloaded chunks are represented as `none` if needed.

`TelluricChunkCellView` uses debug colors for:

- `active`
- `resident`
- `meshed` / `meshRequested`
- `sampled` / `sampleRequested`
- `evictionCandidate`
- `unloaded` / absent

The grid is intentionally 2D and diagnostic. It does not render terrain meshes.

## Controls Available

`TelluricRuntimeControlsView` provides:

- North
- South
- East
- West
- Rebuild
- Reset

It also displays:

- center chunk;
- generator version;
- sample layout;
- residency radii.

## Stats Displayed

`TelluricSnapshotStatsView` displays:

- total records;
- active records;
- resident records;
- meshed records;
- sample-only records;
- render candidate records;
- estimated vertex count;
- estimated index count;
- plan hash;
- cache hash;
- snapshot hash;
- any rebuild error.

## Tests Added

Runtime app tests now cover:

- initial rebuild produces a non-empty snapshot;
- moving east changes the center chunk;
- reset returns to `(0, 0)`;
- repeated rebuild produces the same snapshot hash;
- displayed model stats match the snapshot stats.

Existing UI tests also launched the app successfully during `xcodebuild-safe.sh test`.

## Commands Launched

Only repository safe scripts were used for SwiftPM/Xcode validation.

### `./scripts/swift-test-engine-safe.sh`

Final result: passed, exit code 0.

Exact relevant result:

```text
Executed 55 tests, with 0 failures (0 unexpected)
Test Suite 'All tests' passed
```

### `./scripts/swift-build-all-safe.sh`

Final result: passed, exit code 0.

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

Final result: passed, exit code 0.

Exact relevant result:

```text
Checking safe scripts for forbidden global mutation commands.
Checking EngineCore forbidden imports.
Checking .gitignore local output coverage.
No global mutation patterns detected.
```

### `./scripts/xcodebuild-safe.sh build`

Initial result: failed, exit code 65.

Cause:

- RuntimeApp views used `@ObservedObject` before `Combine` was explicitly imported by the model.
- Some RuntimeApp views accessed `EngineCore`-defined properties without importing `EngineCore`.

Local fix:

- Added `import Combine` to `TelluricDebugRuntimeModel.swift`.
- Added `import EngineCore` to the RuntimeApp views that directly read EngineCore-defined values.

Final result: passed, exit code 0.

Exact relevant result:

```text
Resolved source packages:
  EngineCore: /Users/work/GamesByMe/TelluricEngine/EngineCore @ local

** BUILD SUCCEEDED **
```

### `./scripts/xcodebuild-safe.sh test`

Initial result: failed, exit code 65.

Cause:

- The unit test file accessed `EngineCore`-defined snapshot fields without importing `EngineCore`.

Local fix:

- Added `import EngineCore` to `TelluricRuntimeAppTests.swift`.

Final result: passed, exit code 0.

Exact relevant result:

```text
** TEST SUCCEEDED **
TelluricRuntimeAppTests/initialRebuildProducesNonEmptySnapshot() passed
TelluricRuntimeAppTests/moveEastChangesCenterChunk() passed
TelluricRuntimeAppTests/resetReturnsToOrigin() passed
TelluricRuntimeAppTests/repeatedRebuildIsDeterministic() passed
TelluricRuntimeAppTests/statsMatchSnapshot() passed
TelluricRuntimeAppUITests.testExample() passed
TelluricRuntimeAppUITests.testLaunchPerformance() passed
TelluricRuntimeAppUITestsLaunchTests.testLaunch() passed in Light and Dark appearances
```

## Known Limits

- The visualization is a 2D SwiftUI debug grid only.
- Terrain meshes are not rendered visually.
- There is no Metal device, Metal buffer, shader, RenderGraph, GPU residency, or camera.
- UI colors are diagnostic and not final art direction.
- Runtime cache rebuild is synchronous and intended for small debug radii.
- The app uses a fixed debug seed and config for Phase 5.
- UI launch tests confirm the app launches, but no screenshot pixel inspection was added.

## Technical Risks

- Xcode package integration was added by a minimal `.pbxproj` edit. The project builds and tests after the edit, but future package additions should stay similarly narrow.
- The SwiftUI grid is useful for inspection but will not scale to large radii without virtualization or filtering.
- The debug model owns a synchronous cache; Phase 6 should keep renderer upload separate from this model.

## Confirmations

- `EngineCore` remains pure and was not modified in Phase 5.
- `EngineCore/Sources/EngineCore` still has no SwiftUI, AppKit, Metal, MetalKit, RealityKit, SceneKit, SpriteKit, GameController, GameplayKit, AVFoundation, or simd imports.
- `RenderCoreMetal` was not modified.
- `AudioRuntime` was not modified.
- `TelluricTools`, `Shaders`, and `LocalAssets` were not modified.
- Ruby, Rails, Bundler, Gem, Homebrew, sudo, and global `xcode-select` commands were not used.
- No global shell profile or toolchain configuration was modified.

## Recommended Phase 6

Phase 6 — Metal Debug Terrain Renderer Bridge

Objective Phase 6:

- create the first minimal `RenderCoreMetal` bridge;
- transform `TerrainMeshPayload` CPU data into GPU buffers;
- display a very simple terrain mesh;
- keep the SwiftUI debug grid available;
- avoid building the AAA renderer too early;
- avoid vegetation, complex lighting, and advanced render systems.
