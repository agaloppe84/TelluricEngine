# Telluric Engine

Telluric Engine is a custom Swift/Metal engine for procedural, deterministic, systemic worlds on Apple Silicon.

The project follows a non-negotiable foundation:

```text
seed-first + deterministic-first + systemic-first + simulation-first + Metal-first
```

`EngineCore` is the pure deterministic core. It must not import SwiftUI, Metal, RealityKit, audio backends, or editor/runtime UI frameworks. Rendering lives in `RenderCoreMetal`, audio runtime work lives in `AudioRuntime`, and tools live in `TelluricTools`.

## Safe Commands

Run only the local safe scripts for validation:

```sh
./scripts/codex-preflight-safe.sh
./scripts/swift-test-engine-safe.sh
./scripts/swift-build-all-safe.sh
./scripts/xcodebuild-safe.sh build
```

These scripts set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` locally and keep Swift/Xcode outputs inside the repository.

Do not run global installs, do not change `xcode-select`, and do not use Ruby/Rails tooling for this project.

