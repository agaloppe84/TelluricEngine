import EngineCore
import Foundation
import SwiftUI

struct TelluricPlayerProbeInspectorView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Probe terrain")
                    .font(.headline)
                Spacer()
                Text(model.playerProbe?.isGrounded == true ? "grounded" : "not grounded")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let probe = model.playerProbe {
                probeDetails(probe)
            } else {
                Text("No probe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private func probeDetails(_ probe: TerrainProbe) -> some View {
        let result = probe.lastQueryResult
        let surface = result?.surface

        return VStack(spacing: 7) {
            detailRow("Position", format(probe.worldPosition))
            detailRow("Height", result.map { String(format: "%.2f m", Double($0.heightMeters)) } ?? "-")
            detailRow("Slope", result.map { String(format: "%.1f deg", Double($0.slopeDegrees)) } ?? "-")
            detailRow("Slope class", result.map { String(describing: $0.slopeClassification) } ?? "-")
            detailRow("Walkability", walkabilityLabel(probe.walkability))
            detailRow("Material", surface.map { String(describing: $0.material) } ?? "-")
            detailRow("Physical", surface.map { String(describing: $0.physicalTag) } ?? "-")
            detailRow("Audio", surface.map { String(describing: $0.audioTag) } ?? "-")
            detailRow("Sample", format(result?.sampleCoord))
            detailRow("Inside", result?.isInsideKnownTerrain == true ? "yes" : "no")
            detailRow("Probe hash", formatHash(probe.stableHash))
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

    private func format(_ position: TerrainWorldPosition) -> String {
        String(
            format: "%.2f, %.2f, %.2f",
            Double(position.x),
            Double(position.y),
            Double(position.z)
        )
    }

    private func format(_ coord: TerrainSampleCoord?) -> String {
        guard let coord else {
            return "-"
        }
        return "(\(coord.x), \(coord.z))"
    }

    private func walkabilityLabel(_ walkability: TerrainWalkability) -> String {
        "\(walkability.isWalkable ? "yes" : "no") / \(walkability.reason)"
    }

    private func formatHash(_ value: UInt64) -> String {
        "0x" + String(value, radix: 16, uppercase: true)
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

