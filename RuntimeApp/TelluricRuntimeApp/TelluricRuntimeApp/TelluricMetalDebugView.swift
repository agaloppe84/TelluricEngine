import RenderCoreMetal
import SwiftUI

struct TelluricMetalDebugView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel
    @State private var renderErrorMessage: String?
    @State private var frameStats = MetalDebugFrameStats.zero

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            TelluricMetalDebugToolbarView(model: model)

            ZStack(alignment: .topLeading) {
                TimelineView(.periodic(from: .now, by: 0.35)) { timeline in
                    TelluricMetalViewRepresentable(
                        meshDescriptors: model.debugTerrainMeshDescriptors,
                        uploadHash: model.debugMeshUploadHash,
                        displayOptions: model.debugDisplayOptions,
                        cameraState: model.debugCameraState,
                        pickedPoint: model.pickedWorldPoint,
                        probePoint: model.debugDisplayOptions.probeMarker.isEnabled ? model.playerProbeWorldPoint : nil,
                        playerPoint: model.runtimePlayerWorldPoint,
                        isViewportPickingEnabled: model.isViewportPickingEnabled,
                        statsTick: timeline.date,
                        renderErrorMessage: $renderErrorMessage,
                        frameStats: $frameStats,
                        onPickResult: model.applyViewportPick,
                        onHoverResult: model.applyViewportHover,
                        onScrollZoom: model.zoomDebugCameraFromScroll,
                        onOrbitDrag: model.orbitDebugCameraFromDrag,
                        onPanDrag: model.panDebugCameraFromDrag
                    )
                }
                .frame(minHeight: 420)
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

                VStack {
                    Spacer()
                    HStack {
                        TelluricMetalDebugOverlayView(model: model, frameStats: frameStats)
                        Spacer()
                    }
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
