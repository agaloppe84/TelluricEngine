import EngineCore
import SwiftUI

struct TelluricSnapshotStatsView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Snapshot")
                .font(.headline)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            statRows
            hashRows
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private var statRows: some View {
        VStack(spacing: 7) {
            statRow("Records", "\(model.totalRecords)")
            statRow("Active", "\(model.activeRecords)")
            statRow("Resident", "\(model.residentRecords)")
            statRow("Meshed", "\(model.meshedRecords)")
            statRow("Metal meshes", "\(model.debugTerrainMeshCount)")
            statRow("Sample only", "\(model.sampleOnlyRecords)")
            statRow("Render candidates", "\(model.snapshot?.stats.renderCandidateRecords ?? 0)")
            statRow("Vertices", "\(model.snapshot?.stats.estimatedVertexCount ?? 0)")
            statRow("Indices", "\(model.snapshot?.stats.estimatedIndexCount ?? 0)")
        }
    }

    private var hashRows: some View {
        VStack(spacing: 7) {
            statRow("Plan hash", model.planHashLabel)
            statRow("Cache hash", model.cacheHashLabel)
            statRow("Snapshot hash", model.snapshotHashLabel)
        }
        .padding(.top, 4)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .font(.caption)
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
