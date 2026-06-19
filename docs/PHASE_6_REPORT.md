# Phase 6 Report - Metal Debug Terrain Renderer Bridge

## Summary

Phase 6 adds the first minimal Metal bridge for Telluric terrain debug rendering.

The implemented path is:

```text
ResidentWorldSnapshot records with TerrainMeshPayload
  -> RuntimeApp debug mesh descriptors
  -> RenderCoreMetal upload
  -> MTLBuffer vertex/index data
  -> MTKView debug draw
```

This is intentionally not the AAA renderer. It is a small debug renderer for seeing CPU mesh payloads produced by EngineCore. The Phase 5 SwiftUI chunk grid remains available below the Metal viewport.

## Files Created Or Modified

Created in `RenderCoreMetal/Sources/RenderCoreMetal/`:

- `MetalTerrainVertex.swift`
- `MetalTerrainMeshDescriptor.swift`
- `MetalTerrainMeshBuffers.swift`
- `MetalTerrainMeshUploadResult.swift`
- `MetalTerrainMeshUploader.swift`
- `MetalDebugRenderer.swift`
- `MetalDebugRendererConfiguration.swift`
- `MetalDebugCamera.swift`
- `MetalDebugRenderError.swift`
- `Shaders/TelluricDebugTerrain.metal`

Modified in `RenderCoreMetal/`:

- `Package.swift`
- `Sources/RenderCoreMetal/RenderCoreMetalInfo.swift`
- `Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`

Created in `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/`:

- `TelluricMetalDebugCoordinator.swift`
- `TelluricMetalDebugView.swift`
- `TelluricMetalViewRepresentable.swift`

Modified in `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/`:

- `TelluricDebugRuntimeModel.swift`
- `TelluricDebugView.swift`
- `TelluricSnapshotStatsView.swift`

Modified in `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/`:

- `TelluricRuntimeAppTests.swift`

