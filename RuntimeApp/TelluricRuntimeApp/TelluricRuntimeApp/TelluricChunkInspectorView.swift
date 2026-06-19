import EngineCore
import Foundation
import SwiftUI

struct TelluricChunkInspectorView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Chunk")
                    .font(.headline)
                Spacer()
                Button {
                    model.clearSelection()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .labelStyle(.iconOnly)
                }
                .disabled(model.selectedChunkCoord == nil)
            }

            if let coord = model.selectedChunkCoord {
                selectedDetails(coord: coord)
            } else {
                Text("No selection")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.bordered)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private func selectedDetails(coord: WorldChunkCoord) -> some View {
        let record = model.selectedChunkRecord
        let target = model.selectedChunkTarget
        let mesh = record?.meshPayload

        return VStack(spacing: 7) {
            detailRow("Coord", "(\(coord.x), \(coord.z))")
            detailRow("Target", target?.targetState.label ?? "none")
            detailRow("Lifecycle", record?.lifecycleState.label ?? "not cached")
            detailRow("Payload", record?.payloadState.label ?? "absent")
            detailRow("Priority", record.map { "\($0.priority.rank)" } ?? target.map { "\($0.priority.rank)" } ?? "-")
            detailRow("Sample", record?.samplePayload == nil ? "no" : "yes")
            detailRow("Mesh", mesh == nil ? "no" : "yes")
            detailRow("Render candidate", record?.renderCandidate == nil ? "no" : "yes")
            detailRow("Vertices", mesh.map { "\($0.vertices.count)" } ?? "0")
            detailRow("Indices", mesh.map { "\($0.indices.count)" } ?? "0")
            detailRow("Surfaces", mesh.map { "\($0.surfacePayload.samples.count)" } ?? "0")

            if let bounds = mesh?.bounds {
                detailRow("Bounds min", format(bounds.min))
                detailRow("Bounds max", format(bounds.max))
            }

            detailRow("Chunk hash", formatHash(record?.chunkID.stableHash ?? target?.chunkID.stableHash))
            detailRow("Mesh hash", formatHash(mesh?.stableHash))
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

    private func format(_ value: TEVec3f) -> String {
        "\(format(value.x)), \(format(value.y)), \(format(value.z))"
    }

    private func format(_ value: Float) -> String {
        String(format: "%.1f", Double(value))
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

private extension ChunkLifecycleState {
    var label: String {
        switch self {
        case .unloaded:
            return "unloaded"
        case .sampleRequested:
            return "sample requested"
        case .sampled:
            return "sampled"
        case .meshRequested:
            return "mesh requested"
        case .meshed:
            return "meshed"
        case .resident:
            return "resident"
        case .active:
            return "active"
        case .evictionCandidate:
            return "eviction"
        }
    }
}

private extension CachedChunkPayloadState {
    var label: String {
        switch self {
        case .empty:
            return "empty"
        case .sampled:
            return "sampled"
        case .meshed:
            return "meshed"
        case .resident:
            return "resident"
        case .active:
            return "active"
        case .evictionCandidate:
            return "eviction"
        }
    }
}
