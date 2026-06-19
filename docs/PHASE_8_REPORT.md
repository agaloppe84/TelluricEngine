# Phase 8 Report - Terrain Interaction + Debug Picking Refinement

## Summary

Phase 8 makes the Metal debug viewport directly inspectable. The developer can now hover or click in the viewport, resolve a CPU debug picking hit, select the matching chunk, inspect the nearest terrain vertex and surface tags, show a chunk/world grid overlay, and display a picked-point marker.

This remains a debug tool, not the production renderer. No texture system, shadows, lighting stack, vegetation renderer, render graph, GPU picking, async streaming, gameplay, or physics system was added.

## Files Created

RenderCoreMetal:

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugAABBIntersection.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugGridConfiguration.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugPickedPointMarkerConfiguration.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugPickingController.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugPickingHit.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugPickingMissReason.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugPickingResult.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRay.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugScreenPoint.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugWorldPoint.swift`

RuntimeApp:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricInteractiveMTKView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricTerrainInspectionState.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricTerrainInspectionView.swift`

Tests and docs:

- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugPickingTests.swift`
- `docs/PHASE_8_REPORT.md`

## Files Modified

RenderCoreMetal:

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugLineBuilder.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRenderer.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugTerrainDisplayOptions.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/RenderCoreMetalInfo.swift`

RuntimeApp:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugCoordinator.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugOverlayView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugToolbarView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalViewRepresentable.swift`

Tests:

- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugDisplayOptionsTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

## Xcode Changes

No `project.pbxproj` change was required. The existing file-system-synchronized app group and existing local package integration from earlier phases picked up the new RuntimeApp files.

No new package was added, no scheme was changed, and AudioRuntime was not integrated.

## Picking Architecture

Picking lives in RenderCoreMetal as CPU debug math:

```text
screen point
  -> normalized device coordinates
  -> inverse view-projection
  -> MetalDebugRay
  -> ray / chunk AABB
  -> nearest visible hit
  -> nearest terrain vertex/sample inspection
