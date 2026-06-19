# Phase 7 Report - Runtime Camera + Terrain Debug Controls

## Summary

Phase 7 turns the Phase 6 Metal viewport into a practical runtime debug tool. The app can now inspect resident terrain chunks with camera controls, display mode toggles, wireframe rendering, bounds and normal line overlays, chunk selection from the SwiftUI grid, a chunk inspector, and a lightweight FPS/debug overlay.

This phase does not start the AAA renderer. It keeps the renderer debug-focused and preserves the architecture split:

- EngineCore: deterministic CPU world truth.
- RenderCoreMetal: Metal debug upload, camera, GPU buffers, simple draw modes.
- RuntimeApp: SwiftUI orchestration, controls, selection, inspection.

## Files Created

RenderCoreMetal:

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugCameraController.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugCameraInput.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugCameraState.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugFrameStats.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugLineBuffers.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugLineBuilder.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugLineVertex.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugNormalsConfiguration.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugTerrainColorMode.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugTerrainDisplayOptions.swift`

RuntimeApp:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricChunkInspectorView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalCameraControlsView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugOverlayView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugToolbarView.swift`

Tests and scripts:

- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugCameraControllerTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugDisplayOptionsTests.swift`
- `scripts/swift-test-render-safe.sh`

Documentation:

- `docs/PHASE_7_REPORT.md`

## Files Modified

RenderCoreMetal:

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugCamera.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRenderer.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalTerrainMeshDescriptor.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalTerrainMeshUploader.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/RenderCoreMetalInfo.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/Shaders/TelluricDebugTerrain.metal`

RuntimeApp:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricChunkCellView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricChunkGridView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugCoordinator.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalViewRepresentable.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

RenderCoreMetal tests:

- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalTerrainMeshUploaderTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`

## Xcode Changes

No `project.pbxproj` integration change was required in Phase 7.

The app already imported `EngineCore` and `RenderCoreMetal` from Phase 6. Phase 7 added Swift files under the existing file-system-synchronized RuntimeApp group and added RenderCoreMetal source/test files under the existing Swift package.

Two user-specific Xcode metadata files are visible as modified in the worktree:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj/project.xcworkspace/xcuserdata/work.xcuserdatad/UserInterfaceState.xcuserstate`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj/xcuserdata/work.xcuserdatad/xcschemes/xcschememanagement.plist`

They were not used for package integration and no manual project structure edit was made.

## Camera Architecture

`MetalDebugCameraState` stores the debug camera data:

- target
- distance
- yaw
- pitch
- zoom scale
- orthographic scale
- near/far planes

`MetalDebugCameraController` applies deterministic camera inputs:

- reset to terrain bounds
- fit to bounds
- pan
- zoom
- orbit
- pitch adjustment

The controller clamps pitch, zoom, distance, and orthographic scale to avoid negative distances, invalid scales, and NaN-producing states.

## Camera Controls Added

RuntimeApp now exposes simple SwiftUI controls:

- zoom in
- zoom out
- rotate left
- rotate right
- pitch up
- pitch down
- pan north
- pan south
- pan east
- pan west
- reset camera
- fit terrain

The controls update `TelluricDebugRuntimeModel.debugCameraState`, and `TelluricMetalViewRepresentable` forwards the state into `MetalDebugRenderer`.

## Display Modes Added

`MetalDebugTerrainColorMode` adds these modes:

- `surface`
- `lifecycle`
- `altitude`
- `mixed`

The Phase 7 strategy is to re-upload debug vertices when the color mode or selected chunk changes. This is simple, deterministic, and acceptable for the current debug viewport size.

## Wireframe Strategy

`MetalDebugRenderer` exposes wireframe through `MetalDebugTerrainDisplayOptions.isWireframeEnabled`.

When enabled, the renderer uses:

- `encoder.setTriangleFillMode(.lines)`

This affects only the debug terrain draw pass.

## Bounds Debug Strategy

Bounds are drawn as debug line buffers generated from mesh bounds. Each chunk bounds box produces 24 line vertices, using a constant debug color. Bounds rendering is controlled by `MetalDebugTerrainDisplayOptions.showsBounds`.

## Normals Debug Strategy

Normals are drawn as sampled line segments:

- start = terrain vertex position
- end = position + normal * configured length

`MetalDebugNormalsConfiguration` controls:

- enabled/disabled
- stride
- line length

The stride is clamped to at least 1. RuntimeApp exposes a toggle and length slider.

## Chunk Selection and Inspection

Selection is intentionally grid-driven in Phase 7. Clicking a SwiftUI chunk cell selects the chunk in `TelluricDebugRuntimeModel`.

The inspector displays:

- chunk coordinate
- lifecycle target
- cached payload state
- priority rank
- sample payload presence
- mesh payload presence
- render candidate presence
- vertex count
- index count
- surface sample count
- bounds
- chunk hash
- mesh stable hash

Selected chunks are highlighted in the SwiftUI grid and get a selected debug color during mesh upload.

## FPS and Debug Overlay

`MetalDebugFrameStats` reports:

- approximate FPS
- frame time in milliseconds
- rendered mesh count
- rendered vertex count
- rendered index count
- debug line vertex count

RuntimeApp overlays these with:

- color mode
- wireframe state
- bounds state
- normals state
- camera yaw/pitch/distance
- selected chunk coordinate

The FPS estimate is lightweight and based on periodic frame timing in `MetalDebugRenderer`.

## Tests Added

RenderCoreMetal:

- camera reset produces a valid state
- zoom clamps
- pitch clamps and orbit changes yaw
- pan changes target
- color mode cases are stable
- display options carry wireframe, bounds, and normals state
- bounds line generation count is stable
- normals line generation respects stride
- vertex colors change between debug modes
- selected descriptors change debug color

RuntimeApp:

- initial debug model has default render settings
- changing color mode updates render settings
- selecting and clearing a chunk updates inspection state
- camera controls mutate camera state
- mesh list remains non-empty after debug toggles

Existing RuntimeApp and UI tests remain active.

## Safe Scripts Added or Modified

Added:

- `scripts/swift-test-render-safe.sh`

The script follows the existing safe-script style:

- sets `DEVELOPER_DIR` locally
- runs SwiftPM only for `RenderCoreMetal`
- uses package-local `.build`
- uses a repo-local module cache
- does not touch Ruby, Rails, Homebrew, shell config, or global Xcode configuration

No existing safe script was modified.

## Commands Run and Results

`./scripts/swift-test-engine-safe.sh`

- Result: passed
- EngineCore tests: 55 tests, 0 failures

`./scripts/swift-test-render-safe.sh`

- Result: passed
- RenderCoreMetal tests: 15 tests, 0 failures

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
- RuntimeApp unit tests observed: 15 passed
- RuntimeApp UI tests observed: 4 passed

## Known Limits

- Chunk selection is currently driven by the SwiftUI grid, not by 3D picking in the Metal viewport.
- Bounds and normals are debug line overlays only; there are no labels or per-line picking.
- Color mode changes re-upload debug vertices. This is intentional for Phase 7 and should be revisited only when debug scene size grows.
- FPS is approximate and meant for debug visibility, not performance instrumentation.
- Camera controls are button-driven. Mouse/trackpad orbit and scroll zoom are left for a later refinement.
- No terrain textures, shadows, advanced lighting, vegetation, render graph, or GPU streaming were added.

## Technical Risks

- The debug renderer now has more state than Phase 6; future phases should keep it separate from production rendering.
- Re-uploading on display-mode changes is simple but not ideal for large worlds.
- UI tests still include launch-performance tests, which are inherently slower and can delay `xcodebuild-safe.sh test`.

## Purity and Safety Confirmations

- EngineCore was not modified in Phase 7.
- EngineCore still has no SwiftUI, AppKit, Metal, MetalKit, or simd imports.
- AudioRuntime was not modified.
- RenderCoreMetal is still the only module using Metal/MetalKit/simd for rendering.
- RuntimeApp remains the SwiftUI/AppKit-facing orchestration layer.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo, or global xcode-select command was used.
- Xcode DerivedData stayed inside `.derivedData/TelluricRuntimeApp`.

## Phase 8 Proposal

Phase 8 — Terrain Interaction + Debug Picking Refinement

Objective:

- improve terrain/chunk picking in the Metal viewport;
- select a chunk directly in the Metal view;
- inspect a vertex, sample, or surface under the cursor;
- display world coordinates;
- display height, surface, audio, and physical tags;
- add world/chunk grid overlays;
- prepare the future interactive terrain runtime;
- still avoid the full AAA renderer path.
