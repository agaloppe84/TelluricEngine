# Phase 9 Report - Terrain Collision Query + Player Probe Prototype

## Summary

Phase 9 adds deterministic CPU terrain queries in `EngineCore` and uses them in `RuntimeApp` to drive a debug player probe constrained to terrain height.

The implemented path is:

```text
ResidentWorldSnapshot
  -> TerrainQueryEngine
  -> TerrainQueryResult
  -> TerrainProbeController
  -> RuntimeApp player probe controls
  -> RenderCoreMetal debug probe marker
```

This is a debug/player-probe foundation, not final gameplay, physics, animation, dynamic collision, or a production character controller.

## Files Created

EngineCore:

- `EngineCore/Sources/EngineCore/TerrainWorldPosition.swift`
- `EngineCore/Sources/EngineCore/TerrainQueryMode.swift`
- `EngineCore/Sources/EngineCore/TerrainQueryRequest.swift`
- `EngineCore/Sources/EngineCore/TerrainQuerySurfaceResult.swift`
- `EngineCore/Sources/EngineCore/TerrainSlopeClassification.swift`
- `EngineCore/Sources/EngineCore/TerrainWalkability.swift`
- `EngineCore/Sources/EngineCore/TerrainQueryError.swift`
- `EngineCore/Sources/EngineCore/TerrainQueryResult.swift`
- `EngineCore/Sources/EngineCore/TerrainQueryEngine.swift`
- `EngineCore/Sources/EngineCore/TerrainProbeConfiguration.swift`
- `EngineCore/Sources/EngineCore/TerrainProbe.swift`
- `EngineCore/Sources/EngineCore/TerrainProbeMoveRequest.swift`
- `EngineCore/Sources/EngineCore/TerrainProbeMoveResult.swift`
- `EngineCore/Sources/EngineCore/TerrainProbeController.swift`

EngineCore tests:

- `EngineCore/Tests/EngineCoreTests/TerrainQueryEngineTests.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainWalkabilityTests.swift`
- `EngineCore/Tests/EngineCoreTests/TerrainProbeControllerTests.swift`

RenderCoreMetal:

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugProbeMarkerConfiguration.swift`

RuntimeApp:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricPlayerProbeControlsView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricPlayerProbeInspectorView.swift`

Documentation:

- `docs/PHASE_9_REPORT.md`

## Files Modified

