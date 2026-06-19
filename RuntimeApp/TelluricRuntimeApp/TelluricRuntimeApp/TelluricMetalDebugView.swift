import SwiftUI

struct TelluricMetalDebugView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel
    @State private var renderErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            ZStack(alignment: .topLeading) {
                TelluricMetalViewRepresentable(
                    meshDescriptors: model.debugTerrainMeshDescriptors,
                    meshHash: model.debugTerrainMeshHash,
                    renderErrorMessage: $renderErrorMessage
                )
                .frame(minHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                )

                if let renderErrorMessage {
                    Text(renderErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.red.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(10)
                }
            }
        }
        .padding(12)
        .background(panelBackground)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Metal terrain")
                    .font(.headline)
                Text("RenderCoreMetal debug viewport")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(model.debugTerrainMeshCount) meshes")
                    .font(.caption.monospacedDigit())
                Text("0x" + String(model.debugTerrainMeshHash, radix: 16, uppercase: true))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
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
    TelluricMetalDebugView(model: TelluricDebugRuntimeModel())
}
