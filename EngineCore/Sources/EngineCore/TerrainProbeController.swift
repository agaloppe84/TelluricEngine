public struct TerrainProbeController: Sendable {
    public let configuration: TerrainProbeConfiguration

    public init(configuration: TerrainProbeConfiguration = .default) {
        self.configuration = configuration
    }

    public func place(
        id: UInt64 = 1,
        worldX: Float,
        worldZ: Float,
        terrain: TerrainQueryEngine,
        queryMode: TerrainQueryMode = .bilinearHeightfield
    ) -> TerrainProbeMoveResult {
        let queryResult = terrain.query(
            TerrainQueryRequest(worldX: worldX, worldZ: worldZ, queryMode: queryMode)
        )
        let probe = makeProbe(id: id, queryResult: queryResult)
        return TerrainProbeMoveResult(
            previousProbe: nil,
            probe: probe,
            queryResult: queryResult,
            didMove: true
        )
    }

    public func move(
        probe: TerrainProbe,
        request: TerrainProbeMoveRequest,
        terrain: TerrainQueryEngine
    ) -> TerrainProbeMoveResult {
        let targetX = probe.worldPosition.x + request.deltaX
        let targetZ = probe.worldPosition.z + request.deltaZ
        let queryResult = terrain.query(
            TerrainQueryRequest(
                worldX: targetX,
                worldZ: targetZ,
                queryMode: request.queryMode
            )
        )
        let shouldMove = configuration.allowsNonWalkableMovement || queryResult.walkability.isWalkable
        let nextProbe = shouldMove
            ? makeProbe(id: probe.id, queryResult: queryResult)
            : probe

        return TerrainProbeMoveResult(
            previousProbe: probe,
            probe: nextProbe,
            queryResult: queryResult,
            didMove: shouldMove
        )
    }

    private func makeProbe(id: UInt64, queryResult: TerrainQueryResult) -> TerrainProbe {
        TerrainProbe(
            id: id,
            worldPosition: queryResult.worldPosition,
            lastQueryResult: queryResult,
            isGrounded: queryResult.isInsideKnownTerrain,
            walkability: queryResult.walkability
        )
    }
}

