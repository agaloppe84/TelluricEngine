import RenderCoreMetal
import SwiftUI

struct TelluricGameHUDView: View {
    @ObservedObject var model: TelluricGameRuntimeModel
    let frameStats: MetalDebugFrameStats
    let controllerStatus: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            row("FPS", String(format: "%.1f", frameStats.framesPerSecond))
            row("Player", model.playerPositionLabel)
            row("Chunk", model.playerChunkLabel)
            row("Center", model.centerChunkLabel)
            row("Meshes", "\(model.meshCount)")
            row("Resident", "\(model.residentChunkCount)")
            row("Active", "\(model.activeChunkCount)")
            row("Rebuilds", "\(model.rebuildCount)")
            row("Center Δ", "\(model.centerChunkChangeCount)")
            row("Stream", model.streamingUpdateLabel)
            row("Chunk m", String(format: "%.0f", Double(model.chunkWorldSizeMeters)))
            row("Ground", model.isGrounded ? "yes" : "no")
            row("Walk", model.walkabilityLabel)
            row("Input", model.lastInputSource.label)
            row("Pad", controllerStatus)
            row("Debug", model.debugOverlayStatusLabel)
        }
        .font(.caption2.monospacedDigit())
        .padding(10)
        .foregroundStyle(.white)
        .background(Color.black.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(spacing: 7) {
            Text(label)
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 54, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
