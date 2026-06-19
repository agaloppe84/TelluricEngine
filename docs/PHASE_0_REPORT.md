# Phase 0 Report - Safe Foundation

Date: 2026-06-19

## Summary

Phase 0 established a minimal, local, testable foundation for Telluric Engine without global installs, without `xcode-select` changes, without Ruby/Rails commands, and without manual `.xcodeproj` edits.

The foundation keeps the intended separation:

- `EngineCore`: pure deterministic Swift package.
- `RenderCoreMetal`: minimal placeholder Swift package.
- `AudioRuntime`: minimal placeholder Swift package.
- `RuntimeApp`: existing Xcode app, detected but not modified.
- `TelluricTools`, `Shaders`, `SamplesTiny`, `LocalAssets`: base folders created.
- `scripts`: local safe scripts for validation.

## Created Or Completed

- `.gitignore`
  - Ignores Swift/Xcode local outputs: `.build/`, `**/.build/`, `.derivedData/`, `DerivedData/`.
  - Ignores local/generated heavy assets.
  - Keeps `LocalAssets/.gitkeep` versionable while ignoring real local assets.
  - Ignores Ruby/Rails local dependency markers such as `.bundle/` and `vendor/bundle/`.

- `README.md`
  - Short engine description.
  - Safe command list.
  - Environment safety reminder.

- `EngineCore/`
  - Local Swift package.
  - `StableSeed`
  - `StableHasher`
  - `StableHashable`
  - `ChunkCoord`
  - `WorldSeed`
  - `DeterminismProbe`
  - EngineCore tests for seed determinism, different seeds, stable chunk hashing, and forbidden imports.

- `RenderCoreMetal/`
  - Local Swift package.
  - Minimal `RenderCoreMetalInfo` placeholder.
  - No renderer and no dependency on `EngineCore`.

- `AudioRuntime/`
  - Local Swift package.
  - Minimal `AudioRuntimeInfo` placeholder.
  - No heavy audio backend dependency.

- `scripts/`
  - `codex-preflight-safe.sh`
  - `swift-test-engine-safe.sh`
  - `swift-build-all-safe.sh`
  - `xcodebuild-safe.sh`
  - `verify-no-global-mutations.sh`

All scripts are executable.

## Structure Detected

Existing Xcode project detected:

```text
RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj
```

Reference docs detected:

```text
docs/reference/TELLURIC_BASE_SPECS.md
docs/reference/TELLURIC_BIOME_TERRAIN_FORGE_ULTIMATE.md
docs/reference/TELLURIC_METAL4_AI_ML_RPG_PIPELINE.md
docs/reference/TELLURIC_MOTION_FORGE_ULTIMATE.md
docs/reference/TELLURIC_PROCEDURAL_PARAMETRIC_AUDIO_ENGINE.md
```

## Safe Commands Available

```sh
./scripts/codex-preflight-safe.sh
./scripts/swift-test-engine-safe.sh
./scripts/swift-build-all-safe.sh
./scripts/xcodebuild-safe.sh build
./scripts/xcodebuild-safe.sh test
./scripts/verify-no-global-mutations.sh
```

The Swift and Xcode scripts set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` locally. SwiftPM scratch paths are local to each package. Xcode DerivedData is local:

```text
.derivedData/TelluricRuntimeApp
```

## Validation Results

`./scripts/codex-preflight-safe.sh`

- Passed.
- Detected the Xcode project under `RuntimeApp/`.
- Confirmed no Ruby/Rails dependency markers in the repo root scan.
- Xcode emitted sandbox-related cache/FSEvents warnings during tool lookup, but `xcodebuild` resolved through local `DEVELOPER_DIR`.

`./scripts/swift-test-engine-safe.sh`

- Initial run inside the Codex sandbox failed because SwiftPM attempted to use `sandbox-exec`, which is blocked in this environment.
- Re-run via the same local safe script with approved non-sandboxed execution passed.
- Result: 4 EngineCore tests passed.

Covered by tests:

- same seed + same chunk => same deterministic probe result;
- different seed => different deterministic probe result;
- `ChunkCoord` is `Hashable` and exposes a stable deterministic hash;
- `EngineCore` sources do not import SwiftUI, AppKit, UIKit, Metal, MetalKit, RealityKit, SceneKit, SpriteKit, GameController, or AVFoundation.

`./scripts/swift-build-all-safe.sh`

- Initial run inside the Codex sandbox failed for the same SwiftPM `sandbox-exec` reason.
- Re-run via the same local safe script with approved non-sandboxed execution passed.
- Built:
  - `EngineCore`
  - `RenderCoreMetal`
  - `AudioRuntime`

`./scripts/xcodebuild-safe.sh build`

- Passed.
- Project: `RuntimeApp/TelluricRuntimeApp/TelluricRuntimeApp.xcodeproj`
- Scheme: `TelluricRuntimeApp`
- DerivedData: `.derivedData/TelluricRuntimeApp`
- Xcode warned that multiple macOS destinations matched and selected one automatically. This did not block the build.

## Safety Notes

- No `sudo`.
- No `xcode-select`.
- No Homebrew commands.
- No Ruby/Rails/Bundler/Gem commands.
- No global installs.
- No shell profile changes.
- No Xcode project file edits.
- No dependency additions.
- No Metal, SwiftUI, RealityKit, or audio backend imports in `EngineCore`.

## Remaining Limits

- `EngineCore` only contains the Phase 0 deterministic seed/hash/probe nucleus.
- No terrain generation yet.
- No surface fields yet.
- No residency graph yet.
- `RenderCoreMetal` is intentionally a placeholder; no renderer, RenderGraph, device, shaders, or Metal pipeline yet.
- `AudioRuntime` is intentionally a placeholder; no AVAudioEngine/CoreAudio backend yet.
- The Swift packages are not integrated into the Xcode app project. This was intentionally left unmodified to avoid risky `.pbxproj` edits.
- `verify-no-global-mutations.sh` exists for local safety checks, but it was not part of the required validation command list for Phase 0.

## Manual Xcode Work

None required for Phase 0.

For later phases, if `RuntimeApp` needs to import the local packages, add them manually in Xcode as local package dependencies:

- `EngineCore`
- `RenderCoreMetal`
- `AudioRuntime`

Do this through Xcode's package dependency UI instead of hand-editing the `.pbxproj`.

## Recommended Next Step

Start Phase 1 with a narrow deterministic terrain slice in `EngineCore`:

```text
Implement Phase 1 - EngineCore deterministic terrain slice.
Keep EngineCore pure. Add terrain sample coordinates, generator versioning,
a minimal deterministic scalar field, chunk terrain sample payloads, and tests
for same seed, different seed, neighboring chunk edge consistency, and no
forbidden imports.
```

