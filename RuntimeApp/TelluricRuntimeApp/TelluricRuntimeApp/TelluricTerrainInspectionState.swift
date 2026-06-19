import EngineCore
import RenderCoreMetal

enum TelluricTerrainInspectionSource: String, Hashable {
    case hover
    case click
    case grid
}

struct TelluricTerrainInspectionState: Hashable {
    let source: TelluricTerrainInspectionSource
    let result: MetalDebugPickingResult?
    let selectedCoord: WorldChunkCoord?

    init(
        source: TelluricTerrainInspectionSource,
        result: MetalDebugPickingResult?,
        selectedCoord: WorldChunkCoord?
    ) {
        self.source = source
        self.result = result
        self.selectedCoord = selectedCoord
    }

    var hit: MetalDebugPickingHit? {
        result?.hit
    }

    var pickedWorldPoint: MetalDebugWorldPoint? {
        hit?.worldPosition
    }

    var displayCoord: WorldChunkCoord? {
        hit?.chunkCoord ?? selectedCoord
    }

    var statusLabel: String {
        if hit != nil {
            return source.rawValue
        }
        return result?.missReason?.rawValue ?? "none"
    }

    var stableDebugID: UInt64 {
        var state = result?.stableDebugID ?? 0
        state = (state &* 0x9E37_79B9_7F4A_7C15) ^ (selectedCoord?.stableHash ?? 0)
        state = (state &* 0x9E37_79B9_7F4A_7C15) ^ source.stableDebugID
        return state
    }
}

private extension TelluricTerrainInspectionSource {
    var stableDebugID: UInt64 {
        switch self {
        case .hover:
            return 1
        case .click:
            return 2
        case .grid:
            return 3
        }
    }
}
