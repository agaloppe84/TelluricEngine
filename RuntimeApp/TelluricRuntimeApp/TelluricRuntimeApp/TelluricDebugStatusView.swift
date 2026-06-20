import RenderCoreMetal
import SwiftUI

struct TelluricDebugStatusView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What am I seeing?")
                .font(.headline)

            VStack(spacing: 7) {
                statusRow("Scene", model.runtimeSceneModeLabel)
                statusRow("Terrain meshes", "\(model.debugTerrainMeshCount)")
                statusRow("Terrain visible", model.isTerrainVisible ? "yes" : "no")
                statusRow("Probe visible", model.isProbeVisible ? "yes" : "no")
                statusRow("Sanity preset", model.sanityDebugPresetLabel)
                statusRow("Camera preset", model.currentCameraPresetLabel)
                statusRow("Color mode", model.debugTerrainColorMode.label)
                statusRow("Probe position", model.playerProbePositionLabel)
                statusRow("Probe walkability", model.probeWalkabilityLabel)
                statusRow("Selected chunk", model.selectedChunkStatusLabel)
                statusRow("Picked point", model.pickedTerrainPointLabel)
            }

            if model.debugWarnings.isEmpty == false {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.debugWarnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
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

#Preview {
    TelluricDebugStatusView(model: TelluricDebugRuntimeModel())
}