Modified in Xcode project:

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj/project.pbxproj`

Note: `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj/project.xcworkspace/xcuserdata/work.xcuserdatad/UserInterfaceState.xcuserstate` was already dirty before Phase 6 work started and was left in place. It is not part of the intended implementation.

## Xcode Modifications

`project.pbxproj` was updated minimally:

- Added local package reference `../../RenderCoreMetal`.
- Added `RenderCoreMetal` product dependency to `TelluricRuntimeApp`.
- Added `RenderCoreMetal` product dependency to `TelluricRuntimeAppTests`.
- Added `RenderCoreMetal in Frameworks` build entries for the app and test targets.
- Kept the existing `../../EngineCore` integration unchanged.
- Did not add `AudioRuntime`.
- Did not recreate or rename the Xcode project.

## RenderCoreMetal Integration

`RenderCoreMetal/Package.swift` now depends on the local `../EngineCore` package. This allows RenderCoreMetal to consume `TerrainMeshPayload`, lifecycle state, bounds, surface tags, and chunk IDs while keeping all Metal APIs out of EngineCore.

RuntimeApp imports:

```swift
import EngineCore
import RenderCoreMetal
import SwiftUI
```

RenderCoreMetal imports:

```swift
import EngineCore
import Metal
import MetalKit
import simd
```

EngineCore was not modified for Phase 6.

## Renderer Architecture

`MetalDebugRenderer` owns:

- `MTLDevice`
- `MTLCommandQueue`
- render pipeline state
- depth stencil state
- uploaded terrain mesh buffers
- a fitting debug camera

It exposes:

- `attach(to:)` for configuring an `MTKView`
- `updateMeshes(_:)` for uploading a new debug mesh set
- `clearMeshes()` for empty viewport states
- `draw(in:)` as the `MTKViewDelegate` draw path

No render graph, texture system, lighting stack, shadowing, vegetation, async streaming, or GPU residency system was added.

## Mesh Uploader Architecture

`MetalTerrainMeshUploader` converts `TerrainMeshPayload` into GPU-friendly `MetalTerrainVertex` values and uploads:

- one vertex buffer per terrain mesh
- one UInt32 index buffer per terrain mesh

The uploader does not draw. It only converts CPU mesh data into `MetalTerrainMeshBuffers`.

## Shader Strategy

The shader is a SwiftPM package resource:

- `RenderCoreMetal/Sources/RenderCoreMetal/Shaders/TelluricDebugTerrain.metal`

It provides:

- `telluric_debug_terrain_vertex`
- `telluric_debug_terrain_fragment`

The vertex shader applies a simple MVP matrix and passes debug color through. The fragment shader returns that color. `MetalDebugRenderer` also contains a fallback source string if the resource cannot be found.

## Camera Strategy

Phase 6 uses a fixed orthographic debug camera fitted to the combined terrain bounds. The camera looks down at the mesh from above and at an angle. There are no mouse, orbit, pan, or zoom controls yet.

## Rendered Chunk Selection

RuntimeApp renders every `CachedChunkRecord` in the current `ResidentWorldSnapshot` that has a `meshPayload`.

That means:

- `meshRequested` chunks can be visible
- `resident` chunks can be visible
- `active` chunks can be visible
- sample-only chunks are not rendered by Metal

The SwiftUI grid still shows sample-only and eviction/absent states.

## Debug Color Strategy

Metal debug colors combine:

- terrain surface material tint
- lifecycle state tint
- a small altitude brightness factor

This keeps the view useful for terrain inspection without adding textures or lighting.

## Runtime UI Strategy

`TelluricDebugView` now shows:

- left side controls and stats
- a Metal terrain viewport
- the existing SwiftUI chunk grid

`TelluricDebugRuntimeModel` exposes:

- `debugTerrainMeshDescriptors`
- `debugTerrainMeshCount`
- `debugTerrainMeshHash`

These are derived from the current snapshot and cache records. No mutable render state was added to EngineCore.

## Tests Added

RenderCoreMetal package tests added:

- `RenderCoreMetalInfoTests` now checks Phase 6 status.
- `MetalTerrainMeshUploaderTests` checks CPU vertex conversion, debug colors, and optional GPU upload with `MTLCreateSystemDefaultDevice()` skip behavior.

RuntimeApp tests added:

- snapshot exposes debug terrain meshes after rebuild
- mesh export remains deterministic across rebuilds
- moving center changes debug terrain mesh hash
- RuntimeApp can reference RenderCoreMetal types
- CPU conversion from debug mesh descriptor matches source mesh payload

The current safe validation whitelist does not include a dedicated `RenderCoreMetal` package test script. The RuntimeApp tests above execute under `xcodebuild-safe.sh test`, and `swift-build-all-safe.sh` builds the RenderCoreMetal package.

## Commands Run

Only safe repo scripts were used for validation.

```sh
./scripts/swift-test-engine-safe.sh
```

Result:

- passed
- EngineCore: 55 tests, 0 failures

```sh
./scripts/swift-build-all-safe.sh
```

Result:

- passed
- EngineCore built
- RenderCoreMetal built
- AudioRuntime built
- no warnings after the final rerun

```sh
./scripts/xcodebuild-safe.sh build
```

Result:

- passed
- Xcode resolved local packages:
  - `EngineCore: /Users/work/GamesByMe/TelluricEngine/EngineCore`
  - `RenderCoreMetal: /Users/work/GamesByMe/TelluricEngine/RenderCoreMetal`
- `** BUILD SUCCEEDED **`

```sh
./scripts/xcodebuild-safe.sh test
```

Result:

- passed
- `** TEST SUCCEEDED **`
- RuntimeApp unit tests: 10 passed
- RuntimeApp UI tests: 4 passed

```sh
./scripts/verify-no-global-mutations.sh
```

Result:

- passed
- no forbidden global mutation command patterns detected
- EngineCore forbidden import check passed
- `.gitignore` local output coverage passed

## Known Limits

- The Metal viewport is debug-only and minimal.
- No interactive camera controls yet.
- No wireframe toggle yet.
- No bounds, normals, or surface/lifecycle color toggle UI yet.
- No textures, lighting, shadows, vegetation, or render graph.
- No GPU streaming or advanced resource lifetime management.
- RenderCoreMetal package tests exist, but the current approved safe script set does not include a dedicated command to run that package test target directly.

## Technical Risks

- The shader is loaded as a SwiftPM package resource and also has a fallback source string. If future Xcode package resource behavior changes, this path should be rechecked.
- The camera fitting is intentionally simple and may not frame extreme terrain ranges perfectly.
- The debug color strategy mixes lifecycle and surface colors; Phase 7 should add toggles to inspect each signal independently.

## Safety Confirmations

- EngineCore remains pure and was not modified in Phase 6.
- EngineCore still has no `SwiftUI`, `AppKit`, `Metal`, `MetalKit`, or `simd` imports.
- AudioRuntime was not modified.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo, or xcode-select command was used.
- No global Xcode configuration was modified.
- DerivedData stayed local under `.derivedData/TelluricRuntimeApp`.

## Phase 7 Proposal

Phase 7 - Runtime Camera + Terrain Debug Controls

Objective:

- add clean camera controls
- add terrain debug navigation
- add chunk selection and inspection
- add toggles for wireframe, surface colors, lifecycle colors, bounds, and normals
- add FPS/debug overlay
- keep the renderer minimal but genuinely inspectable
- do not start the full AAA renderer yet
