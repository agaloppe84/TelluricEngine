# Phase R2 Report - Runtime Cleanup + Vertical Slice Rebuild

## Initial Problem

The runtime had drifted toward a heavy debug dashboard. The dashboard was useful for isolated inspection but it was starting to drive the architecture like a second app.

The visible result was not a strong vertical slice:

- Game was better than the dashboard, but still visually too distant;
- terrain could feel like a small island in a dark viewport;
- chunk streaming was hard to perceive;
- changing chunks could trigger heavy Metal buffer churn;
- Debug UI mixed runtime, tooling, probing, picking, and panels too aggressively.

R2 resets the direction:

Game first. Debug as overlays. Tooling later. Native Metal debugging where possible.

## Cleanup Decisions

- `ContentView` still enters through `TelluricRootView`.
- `TelluricRootView` now routes directly to `TelluricGameRuntimeView`.
- The segmented Game/Debug router is removed from the primary UI path.
- The old dashboard code remains compiled as legacy/debug support to avoid a risky Xcode/file-group refactor, but it is no longer the main runtime route.
- Debug controls useful during play are represented as optional overlays on the Game scene.

## Debug View Status

The separate dashboard is neutralized in the primary flow.

It was not physically deleted because the project uses file-system synchronized groups and the dashboard still has broad existing test coverage. Removing it now would be more risky than making it inaccessible from `ContentView`.

Current primary app flow:

```text
ContentView
  -> TelluricRootView
     -> TelluricGameRuntimeView
```

The dashboard remains as legacy code, not as the runtime architecture.

## Runtime Architecture

`TelluricRuntimeScene` remains the shared runtime concept and now carries more runtime state:

- player state;
- camera state;
- input state;
- center chunk;
- residency request;
- snapshot;
- render mesh descriptors;
- world scale;
- rebuild counters;
- streaming update summary;
- debug overlay enabled flag.

`TelluricGameRuntimeModel` is the current `TelluricRuntimeSceneController`. Debug overlays read the same model directly, not an independent dashboard scene.

## GameView Default

Game is the default and only primary route.

`TelluricGameRuntimeView` contains:

- full-window Metal viewport;
- minimal HUD;
- player marker;
- close-follow camera;
- keyboard/controller input path;
- optional debug overlay panel;
- compact top-right controls.

There is no chunk grid or inspector dashboard in the default view.

## World Scale

`TelluricRuntimeWorldScale` now documents runtime scale decisions:

- `metersPerSample = 1.0`;
- `chunkSampleSpan = 32`;
- `chunkWorldSizeMeters = 32`;
- `terrainVerticalScale = 1.0`;
- `renderVerticalScale = 1.0`;
- `playerHeightMeters = 1.8`;
- `playerRadiusMeters = 0.45`;
- `defaultCameraDistance = 42`;
- `defaultCameraPitch = 0.72`.

This is still a simple debug/playable scale, but it is now explicit and test-covered.

## Camera

The default camera remains `playableCloseFollow`, but it is now closer:

- orthographic scale is capped tighter for the default;
- default distance is around `42` meters for the current chunk scale;
- far plane is reduced from the earlier broad fit behavior;
- reset/focus returns to the player rather than a global terrain fit.

The intent is to frame the player and nearby chunks, not the entire residency square.

## Player

The player marker remains separate from the debug probe. In Game preview:

- marker is enabled by default;
- marker size is derived from runtime player scale;
- marker remains visible without enabling debug overlays;
- debug probe marker is not part of the Game primary UI.

## Streaming Incremental Summary

R2 adds `TelluricRuntimeStreamingUpdateSummary`.

Each residency rebuild now records:

- previous center chunk;
- current center chunk;
- added chunks;
- kept chunks;
- evicted chunks;
- created records;
- updated records;
- reused records;
- whether the update looked like a full rebuild.

When the player crosses a chunk boundary, tests verify:

- center chunk changes;
- snapshot changes;
- chunks are kept across the transition;
- chunks are added and evicted;
- the update is not reported as a full rebuild.

CPU-side `ChunkBuildPipeline` was already capable of record reuse through `InMemoryWorldCache`; R2 exposes that behavior through runtime state and HUD/debug overlay.

## Metal Buffer Reuse

Added `MetalTerrainBufferCache` and `MetalTerrainBufferCacheUpdate`.

Buffers are keyed by:

- chunk identity;
- mesh stable hash;
- lifecycle state;
- color mode;
- render mode;
- selection state;
- vertical scale;
- debug name.

The renderer now updates mesh buffers through this cache:

- unchanged mesh descriptors reuse existing buffers;
- changed descriptors create new buffers;
- removed chunks are evicted;
- draw order follows the incoming stable descriptor order.

This reduces the previous clear/reupload-all behavior when the global upload hash changes due to player movement or center chunk updates.

## Native Metal Debug

R1 labels remain in place:

- command buffer labels;
- render encoder labels;
- terrain draw debug group;
- debug line draw debug group;
- terrain vertex/index buffer labels by chunk/debug name.

R2 keeps the direction: use Xcode GPU Frame Capture / Metal Debugger for GPU-level inspection. Custom overlays are reserved for engine data.

