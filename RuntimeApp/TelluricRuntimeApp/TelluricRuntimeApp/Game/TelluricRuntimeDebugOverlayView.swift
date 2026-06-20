import RenderCoreMetal
import SwiftUI

struct TelluricRuntimeDebugOverlayView: View {
    @ObservedObject var model: TelluricGameRuntimeModel
    let frameStats: MetalDebugFrameStats

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            row("Overlay", model.isDebugOverlayEnabled ? "enabled" : "disabled")
            row("Wire", model.displayOptions.isWireframeEnabled ? "on" : "off")
            row("Bounds", model.displayOptions.showsBounds ? "on" : "off")
            row("Normals", model.displayOptions.normals.isEnabled ? "on" : "off")
            row("Grid", model.displayOptions.grid.isEnabled ? "on" : "off")
            row("Frame", String(format: "%.2f ms", frameStats.frameTimeMilliseconds))
            row("Verts", "\(frameStats.renderedVertexCount)")
            row("Idx", "\(frameStats.renderedIndexCount)")
            row("Streaming", model.streamingUpdateLabel)
            row("Full", model.lastStreamingUpdate.isFullRebuild ? "yes" : "no")
        }
        .font(.caption2.monospacedDigit())
        .padding(10)
        .foregroundStyle(.white)
        .background(Color.black.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(spacing: 7) {
            Text(label)
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 58, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

#Preview {
    TelluricRuntimeDebugOverlayView(
        model: TelluricGameRuntimeModel(),
        frameStats: .zero
    )
}
