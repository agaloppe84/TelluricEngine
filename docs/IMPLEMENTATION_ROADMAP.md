# Telluric Engine Implementation Roadmap

This roadmap starts after Phase 0 - Safe Foundation.

## Phase 1 - EngineCore Deterministic Terrain Slice

Goal: create the first terrain truth in `EngineCore` without rendering, tools, or platform dependencies.

Deliverables:

- `TerrainSampleCoord`
- `TerrainGeneratorVersion`
- minimal deterministic scalar field
- chunk sample grid payload
- stable payload hash
- golden seed tests
- neighbor edge consistency tests
- no SwiftUI, Metal, RealityKit, or audio backend imports

Non-goals:

- no mesh generation;
- no renderer;
- no biome solver;
- no GPU work.

## Phase 2 - Terrain Mesh Payload + Surface Fields

Goal: convert deterministic terrain samples into a CPU payload contract that later rendering, motion, audio, and gameplay can consume.

Deliverables:

- `TerrainMeshPayload` contract
- terrain vertex/index payload basics
- bounds and payload hash
- minimal surface field contract
- physical surface tags
- audio surface tags as pure data
- tests for deterministic payload hashes and edge stability

Non-goals:

- no Metal renderer yet;
- no complex material system;
- no live editing.

## Phase 3 - World Residency Graph

Goal: define the first deterministic, testable residency model for streamed world chunks.

Deliverables:

- chunk state enum
- residency request model
- priority scoring contract
- deterministic ordering for equal-priority requests
- anti-thrashing policy skeleton
- tests for stable scheduling order

Non-goals:

- no async job system yet unless the contract is stable;
- no GPU residency yet;
- no disk cache.

## Phase 4 - RenderCoreMetal Minimal Renderer

Goal: introduce the first real Metal boundary while keeping `EngineCore` pure.

Deliverables:

- `RenderCoreMetal` device bootstrap
- minimal render target clear pass
- shader compilation path
- local shader folder usage
- smoke build through `xcodebuild-safe.sh`
- no terrain renderer complexity yet

Non-goals:

- no full RenderGraph;
- no virtual geometry;
- no material residency.

## Phase 5 - EcoGrowth Forge Minimal

Goal: add the first deterministic ecological placement layer driven by terrain/surface truth.

Deliverables:

- species identity/DNA skeleton
- micro-habitat suitability scalar
- deterministic candidate placement
- stable candidate IDs
- tests for same seed, different seed, and chunk neighbor behavior

Non-goals:

- no complex plant meshes;
- no growth simulation persistence;
- no renderer integration beyond contracts.