In Xcode GPU Frame Capture, inspect:

- `telluric-debug-frame-N-command-buffer`;
- `telluric-debug-terrain-render-encoder`;
- `telluric terrain meshes`;
- `telluric debug line overlays`;
- `game-chunk-X-Z-terrain-vertices`;
- `game-chunk-X-Z-terrain-indices`.

## Overlays Conserved

Game debug overlays are off by default.

Available from the compact Game controls:

- debug overlay panel;
- wireframe;
- bounds;
- normals;
- grid.

The overlay panel reports:

- overlay state;
- frame time;
- vertex/index counts;
- streaming add/keep/evict summary;
- full rebuild yes/no.

The old dashboard features remain legacy-only and are not part of the primary runtime loop.

## Files Created

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalTerrainBufferCache.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalTerrainBufferCacheUpdate.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricRuntimeDebugOverlayView.swift`
- `docs/PHASE_R2_RUNTIME_CLEANUP_VERTICAL_SLICE.md`

## Files Modified

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRenderer.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRendererConfiguration.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/RenderCoreMetalInfo.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalTerrainMeshUploaderTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameHUDView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Game/TelluricGameRuntimeView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Shared/TelluricRootView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/Shared/TelluricRuntimeScene.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

No `project.pbxproj` edit was made. Local `xcuserdata` files may be touched by Xcode during build/test.

## Tests Added Or Updated

RuntimeApp:

- Game view is default and separate Debug dashboard is not primary;
- Runtime scene exposes debug overlay state;
- debug overlays are off by default and use the Game scene when enabled;
- default camera is close follow and closer than the earlier broad fit;
- world scale is stable and documented by the model;
- player marker follows runtime scale;
- crossing a chunk boundary reports added/kept/evicted chunks and not a full rebuild.

RenderCoreMetal:

- buffer cache reuses unchanged mesh buffers;
- buffer cache creates new buffers when descriptor state changes;
- buffer cache evicts removed chunks;
- resource labels remain stable;
- Phase R2 status is exported.

EngineCore:

- no EngineCore code was modified in R2;
- existing EngineCore import guards and terrain/cache tests still pass.

## Commands Run

`./scripts/swift-test-engine-safe.sh`

Result: passed.

- EngineCore tests: 76 tests, 0 failures.

`./scripts/swift-test-render-safe.sh`

Result: passed.

- RenderCoreMetal tests: 37 tests, 0 failures.

`./scripts/swift-build-all-safe.sh`

Result: passed.

- EngineCore built.
- RenderCoreMetal built.
- AudioRuntime built.
- Final output: `All Swift packages built.`

`./scripts/verify-no-global-mutations.sh`

Result: passed.

- Final output: `No global mutation patterns detected.`

`./scripts/xcodebuild-safe.sh build`

First run failed because `displayOptions` needed an explicit `return` after adding a local `let`.

Fixed locally.

Final result: passed.

- Final output: `** BUILD SUCCEEDED **`.

`./scripts/xcodebuild-safe.sh test`

Result: passed.

- RuntimeApp unit tests: 44 tests, 0 failures.
- RuntimeApp UI tests: 4 tests, 0 failures.
- Final output: `** TEST SUCCEEDED **`.

## Known Limits

- Visual confirmation by a human is still required. Code and tests can verify routing, scale, counters, and reuse, but not whether the viewport feels good enough.
- Streaming remains synchronous. R2 reduces avoidable rebuild/reupload churn but does not introduce async or per-frame budgets.
- The old dashboard still exists as legacy compiled code. It is neutralized from the primary route, not deleted.
- The player is still a line marker, not a character.
- Camera follow is still a debug/playable camera, not final gameplay camera logic.
- No PS5-specific deeper controller behavior was added; existing GameController input path remains minimal.

## What Remains To Correct

- Validate the Game viewport visually on device.
- If chunk changes still hitch noticeably, add a per-frame streaming budget before any gameplay expansion.
- Consider deleting or moving legacy dashboard files only after Game overlays cover all necessary runtime inspection.
- Improve input smoothness only after the visual runtime slice is accepted.

## Safety Confirmations

- EngineCore remains pure.
- EngineCore has no SwiftUI, AppKit, Metal, MetalKit, GameController, or simd imports added by R2.
- RenderCoreMetal still does not depend on RuntimeApp.
- AudioRuntime was not modified.
- TelluricTools and LocalAssets were not modified.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo, or global xcode-select command was used.
- No global shell or tool configuration was modified.
- No Phase 10 gameplay work was started.

## Recommendation

If R2 is visually validated by a human:

**Phase R3 - Continuous Movement Polish + Streaming Budget**

Scope:

- smooth continuous keyboard/controller movement;
- budget chunk build/upload work per frame;
- preserve synchronous fallback path;
- keep debug overlays lightweight;
- no physics, animation, vegetation, or renderer AAA.

If R2 is not visually acceptable:

create a fresh minimal RuntimeApp surface using the existing EngineCore and RenderCoreMetal packages, without carrying the legacy dashboard UI forward.
