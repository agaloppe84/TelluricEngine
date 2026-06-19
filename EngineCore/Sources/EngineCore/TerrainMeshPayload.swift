public struct TerrainMeshPayload: Hashable, Codable, Sendable, StableHashable {
    public let generatorVersion: TerrainGeneratorVersion
    public let chunkCoord: ChunkCoord
    public let layout: TerrainChunkLayout
    public let vertices: [TerrainMeshVertex]
    public let indices: [TerrainMeshIndex]
    public let bounds: TerrainMeshBounds
    public let surfacePayload: TerrainSurfacePayload
    public let stableHash: UInt64

    public init(
        generatorVersion: TerrainGeneratorVersion,
        chunkCoord: ChunkCoord,
        layout: TerrainChunkLayout,
        vertices: [TerrainMeshVertex],
        indices: [TerrainMeshIndex],
        bounds: TerrainMeshBounds,
        surfacePayload: TerrainSurfacePayload
    ) {
        precondition(vertices.count == layout.sampleCount, "Terrain mesh vertex count does not match its layout.")
        precondition(surfacePayload.samples.count == vertices.count, "Surface payload must match terrain mesh vertices.")

        self.generatorVersion = generatorVersion
        self.chunkCoord = chunkCoord
        self.layout = layout
        self.vertices = vertices
        self.indices = indices
        self.bounds = bounds
        self.surfacePayload = surfacePayload
        self.stableHash = Self.computeStableHash(
            generatorVersion: generatorVersion,
            chunkCoord: chunkCoord,
            layout: layout,
            vertices: vertices,
            indices: indices,
            bounds: bounds,
            surfacePayload: surfacePayload
        )
    }

    public func vertex(localX: Int, localZ: Int) -> TerrainMeshVertex {
        precondition(localX >= 0 && localX < layout.samplesPerAxis, "localX is outside the terrain mesh layout.")
        precondition(localZ >= 0 && localZ < layout.samplesPerAxis, "localZ is outside the terrain mesh layout.")

        return vertices[localZ * layout.samplesPerAxis + localX]
    }

    private static func computeStableHash(
        generatorVersion: TerrainGeneratorVersion,
        chunkCoord: ChunkCoord,
        layout: TerrainChunkLayout,
        vertices: [TerrainMeshVertex],
        indices: [TerrainMeshIndex],
        bounds: TerrainMeshBounds,
        surfacePayload: TerrainSurfacePayload
    ) -> UInt64 {
        var state = StableHasher.hash(
            seed: 0x7E11_571C_7E55_0001,
            generatorVersion.stableHash,
            chunkCoord.stableHash,
            layout.stableHash,
            bounds.stableHash,
            surfacePayload.stableHash
        )

        for vertex in vertices {
            state = StableHasher.combine(state, vertex.stableHash)
        }
        for index in indices {
            state = StableHasher.combine(state, UInt64(index))
        }

        state = StableHasher.combine(state, UInt64(vertices.count))
        return StableHasher.combine(state, UInt64(indices.count))
    }
}

