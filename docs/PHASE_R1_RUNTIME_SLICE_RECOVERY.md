# Phase R1 Report - Runtime Slice Recovery

## Summary

Phase R1 recovers the runtime slice from the previous dashboard-heavy shape. The app now has a shared runtime scene that feeds both Game and Debug modes, with Game remaining the default entry point.

The focus was not new gameplay. The work keeps the vertical slice clear:

player input -> player position -> terrain query -> chunk residency -> build cache -> render meshes -> HUD/debug overlays.

No Phase 10 player controller work was started.

## Problem Observed

The existing Game mode was technically functional but visually weak:

- the terrain appeared too small in a mostly black viewport;
- camera defaults could fit the entire terrain too far away;
- chunk streaming changes were not obvious during movement;
- Game and Debug behaved like separate workflows rather than two views of the same runtime;
- the player marker/probe distinction was too easy to miss;
- the Debug dashboard was acting like the main experience.

## Game / Debug / Tooling Separation

Game is now the default mode and keeps the viewport dominant. It exposes a compact HUD with player position, current chunk, visible mesh count, resident count, rebuild count, center-chunk change count, input source, and chunk world size.

Debug still exposes chunk grid, picking, inspector, overlays, wireframe, bounds, normals, probe tools, and terrain toolbar. It now attaches to the same runtime scene when constructed from `TelluricRootView`.

Tooling is still future work. No heavy editor/tool system was added.

## Shared Runtime Scene

Added `TelluricRuntimeScene`, `TelluricRuntimeSceneState`, and the controller alias `TelluricRuntimeSceneController`.

The scene state contains:

- player state;
- camera state;
- input state;
- current center chunk;
- last residency request;
- world cache snapshot;
- build result;
- render mesh descriptors;
- world scale;
- rebuild and center-change counters.

`TelluricRootView` creates one `TelluricGameRuntimeModel` and injects it into the Debug runtime model. Game and Debug therefore read the same player/chunk/snapshot source of truth instead of building unrelated scenes.

Standalone Debug model construction remains supported for tests and direct preview use.

## Scale, Chunk Size, And Camera Defaults

Runtime scale is now explicit through `TelluricRuntimeWorldScale`.

Current default:

- `metersPerSample = 1.0`;
- `samplesPerAxis = 33`;
- `chunkSampleSpan = 32`;
- `chunkWorldSizeMeters = 32`.

Game mode now defaults to `playableCloseFollow`, not a far terrain fit.

The close-follow camera:

- targets the player;
- keeps orthographic scale bounded for readability;
- uses a closer distance than the previous fit behavior;
- preserves an isometric-like pitch so terrain reads as a surface instead of a far-away map.

The Game controls still allow follow, top-down, reset, and focus-on-player.

## Streaming Around Player

Player movement now drives the real runtime chain:

player position -> chunk coord -> residency request -> planner -> build pipeline -> cache -> snapshot -> render mesh descriptors.

When the player crosses a chunk boundary:

- the center chunk updates;
- the world is rebuilt around the player;
- `rebuildCount` increments;
- `centerChunkChangeCount` increments;
- the HUD exposes the change.

This keeps streaming perceptible without adding async, jobs, disk cache, or advanced gameplay.

## Player Marker

The Game viewport uses a larger player marker by default:

- radius: `4.2`;
- height: `14.0`;
- marker enabled in `gamePreview`;
- debug probe marker is disabled when Debug is attached to the shared runtime scene, avoiding a misleading second player-like marker.

The Debug model exposes the runtime player point so the same player marker can be shown in Debug overlays.

## Native Metal Debug Preparation

RenderCoreMetal now labels key Metal resources and draw groups:

- terrain vertex buffers;
- terrain index buffers;
- command buffers;
- render encoder;
- terrain draw debug group;
- debug line draw debug group.

The labels are intentionally lightweight and intended for Xcode GPU Frame Capture / Metal debugger inspection. No custom profiler or heavy tooling was added.

In Xcode GPU Frame Capture, inspect the frame and look for labels such as:

