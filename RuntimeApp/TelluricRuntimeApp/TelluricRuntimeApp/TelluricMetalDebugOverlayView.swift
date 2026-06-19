import Foundation
import RenderCoreMetal
import SwiftUI

struct TelluricMetalDebugOverlayView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel
    let frameStats: MetalDebugFrameStats

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("FPS", String(format: "%.1f", frameStats.framesPerSecond))
            row("Frame", String(format: "%.2f ms", frameStats.frameTimeMilliseconds))
            row("Meshes", "\(frameStats.renderedMeshCount)")
            row("Vertices", "\(frameStats.renderedVertexCount)")
            row("Indices", "\(frameStats.renderedIndexCount)")
            row("Lines", "\(frameStats.renderedLineVertexCount)")
            row("Mode", model.debugTerrainColorMode.label)
            row("Wire", model.isWireframeEnabled ? "on" : "off")
            row("Bounds", model.showsBounds ? "on" : "off")
            row("Normals", model.showsNormals ? "on" : "off")
            row("Camera", cameraLabel)
            row("Selected", model.selectedChunkLabel)
        }
        .font(.caption2.monospacedDigit())
        .padding(8)
        .foregroundStyle(.white)
        .background(Color.black.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var cameraLabel: String {
        String(
            format: "yaw %.2f pitch %.2f d %.0f",
            Double(model.debugCameraState.yawRadians),
            Double(model.debugCameraState.pitchRadians),
            Double(model.debugCameraState.distance)
        )
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 48, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
