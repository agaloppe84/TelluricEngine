import EngineCore
import SwiftUI

struct TelluricChunkCellView: View {
    let cell: TelluricDebugChunkCell
    let onSelect: (WorldChunkCoord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("\(cell.coord.x),\(cell.coord.z)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Spacer(minLength: 2)
                if cell.isCenter {
                    Image(systemName: "scope")
                        .font(.system(size: 10, weight: .bold))
                }
            }

            Text(cell.stateLabel)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 4) {
                Text(cell.payloadLabel)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 2)
                Text(priorityLabel)
                    .font(.system(size: 9, design: .monospaced))
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)
        }
        .padding(7)
        .frame(width: 76, height: 64, alignment: .topLeading)
        .background(background)
        .overlay(border)
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            onSelect(cell.coord)
        }
    }

    private var priorityLabel: String {
        guard let priorityRank = cell.priorityRank else {
            return "-"
        }
        return "p\(priorityRank)"
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(fillColor.opacity(cell.isCached ? 0.88 : 0.42))
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(
                cell.isSelected ? Color.yellow : (cell.isCenter ? Color.white : Color.black.opacity(0.24)),
                lineWidth: cell.isSelected || cell.isCenter ? 2 : 1
            )
    }

    private var fillColor: Color {
        switch cell.lifecycleState {
        case .active:
            return Color(red: 0.85, green: 0.18, blue: 0.16)
        case .resident:
            return Color(red: 0.17, green: 0.58, blue: 0.28)
        case .meshed, .meshRequested:
            return Color(red: 0.18, green: 0.37, blue: 0.76)
        case .sampled, .sampleRequested:
            return Color(red: 0.86, green: 0.68, blue: 0.22)
        case .evictionCandidate:
            return Color(red: 0.55, green: 0.47, blue: 0.40)
        case .unloaded:
            return Color(red: 0.25, green: 0.27, blue: 0.29)
        }
    }
}