RenderCoreMetal:

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugLineBuilder.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRenderer.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugTerrainDisplayOptions.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/RenderCoreMetalInfo.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugDisplayOptionsTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`

RuntimeApp:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugCoordinator.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugOverlayView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugToolbarView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalViewRepresentable.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

## Xcode Changes

No `project.pbxproj` modification was required. The RuntimeApp target uses file-system-synchronized groups, so the new RuntimeApp Swift files were picked up without manual Xcode project editing.

The user-specific file below was already dirty before Phase 9 work and remains outside the intended implementation:

```text
RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj/project.xcworkspace/xcuserdata/work.xcuserdatad/UserInterfaceState.xcuserstate
```

No package integration was added or removed.

## Terrain Query Architecture

`TerrainQueryEngine` is pure `EngineCore` and reads a `ResidentWorldSnapshot`. It searches the snapshot's stable sorted cached records for mesh payloads containing the requested world `x/z` coordinate.

The query result includes:

- world position;
- nearest terrain sample coordinate;
- height in meters;
- normal;
- surface material;
- physical surface tag;
- audio surface tag;
- slope radians/degrees/normalized value;
- slope classification;
- walkability;
- inside/outside known-terrain state;
- source chunk ID and mesh hash when available;
- stable hash.

No disk cache, BVH, async job system, GPU picking, or RenderCoreMetal dependency was added to EngineCore.

## Height Query Strategy

The default mode is `bilinearHeightfield`.

For a matching mesh payload:

1. derive the local sample-grid position from world `x/z`;
2. clamp to the mesh cell range;
3. read the four cell vertices from the row-major terrain mesh;
4. bilinearly interpolate height;
5. choose the nearest of the four vertices for surface tags and sample identity.

`nearestVertex` is also exposed as a deterministic fallback/debug query mode.

## Normal And Slope Strategy

Normals are interpolated from the four surrounding mesh vertex normals in bilinear mode, then normalized with `TEVec3f`.

Slope is computed from the angle between the query normal and `TEVec3f.up`:

```text
slopeRadians = acos(clamp(normal.y, -1, 1))
slopeDegrees = slopeRadians * 180 / pi
slope01 = clamp(slopeDegrees / 90, 0, 1)
```

`TerrainSlopeClassification` maps slopes into `flat`, `gentle`, `moderate`, `steep`, `extreme`, or `unknown`.

## Surface Query Strategy

Phase 9 returns the surface of the nearest vertex/sample around the query point. This keeps the query deterministic and directly tied to the Phase 2 surface payload.

Surface blending is intentionally deferred.

## Walkability Strategy

`TerrainWalkabilityConfig` provides:

- `maxWalkableSlopeDegrees`, default `35`;
- `mudIsWalkable`, default `true`;
- `shallowWaterIsWalkable`, default `false`.

Rules:

- outside known terrain -> not walkable, `outsideKnownTerrain`;
- missing/invalid data -> not walkable, `unknown`;
- slope above threshold -> not walkable, `tooSteep`;
- shallow water -> follows `shallowWaterIsWalkable`;
- mud -> follows `mudIsWalkable`;
- all other minimal surfaces are walkable when slope allows.

## TerrainProbe Architecture

`TerrainProbe` is pure EngineCore data:

- stable ID;
- world position;
- last terrain query result;
- grounded state;
- walkability;
- stable hash.

`TerrainProbeController` can place or move a probe in `x/z`, query terrain, and set `y` to the terrain height. It does not apply gravity, velocity, capsules, sliding, dynamic collision, animation, or a gameplay input model.

By default Phase 9 allows non-walkable movement but reports walkability. This keeps the debug probe useful for inspecting steep/water/mud/outside areas without pretending to be a final controller.

## RuntimeApp Probe Controls

RuntimeApp now exposes:

- show/hide probe toggle;
- probe step size slider;
- move north/south/east/west buttons;
- reset probe button;
- `Move to pick` button using the last Phase 8 picked terrain point;
- probe inspector with position, height, slope, walkability, surface tags, inside/outside state and stable hash.

The Phase 8 Metal click continues to select/inspect terrain. Moving the probe to a picked point is an explicit action to avoid ambiguous click behavior.

## Probe Marker Metal Strategy

RenderCoreMetal adds `MetalDebugProbeMarkerConfiguration` and line generation through `MetalDebugLineBuilder`.

The marker is a small debug-only line cross/vertical marker at the probe world position. It reuses the existing debug line renderer; no new shader or mesh renderer was added.

`MetalDebugRenderer.updateMeshes` now accepts an optional `probePoint`, and frame line stats include probe marker vertices.

## Tests Added

EngineCore:

- deterministic terrain query results for repeated requests;
- inside known terrain returns finite height/normal/surface/slope;
- outside known terrain returns a clean outside result;
- bilinear interpolation at a cell center;
- nearest-vertex fallback behavior;
- shared-edge query consistency across neighboring snapshots;
- walkability rules for low slope, steep slope, shallow water, mud and outside terrain;
- slope classification;
- probe placement snaps to terrain height;
- probe movement updates x/z/y and propagates walkability;
- repeated probe movement is deterministic;
- outside probe movement is handled without crash.

RenderCoreMetal:

- display options include probe marker state;
- probe marker line generation count is stable;
- disabled probe marker emits no lines;
- module info exposes Phase 9 status.

RuntimeApp:

- initial model creates a grounded player probe;
- moving the probe updates position and terrain query;
- reset probe works;
- `Move to pick` uses the Phase 8 picked point;
- probe toggle updates render options;
- existing picking, camera and mesh tests remain valid.

## Safe Scripts Added Or Modified

No safe script was added or modified in Phase 9.

## Commands Run And Results

`./scripts/swift-test-engine-safe.sh`

- Result: passed
- EngineCore tests: 71 tests, 0 failures

`./scripts/swift-test-render-safe.sh`

- Result: passed
- RenderCoreMetal tests: 27 tests, 0 failures

`./scripts/swift-build-all-safe.sh`

- Result: passed
- EngineCore build: complete
- RenderCoreMetal build: complete
- AudioRuntime build: complete
- Final output: `All Swift packages built.`

`./scripts/verify-no-global-mutations.sh`

- Result: passed
- Final output: `No global mutation patterns detected.`

`./scripts/xcodebuild-safe.sh build`

- Result: passed
- Final output: `** BUILD SUCCEEDED **`

`./scripts/xcodebuild-safe.sh test`

- Result: passed
- Final output: `** TEST SUCCEEDED **`
- RuntimeApp unit tests observed: 25 passed
- RuntimeApp UI tests observed: 4 passed

## Known Limits

- Terrain query is heightfield-based and CPU-only.
- Surface query uses nearest vertex/sample tags; no surface blending yet.
- No ray/triangle production collision.
- No BVH or spatial acceleration.
- No dynamic collision, capsule, step height, sliding, gravity, velocity, animation, or gameplay controller.
- Probe movement is discrete button-driven debug movement.
- Probe marker is a debug line overlay, not a rendered character.

## Technical Risks

- Querying scans current snapshot records, which is fine for the debug radius but will need indexing when worlds grow.
- Bilinear heightfield queries match current terrain topology, but future caves/overhangs will need a richer collision representation.
- The probe intentionally allows non-walkable movement by default, so gameplay code must not treat it as final movement authority.

## Safety Confirmations

- EngineCore remains pure and contains no SwiftUI, AppKit, Metal, MetalKit, RealityKit, SceneKit, SpriteKit, GameController, GameplayKit, AVFoundation, or simd import.
- RenderCoreMetal remains the only module using Metal/MetalKit/simd.
- AudioRuntime was not modified.
- TelluricTools and LocalAssets were not modified.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo, or global xcode-select command was used.
- No global shell profile or toolchain configuration was modified.
- Xcode DerivedData stayed local under `.derivedData/TelluricRuntimeApp`.

## Phase 10 Proposal

Phase 10 - Debug Player Controller + Camera Follow Prototype

Objective:

- transform the probe into a debug player controller prototype;
- add continuous keyboard movement;
- add simple camera follow;
- keep CPU collision simple;
- display velocity, slope and grounded state;
- prepare gameplay input;
- avoid animation, full physics and AAA rendering.
