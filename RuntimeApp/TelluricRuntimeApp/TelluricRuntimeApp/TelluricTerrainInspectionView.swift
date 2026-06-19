import EngineCore
import Foundation
import RenderCoreMetal
import SwiftUI

struct TelluricTerrainInspectionView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Terrain point")
                    .font(.headline)
                Spacer()
                Text(model.terrainInspectionState?.statusLabel ?? "none")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let state = model.terrainInspectionState {
                inspectionDetails(state)
            } else {
                Text("No viewport point")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private func inspectionDetails(_ state: TelluricTerrainInspectionState) -> some View {
        let hit = state.hit
        return VStack(spacing: 7) {
            detailRow("Source", state.source.rawValue)
            detailRow("Chunk", format(state.displayCoord))
            detailRow("Screen", format(state.result?.screenPoint))
            detailRow("World", format(hit?.worldPosition.position))
            detailRow("Nearest vertex", format(hit?.nearestVertexPosition))
            detailRow("Normal", format(hit?.nearestVertexNormal))
            detailRow("Vertex index", hit?.nearestVertexIndex.map(String.init) ?? "-")
            detailRow("Sample", format(hit?.nearestSampleCoord))
            detailRow("Height", hit?.heightMeters.map { String(format: "%.2f m", Double($0)) } ?? "-")
            detailRow("Material", hit?.surface?.material.label ?? "-")
            detailRow("Physical", hit?.surface?.physicalTag.label ?? "-")
            detailRow("Audio", hit?.surface?.audioTag.label ?? "-")
            detailRow("Mesh hash", formatHash(hit?.meshStableHash))
            detailRow("Snapshot", model.snapshotHashLabel)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .font(.caption)
    }

    private func format(_ coord: WorldChunkCoord?) -> String {
        guard let coord else {
            return "-"
        }
        return "(\(coord.x), \(coord.z))"
    }

    private func format(_ coord: TerrainSampleCoord?) -> String {
        guard let coord else {
            return "-"
        }
        return "(\(coord.x), \(coord.z))"
    }

    private func format(_ point: MetalDebugScreenPoint?) -> String {
        guard let point else {
            return "-"
        }
        return "\(format(point.x)), \(format(point.y))"
    }

    private func format(_ value: SIMD3<Float>?) -> String {
        guard let value else {
            return "-"
        }
        return "\(format(value.x)), \(format(value.y)), \(format(value.z))"
    }

    private func format(_ value: Float) -> String {
        String(format: "%.2f", Double(value))
    }

    private func formatHash(_ value: UInt64?) -> String {
        guard let value else {
            return "none"
        }
        return "0x" + String(value, radix: 16, uppercase: true)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            )
    }
}

private extension TerrainSurfaceMaterial {
    var label: String {
        switch self {
        case .rock:
            return "rock"
        case .soil:
            return "soil"
        case .grass:
            return "grass"
        case .sand:
            return "sand"
        case .gravel:
            return "gravel"
        case .mud:
            return "mud"
        case .snow:
            return "snow"
        case .shallowWater:
            return "shallow water"
        }
    }
}

private extension PhysicalSurfaceTag {
    var label: String {
        switch self {
        case .hardRock:
            return "hard rock"
        case .looseSoil:
            return "loose soil"
        case .softGrass:
            return "soft grass"
        case .looseSand:
            return "loose sand"
        case .looseGravel:
            return "loose gravel"
        case .stickyMud:
            return "sticky mud"
        case .compactSnow:
            return "compact snow"
        case .shallowWater:
            return "shallow water"
        }
    }
}

private extension AudioSurfaceTag {
    var label: String {
        switch self {
        case .stone:
            return "stone"
        case .dirt:
            return "dirt"
        case .grass:
            return "grass"
        case .sand:
            return "sand"
        case .gravel:
            return "gravel"
        case .mud:
            return "mud"
        case .snow:
            return "snow"
        case .water:
            return "water"
        }
    }
}