```

RuntimeApp owns input events and selection state. RenderCoreMetal does not depend on RuntimeApp.

## Screen Point To World Ray

`MetalDebugPickingController.makeRay` converts a viewport point into normalized device coordinates, inverts the current `MetalDebugCamera` view-projection matrix, and builds a normalized `MetalDebugRay` from near/far clip points.

Invalid viewport sizes or degenerate rays return `nil` and become explicit miss reasons.

## Ray / AABB Strategy

`MetalDebugAABBIntersection` performs a slab-style ray/AABB test against `TerrainMeshBounds`.

It handles:

- rays parallel to an axis;
- origins inside the box;
- no-hit cases;
- finite distance validation.

The closest positive hit is used. If multiple chunk bounds produce the same distance, sorting is stable by chunk coordinate, mesh hash, then nearest vertex index.

## Nearest Vertex / Sample Strategy

After a chunk bounds hit, Phase 8 finds the closest `TerrainMeshVertex` in the hit mesh to the approximate world hit point. The inspection result carries:

- picked world position;
- nearest vertex position;
- nearest vertex normal;
- nearest vertex index;
- nearest `TerrainSampleCoord`;
- height;
- surface material;
- physical surface tag;
- audio surface tag;
- mesh stable hash.

This is intentionally debug picking, not final terrain collision.

## Unified Selection Strategy

`TelluricDebugRuntimeModel` remains the source of truth for selection.

- Clicking the SwiftUI grid selects a chunk.
- Clicking the Metal viewport selects the picked chunk.
- Clearing selection clears both selected chunk and terrain inspection.
- The selected chunk is highlighted in the SwiftUI grid and in Metal through the existing selected descriptor color path.

There is no parallel selection system.

## Hover / Click Strategy

`TelluricInteractiveMTKView` captures AppKit events from the embedded `MTKView`:

- hover updates terrain inspection;
- click performs picking and selects the hit chunk;
- scroll zooms the debug camera;
- left drag orbits the camera;
- option-drag or right drag pans the camera.

Picking can be disabled with the RuntimeApp `Picking` toggle without disabling camera controls.

## Grid Overlay Strategy

`MetalDebugGridConfiguration` and `MetalDebugLineBuilder.makeGridLineVertices` generate debug grid lines from mesh bounds. The grid uses unique sorted chunk boundary coordinates and draws lines on a plane slightly above the rendered terrain bounds.

The RuntimeApp toolbar exposes a `Grid` toggle. The grid reuses the Phase 7 debug line shader.

## Picked Point Marker Strategy

`MetalDebugPickedPointMarkerConfiguration` draws a small 3-axis cross at the picked world point using debug lines. The RuntimeApp toolbar exposes a `Pick point` toggle.

The marker follows hover/click inspection state. No shader change was needed.

## Mouse / Trackpad Controls Added

- click: viewport picking and chunk selection;
- hover: point inspection;
- scroll wheel / trackpad scroll: zoom;
- left drag: orbit camera;
- option-left-drag or right drag: pan camera.

The Phase 7 button controls remain available.

## Tests Added

RenderCoreMetal:

- ray direction normalization;
- invalid viewport ray/miss handling;
- ray/AABB hit distance;
- ray/AABB miss;
- ray from inside AABB;
- parallel ray handling;
- picking chooses nearest hit;
- picking tie-break is stable;
- grid line generation count;
- picked point marker line generation;
- display options include grid and picked point marker state.

RuntimeApp:

- Metal picking updates selected chunk;
- hover picking exposes world point and surface data without changing selection;
- clear selection clears grid and Metal inspection state;
- grid and picked point toggles update render options;
- viewport scroll and drag mutate camera state;
- existing Phase 7 tests remain valid.

## Safe Scripts Added Or Modified

No safe script was added or modified in Phase 8.

`scripts/swift-test-render-safe.sh` from Phase 7 was reused.

## Commands Run And Results

`./scripts/swift-test-engine-safe.sh`

- Result: passed
- EngineCore tests: 55 tests, 0 failures

`./scripts/swift-test-render-safe.sh`

- Result: passed
- RenderCoreMetal tests: 25 tests, 0 failures

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
- RuntimeApp unit tests observed: 20 passed
- RuntimeApp UI tests observed: 4 passed

Note: an initial `xcodebuild-safe.sh test` pass succeeded but reported SwiftUI runtime issues caused by synchronous binding updates during `updateNSView`. `TelluricMetalDebugCoordinator` was corrected to update `frameStats` and `renderErrorMessage` asynchronously on the main queue, and the final test pass succeeded without those runtime issue messages.

## Known Limits

- Picking is CPU debug picking by chunk bounds plus nearest vertex. It is not final collision or production picking.
- The picked world point is the ray/AABB hit point; terrain detail comes from nearest vertex inspection.
- Hover updates can trigger debug line/mesh refreshes. This is acceptable for the current small debug scene and should be optimized later if needed.
- The grid is line-only, without 3D labels.
- No ray/triangle terrain intersection or BVH was added.
- No GPU picking was added.

## Technical Risks

- Reusing debug mesh descriptors for picking keeps the architecture simple, but large debug scenes will need spatial acceleration.
- The world/chunk grid currently uses mesh bounds, so it represents rendered chunk boundaries rather than a full world-grid system.
- Mouse interaction is intentionally minimal and should be refined before becoming a general editor-style camera.

## Safety Confirmations

- EngineCore was not modified.
- EngineCore remains without SwiftUI, AppKit, Metal, MetalKit, or simd imports.
- AudioRuntime was not modified.
- TelluricTools and LocalAssets were not modified.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo, or global xcode-select command was used.
- Xcode DerivedData stayed inside `.derivedData/TelluricRuntimeApp`.

## Phase 9 Proposal

Phase 9 — Terrain Collision Query + Player Probe Prototype

Objective:

- add CPU terrain queries in EngineCore;
- query terrain height at a world coordinate;
- query normal and surface at a point;
- create a debug player probe;
- move a player marker on the terrain;
- test walkability and slope;
- prepare a future camera/player controller;
- continue avoiding the full AAA renderer path.
