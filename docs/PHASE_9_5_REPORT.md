# Phase 9.5 Report - Debug Runtime Usability Fix

## Summary

Phase 9.5 improves the existing RuntimeApp debug experience without starting Phase 10. The Metal viewport now defaults to a readable isometric camera, uses a display-only vertical scale for terrain relief, exposes named camera presets, shows a stronger player probe marker, and includes a status panel that explains what the developer is seeing.

No gameplay controller, continuous player movement, renderer AAA work, vegetation, shadows, advanced physics, or global environment work was added.

## Observed Problem

- The debug terrain could look like a dense stack of vertical blue lines.
- The player probe marker was too small and easy to lose in dense debug geometry.
- The viewport was visually compressed by a dense toolbar and side panels.
- The default camera fit used raw terrain height, making noisy terrain dominate the visible scale.
- The app did not immediately say whether terrain/probe/picking were visible or valid.

## Probable Cause

- EngineCore terrain heights are deterministic but can be high relative to the small chunk debug footprint.
- Phase 6-9 rendered debug terrain at full vertical scale.
- The camera fit considered raw Y extent equally with X/Z extent.
- The marker was only a small 3-line shape.
- Runtime UI placed most controls in a single compact row.

## Corrections Applied

### Camera

- Added RuntimeApp camera presets:
  - Isometric
  - Top-down
  - Side
  - Fit terrain
  - Reset
- Default launch camera is now Isometric.
- Added `Focus probe`.
- Manual zoom/pan/orbit/pitch switches the camera state to `Custom`.
- Camera fit now uses display-scaled terrain bounds for readability.

### Debug Vertical Scale

- Added `verticalScale` to `MetalDebugTerrainDisplayOptions`.
- Default debug vertical scale is `0.25`.
- Applied vertical scale to:
  - terrain vertex upload;
  - bounds lines;
  - normal debug lines;
  - grid overlay;
  - picked-point marker;
  - probe marker.
- This is display-only. EngineCore terrain payloads and terrain query truth remain unmodified.

### Player Probe Marker

- Increased default probe marker radius and height.
- Changed marker color to bright magenta.
- Replaced the tiny 3-line probe marker with a larger beacon/cross/diamond line shape.
- Added `Focus probe` camera action.

### Layout

- Increased app minimum size to `1280 x 860`.
- Increased Metal viewport minimum height.
- Moved side panels into a scrollable sidebar.
- Made the chunk grid secondary below the Metal viewport.
- Split the Metal toolbar into readable rows:
  - color/wireframe/picking;
  - overlays/vertical scale/normals;
  - camera preset and movement controls.

### Debug Status Panel

Added a `What am I seeing?` panel with:

- rendered terrain mesh count;
- terrain visible yes/no;
- probe visible yes/no;
- sanity preset status;
- current camera preset;
- current color mode;
- probe position;
- probe walkability;
- selected chunk;
- picked terrain point.

Visible warnings now include:

- `No terrain mesh visible`;
- `Probe outside known terrain`;
- `Extreme slope - terrain not playable here`;
- `Camera angle may hide terrain`.

### Sanity Debug Preset

No EngineCore terrain generator change was made. Instead, RuntimeApp now uses a debug presentation preset:

- display vertical scale `0.25`;
- Isometric camera by default;
- relaxed debug probe walkability threshold inside RuntimeApp only;
- initial probe placement searches near the current center for a grounded, walkable, readable surface when possible.

This keeps EngineCore deterministic data unchanged while making the runtime debug view immediately more usable.

## Files Created

- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugCameraPreset.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugStatusView.swift`
- `docs/PHASE_9_5_REPORT.md`

## Files Modified

- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugLineBuilder.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugProbeMarkerConfiguration.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugRenderer.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalDebugTerrainDisplayOptions.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/MetalTerrainMeshUploader.swift`
- `RenderCoreMetal/Sources/RenderCoreMetal/RenderCoreMetalInfo.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalDebugDisplayOptionsTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/MetalTerrainMeshUploaderTests.swift`
- `RenderCoreMetal/Tests/RenderCoreMetalTests/RenderCoreMetalInfoTests.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugRuntimeModel.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalCameraControlsView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugToolbarView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp/TelluricMetalDebugView.swift`
- `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeAppTests/TelluricRuntimeAppTests.swift`

No `project.pbxproj` integration change was made.

## Tests Added Or Updated

RenderCoreMetal:

- default display options use readable vertical scale and visible probe;
- vertical scale affects CPU vertex display Y;
- vertical scale affects probe marker Y only;
- probe marker line count updated for the larger beacon;
- RenderCoreMetal phase marker updated to Phase 9.5.

RuntimeApp:

- default camera preset is readable/isometric;
- camera preset changes state;
- vertical scale changes debug upload hash;
- debug status reports visible terrain/probe;
- probe marker config is visible by default;
- focus probe moves camera target to the probe;
- existing Phase 9 runtime/probe/picking tests remain valid.

## Commands Run

### `./scripts/swift-test-render-safe.sh`

Passed.

- RenderCoreMetal tests: 30 tests, 0 failures.

### `./scripts/xcodebuild-safe.sh build`

First run failed due to a missing `RenderCoreMetal` import in the newly added `TelluricDebugStatusView.swift`.

Fixed locally, then reran.

Final result: passed.

- `** BUILD SUCCEEDED **`

### `./scripts/xcodebuild-safe.sh test`

Passed.

- RuntimeApp unit tests: 31 tests, 0 failures.
- RuntimeApp UI tests: 4 tests, 0 failures.
- `** TEST SUCCEEDED **`

### `./scripts/swift-test-engine-safe.sh`

Passed.

- EngineCore tests: 71 tests, 0 failures.

### `./scripts/swift-build-all-safe.sh`

Passed.

- EngineCore build: passed.
- RenderCoreMetal build: passed.
- AudioRuntime build: passed.
- `All Swift packages built.`

### `./scripts/verify-no-global-mutations.sh`

Passed.

- `No global mutation patterns detected.`

## Known Limits

- Terrain generation itself is unchanged; Phase 9.5 improves debug presentation, not procedural terrain shape.
- Vertical scale is display-only, so CPU terrain query values remain raw world values.
- Viewport picking remains the Phase 8 debug picking path and is not production collision.
- The sanity debug preset is a RuntimeApp presentation/probe setup, not a new EngineCore generator profile.
- Human visual validation in the app is still required before Phase 10.

## Risk Notes

- Display-scaled terrain may make visual height differ from raw EngineCore query height. This is intentional for debug readability and surfaced through the vertical scale control.
- Camera presets are simple fixed states, not a full camera tool system.
- The larger probe marker increases debug line count but remains tiny relative to mesh geometry.

## Confirmations

- EngineCore was not modified in Phase 9.5.
- EngineCore remains pure and free of SwiftUI/AppKit/Metal/simd imports.
- AudioRuntime was not modified.
- No Ruby, Rails, Bundler, Gem, Homebrew, sudo, or global xcode-select command was used.
- No renderer AAA work was started.
- No Phase 10 player controller work was started.

## Phase 10 Recommendation

Only start Phase 10 after human visual validation confirms that the Phase 9.5 viewport is readable.

Recommended next phase:

**Phase 10 - Debug Player Controller + Camera Follow Prototype**

Objective:

- transform the probe into a debug player controller prototype;
- add continuous keyboard movement;
- add simple camera follow;
- keep CPU collision simple;
- display speed, slope, grounded state;
- prepare gameplay input;
- still avoid animation, full physics, and renderer AAA work.
