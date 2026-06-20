# Phase 9.6 Report - Playable Runtime Slice + Debug Separation

## Summary

Phase 9.6 replaces the planned Phase 10 with a smaller architectural and usability correction. The RuntimeApp now has a clear Game / Debug split, with Game selected by default.

Game mode is a playable runtime slice:

- large Metal viewport first;
- debug dashboard hidden by default;
- debug-playable terrain profile with low relief;
- visible player marker separate from the debug probe;
- keyboard movement;
- basic GameController / PS5-compatible input path;
- follow/top camera modes;
- synchronous chunk residency rebuild around the player;
- compact HUD with FPS, chunks, player position and input source.

Debug mode keeps the Phase 9.5 dashboard, including grid, stats, picking, inspector, wireframe, bounds, normals and probe tools.

## Initial Problem

The Phase 9.5 app was technically useful but still mixed gameplay, tooling and debug inspection. The Metal viewport could look like a vertical histogram because the default procedural terrain had high amplitude, and the player probe was a debug marker rather than a readable player surrogate.

The result was not a good first runtime slice. It was hard to understand what was game view, what was debug dashboard, and whether chunk streaming around a moving player was actually being exercised.

## Separation: Game / Debug / Tooling

Implemented:

- `ContentView` now routes to `TelluricRootView`.
- `TelluricRootView` owns a segmented `Game` / `Debug` mode switch.
- `Game` is the default mode.
- `Debug` wraps the existing dashboard through `TelluricDebugDashboardView`.
- New RuntimeApp source folders separate `Game`, `Debug` and `Shared` code.

Tooling/editor mode is intentionally not implemented in Phase 9.6. The split leaves room for future tooling without making it part of the runtime surface now.

## Files Created

EngineCore:

- `EngineCore/Sources/EngineCore/TerrainGenerationProfile.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainGenerationProfileTests.swift`

RenderCoreMetal:

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalTerrainRenderMode.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugPlayerMarkerConfiguration.swift`

RuntimeApp:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Shared/TelluricRuntimeMode.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Shared/TelluricRootView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Debug/TelluricDebugDashboardView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameRuntimeView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameHUDView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameInputState.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameKeyboardCaptureView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameControllerInput.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameCameraMode.swift`

Docs:

- `docs/PHASE_9_6_REPORT.md`

## Files Modified

EngineCore:

- `ChunkBuildPipeline.swift`
- `ChunkTerrainSamplePayload.swift`
- `TerrainChunkSampler.swift`
- `TerrainMeshBuilder.swift`
- `TerrainScalarField.swift`
- `WorldChunkID.swift`
- `WorldResidencyPlanner.swift`
- `WorldResidencyRequest.swift`

RenderCoreMetal:

- `MetalDebugLineBuilder.swift`
- `MetalDebugRenderer.swift`
- `MetalDebugTerrainColorMode.swift`
- `MetalDebugTerrainDisplayOptions.swift`
- `MetalTerrainMeshDescriptor.swift`
- `MetalTerrainMeshUploader.swift`
- `RenderCoreMetalInfo.swift`

RuntimeApp:

- `ContentView.swift`
- `TelluricMetalDebugCoordinator.swift`
- `TelluricMetalDebugView.swift`
- `TelluricMetalViewRepresentable.swift`
- `TelluricRuntimeAppTests.swift`

Tests:

- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugDisplayOptionsTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalTerrainMeshUploaderTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

Xcode:

- No `project.pbxproj` edit was made.
- No package integration change was needed because the project uses file-system synchronized groups.
- Local `xcuserdata` files were already dirty and remained local/generated Xcode state.

## Terrain Playable Profile

Added `TerrainGenerationProfile` in EngineCore:

- `defaultProcedural`
- `debugPlayable`

`debugPlayable` uses deterministic coherent value noise with low frequency and low height amplitude:

- height range: 10 meters total;
- softer broad/detail blend;
- deterministic hash inputs;
- stable across chunks and seeds;
- suitable for a first playable debug slice.

The previous `defaultProcedural` payload hash contract was preserved. The existing stable hash test for default terrain still passes.

## Render Game Preview

Added `MetalTerrainRenderMode`:

- `debug`
- `gamePreview`

`gamePreview` uses:

- surface-oriented natural colors;
- no bounds by default;
- no normals by default;
- no grid by default;
- no wireframe by default;
- player marker enabled by default;
- no probe marker by default.

The debug dashboard keeps the Phase 9.5 debug display options.

## Player Marker

Added `MetalDebugPlayerMarkerConfiguration` and player marker line generation.

The marker is separate from the Phase 9 debug probe:

- brighter game/player marker;
- vertical beacon plus base diamond and heading line;
- generated as debug line vertices;
- included in `MetalDebugRenderer` line passes;
- visible in Game mode by default.

## Input

Keyboard:

- arrow keys;
- WASD;
- ZQSD for AZERTY-friendly movement.

GameController / PS5:

- RuntimeApp imports `GameController`.
- `TelluricGameControllerInput` detects connected controllers.
- It reads the extended gamepad left thumbstick with a deadzone.
- Movement is event-driven and minimal.