- `telluric-debug-frame-N-command-buffer`;
- `telluric-debug-terrain-render-encoder`;
- `telluric terrain meshes`;
- `telluric debug line overlays`;
- `chunk-X-Z-terrain-vertices`;
- `chunk-X-Z-terrain-indices`.

## Files Created

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Shared/TelluricRuntimeScene.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugResourceLabels.swift`
- `docs/PHASE_R1_RUNTIME_SLICE_RECOVERY.md`

## Files Modified

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugPlayerMarkerConfiguration.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRenderer.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalTerrainMeshUploader.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/RenderCoreMetalInfo.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugDisplayOptionsTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalTerrainMeshUploaderTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameCameraMode.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameHUDView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameRuntimeView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Shared/TelluricRootView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugStatusView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

The Xcode project structure was not manually changed. `project.pbxproj` was not modified. Local Xcode `xcuserdata` files may be touched by Xcode itself during build/test.

## Tests Added Or Updated

RuntimeApp tests now cover:

- Game and Debug sharing the same runtime scene source of truth;
- Game as default runtime mode;
- stable world scale and chunk size config;
- playable close-follow camera default;
- visible player marker by default in Game preview;
- player movement crossing a chunk boundary updates center chunk and snapshot;
- shared Debug mode using the runtime player marker instead of an independent probe marker.

RenderCoreMetal tests now cover:

- stable native Metal resource label generation;
- upload buffer labels for terrain vertex/index buffers;
- larger default player marker in game preview;
- Phase R1 status export.

Existing EngineCore import guards remain covered by the safe scripts.

## Commands Run

`./scripts/swift-test-engine-safe.sh`

Result: passed. EngineCore completed 76 tests with 0 failures.

`./scripts/swift-test-render-safe.sh`

Result: passed. RenderCoreMetal completed 34 tests with 0 failures.

`./scripts/swift-build-all-safe.sh`

Result: passed. EngineCore, RenderCoreMetal, and AudioRuntime all built. Output ended with `All Swift packages built.`

`./scripts/verify-no-global-mutations.sh`

Result: passed. Output ended with `No global mutation patterns detected.`

`./scripts/xcodebuild-safe.sh build`

Result: passed. Output ended with `** BUILD SUCCEEDED **`.

`./scripts/xcodebuild-safe.sh test`

Result: passed. Output ended with `** TEST SUCCEEDED **`.

Observed Xcode test counts:

- RuntimeApp unit tests: 44 passed, 0 failures;
- RuntimeApp UI tests: 4 passed, 0 failures.

## Limits

- Camera is still a debug/game-preview camera, not a final gameplay camera.
- Player movement remains simple and discrete enough for the runtime slice; no continuous Phase 10 controller was added.
- Streaming rebuilds are synchronous.
- Terrain readability still depends on the current procedural profile from Phase 9.6; this phase improved framing, scale, and shared scene behavior rather than adding a new terrain system.
- Metal labels prepare native inspection but do not replace Xcode GPU debugging tools.
- Debug overlays remain custom only for engine data such as chunk state, bounds, normals, picking, and player marker.

## Safety Confirmations

- EngineCore remains pure: no SwiftUI, AppKit, Metal, MetalKit, or simd imports were added.
- RenderCoreMetal still does not depend on RuntimeApp.
- AudioRuntime was not modified.
- No dependency was added.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo, or xcode-select global command was used.
- No global Xcode configuration was changed.
- No Phase 10 gameplay-advanced work was started.

## Phase 10 Recommendation

Phase 10 should only start after a human visual check confirms:

- Game mode opens first and reads as the main experience;
- terrain occupies most of the viewport;
- player marker is visible immediately;
- moving the player changes the current chunk and visible runtime state;
- Debug mode shows the same scene rather than a separate world.

Recommended Phase 10 after that validation: Debug Player Controller + Camera Follow Prototype, limited to continuous input polish and camera follow behavior, without physics, animation, vegetation, or AAA rendering.
