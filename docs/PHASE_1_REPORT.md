# Phase 1 Report - EngineCore Deterministic Terrain Slice

Date: 2026-06-19

## Summary

Phase 1 adds the first deterministic terrain slice in `EngineCore`. It is pure Swift data and computation: no SwiftUI, Metal, RealityKit, rendering, audio backend, Xcode project edits, or external dependencies.

## Added Contracts

- `TerrainGeneratorVersion`
- `TerrainSampleCoord`
- `TerrainChunkLayout`
- `TerrainSample`
- `TerrainScalarField`
- `ChunkTerrainSamplePayload`
- `TerrainChunkSampler`

## Determinism Model

Terrain samples are addressed by world sample coordinates, not by chunk-local identity. A chunk layout maps local sample positions to stable world coordinates:

```text
worldSampleX = chunkX * (samplesPerAxis - 1) + localX
worldSampleZ = chunkZ * (samplesPerAxis - 1) + localZ
```

That makes neighboring chunks share identical coordinates and identical scalar samples on their common edge.

The scalar field is intentionally minimal:

- input: `WorldSeed`, `TerrainGeneratorVersion`, `TerrainSampleCoord`;
- output: deterministic scalar value in `[0, 1)` plus a simple height in meters;
- hash path: `StableHasher`, never Swift's process-randomized `Hasher`.

## Tests Added

- same seed and chunk produce the same terrain payload;
- different seeds produce different terrain payloads;
- neighboring chunks share stable edge samples;
- terrain payload exposes a stable non-zero payload hash;
- existing EngineCore import purity test continues to cover forbidden imports.

## Non-Goals

- no mesh generation;
- no terrain renderer;
- no biome solver;
- no hydrology;
- no surface material system;
- no async streaming or residency graph.

## Recommended Next Step

Phase 2 should turn the deterministic sample payload into a terrain mesh/surface payload contract while keeping rendering separate.

