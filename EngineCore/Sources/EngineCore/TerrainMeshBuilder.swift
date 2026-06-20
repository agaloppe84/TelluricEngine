public enum TerrainMeshBuilder {
    public static func makePayload(
        from samplePayload: ChunkTerrainSamplePayload,
        horizontalSpacingMeters: Float = 1.0
    ) -> TerrainMeshPayload {
        precondition(horizontalSpacingMeters > 0, "Terrain mesh horizontal spacing must be positive.")
        precondition(samplePayload.layout.sampleCount <= Int(UInt32.max), "Terrain mesh is too large for UInt32 indices.")

        var vertices: [TerrainMeshVertex] = []
        var surfaceSamples: [TerrainSurfaceSample] = []
        vertices.reserveCapacity(samplePayload.layout.sampleCount)
        surfaceSamples.reserveCapacity(samplePayload.layout.sampleCount)

        var bounds: TerrainMeshBounds?
        let layout = samplePayload.layout

        for localZ in 0..<layout.samplesPerAxis {
            for localX in 0..<layout.samplesPerAxis {
                let terrainSample = samplePayload.sample(localX: localX, localZ: localZ)
                let height = Float(terrainSample.heightMeters)
                let position = TEVec3f(
                    x: Float(terrainSample.coord.x) * horizontalSpacingMeters,
                    y: height,
                    z: Float(terrainSample.coord.z) * horizontalSpacingMeters
                )
                let normal = normalAt(
                    coord: terrainSample.coord,
                    worldSeed: samplePayload.worldSeed,
                    generatorVersion: samplePayload.generatorVersion,
                    profile: samplePayload.profile,
                    horizontalSpacingMeters: horizontalSpacingMeters
                )
                let surface = TerrainSurfaceResolver.resolve(sample: terrainSample, normal: normal)
                let uvDenominator = Float(layout.samplesPerAxis - 1)
                let uv = TEVec2f(
                    x: Float(localX) / uvDenominator,
                    y: Float(localZ) / uvDenominator
                )

                if var currentBounds = bounds {
                    currentBounds.include(position)
                    bounds = currentBounds
                } else {
                    bounds = TerrainMeshBounds(firstPoint: position)
                }

                surfaceSamples.append(surface)
                vertices.append(
                    TerrainMeshVertex(
                        position: position,
                        normal: normal,
                        uv: uv,
                        sampleCoord: terrainSample.coord,
                        heightMeters: height,
                        surface: surface
                    )
                )
            }
        }

        let surfacePayload = TerrainSurfacePayload(
            generatorVersion: samplePayload.generatorVersion,
            chunkCoord: samplePayload.chunkCoord,
            layout: layout,
            samples: surfaceSamples
        )

        return TerrainMeshPayload(
            generatorVersion: samplePayload.generatorVersion,
            chunkCoord: samplePayload.chunkCoord,
            layout: layout,
            vertices: vertices,
            indices: makeIndices(layout: layout),
            bounds: bounds ?? TerrainMeshBounds(firstPoint: .zero),
            surfacePayload: surfacePayload
        )
    }

    private static func makeIndices(layout: TerrainChunkLayout) -> [TerrainMeshIndex] {
        let quadCount = layout.chunkSampleSpan * layout.chunkSampleSpan
        var indices: [TerrainMeshIndex] = []
        indices.reserveCapacity(quadCount * 6)

        for localZ in 0..<layout.chunkSampleSpan {
            for localX in 0..<layout.chunkSampleSpan {
                let topLeft = localZ * layout.samplesPerAxis + localX
                let topRight = topLeft + 1
                let bottomLeft = (localZ + 1) * layout.samplesPerAxis + localX
                let bottomRight = bottomLeft + 1

                indices.append(TerrainMeshIndex(topLeft))
                indices.append(TerrainMeshIndex(bottomLeft))
                indices.append(TerrainMeshIndex(topRight))
                indices.append(TerrainMeshIndex(topRight))
                indices.append(TerrainMeshIndex(bottomLeft))
                indices.append(TerrainMeshIndex(bottomRight))
            }
        }

        return indices
    }

    private static func normalAt(
        coord: TerrainSampleCoord,
        worldSeed: WorldSeed,
        generatorVersion: TerrainGeneratorVersion,
        profile: TerrainGenerationProfile,
        horizontalSpacingMeters: Float
    ) -> TEVec3f {
        let left = TerrainScalarField.sample(
            worldSeed: worldSeed,
            coord: TerrainSampleCoord(x: coord.x - 1, z: coord.z),
            generatorVersion: generatorVersion,
            profile: profile
        )
        let right = TerrainScalarField.sample(
            worldSeed: worldSeed,
            coord: TerrainSampleCoord(x: coord.x + 1, z: coord.z),
            generatorVersion: generatorVersion,
            profile: profile
        )
        let south = TerrainScalarField.sample(
            worldSeed: worldSeed,
            coord: TerrainSampleCoord(x: coord.x, z: coord.z - 1),
            generatorVersion: generatorVersion,
            profile: profile
        )
        let north = TerrainScalarField.sample(
            worldSeed: worldSeed,
            coord: TerrainSampleCoord(x: coord.x, z: coord.z + 1),
            generatorVersion: generatorVersion,
            profile: profile
        )

        let sampleDistance = horizontalSpacingMeters * 2
        let heightDx = (Float(right.heightMeters) - Float(left.heightMeters)) / sampleDistance
        let heightDz = (Float(north.heightMeters) - Float(south.heightMeters)) / sampleDistance
        let normal = TEVec3f(x: -heightDx, y: 1, z: -heightDz).normalized

        if normal.lengthSquared <= 0 {
            return .up
        }
        return normal
    }
}