This is not a continuous final player controller. It is a debug/runtime movement input layer only.

## Game Camera

Added `TelluricGameCameraMode`:

- `followIso`
- `topDown`
- `freeOrbit`

Default:

- `followIso`
- camera target follows the player;
- orthographic scale is constrained to readable bounds.

Controls:

- Follow
- Top
- Reset camera
- scroll zoom through the existing Metal view bridge
- basic drag-orbit hook through the existing bridge

## Streaming Around Player

`TelluricGameRuntimeModel` drives the real CPU pipeline:

1. player position
2. `WorldChunkCoord`
3. `WorldResidencyRequest`
4. `WorldResidencyPlanner.makePlan`
5. `ChunkBuildPipeline.apply`
6. `InMemoryWorldCache`
7. `ResidentWorldSnapshot`
8. mesh descriptors for Metal

When the player crosses a chunk boundary, the model rebuilds residency around the new center chunk. This is synchronous and intentionally simple for Phase 9.6.

The Game config uses:

- active radius: 0
- resident radius: 1
- mesh radius: 2
- sample radius: 3
- eviction radius: 4

This gives a readable HUD split between active, resident and meshed chunks.

## Tests Added

EngineCore:

- debug playable profile determinism;
- profile changes generation signature;
- bounded height range;
- grounded/walkable center query;
- slopes mostly reasonable;
- forbidden imports remain absent.

RenderCoreMetal:

- `gamePreview` options disable heavy debug overlays;
- player marker line generation is stable;
- `gamePreview` color generation differs from debug mode;
- Phase 9.6 status marker.

RuntimeApp:

- default runtime mode is Game;
- Debug mode remains available;
- Game model builds an initial snapshot;
- Game player starts grounded and walkable;
- moving player changes x/z and updates terrain height;
- crossing chunk boundary updates center chunk and snapshot;
- keyboard input mutates movement intent;
- controller input layer initializes safely;
- HUD stats are non-empty.

## Commands Run

`./scripts/swift-test-engine-safe.sh`

Result:

- `EngineCorePackageTests.xctest` passed.
- Executed 76 tests, 0 failures.

`./scripts/swift-test-render-safe.sh`

Result:

- `RenderCoreMetalPackageTests.xctest` passed.
- Executed 33 tests, 0 failures.

`./scripts/swift-build-all-safe.sh`

Result:

- EngineCore built.
- RenderCoreMetal built.
- AudioRuntime built.
- `All Swift packages built.`

`./scripts/verify-no-global-mutations.sh`

Result:

- checked safe scripts;
- checked EngineCore forbidden imports;
- checked `.gitignore` local output coverage;
- `No global mutation patterns detected.`

`./scripts/xcodebuild-safe.sh build`

Result:

- Project: `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj`
- Scheme: `TelluricRuntimeApp`
- DerivedData: `.derivedData/TelluricRuntimeApp`
- `** BUILD SUCCEEDED **`

`./scripts/xcodebuild-safe.sh test`

Result:

- `** TEST SUCCEEDED **`
- RuntimeApp unit tests passed, including Phase 9.6 Game mode tests.
- RuntimeApp UI tests passed: 4 tests, 0 failures.

Note: the first `xcodebuild-safe.sh test` run failed one new HUD assertion because `activeRadiusChunks` and `residentRadiusChunks` were equal, leaving no distinct resident ring. The Game config was corrected to `activeRadiusChunks = 0`, `residentRadiusChunks = 1`, then the full safe Xcode test command passed.

## Known Limits

- Game mode movement is step-based/event-based, not a final continuous player controller.
- GameController support is minimal: connected controller detection plus left thumbstick movement path.
- No physics, gravity, capsule collision, animation or gameplay controller was added.
- Terrain profile is a debug-playable profile, not a final biome/terrain solution.
- Camera controls are intentionally simple.
- Chunk rebuild is synchronous.
- The player marker is line-based debug geometry, not a final character representation.
- Visual validation still needs a human pass in the app.

## Safety Confirmations

- EngineCore remains pure CPU/data code.
- EngineCore has no `SwiftUI`, `AppKit`, `Metal`, `MetalKit`, `GameController` or `simd` imports.
- GameController is used only in RuntimeApp.
- AudioRuntime was not modified.
- TelluricTools and LocalAssets were not modified.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo or global `xcode-select` command was used.
- No global shell or tool configuration was modified.
- No Phase 10 player controller work was started.

## Recommendation for Phase 10

Do not start Phase 10 until a human validates the Phase 9.6 app visually:

- terrain is readable in Game mode;
- player marker is clearly visible;
- keyboard movement works;
- connected controller movement path works where available;
- camera follow/top modes are usable;
- chunks visibly update around the player;
- Debug mode still exposes the full Phase 9.5 dashboard.

If those checks pass, Phase 10 can become:

`Phase 10 - Debug Player Controller + Camera Follow Prototype`

Scope should still stay limited:

- continuous keyboard input;
- smoother camera follow;
- simple velocity and grounded state;
- no animation;
- no advanced physics;
- no AAA rendering.
