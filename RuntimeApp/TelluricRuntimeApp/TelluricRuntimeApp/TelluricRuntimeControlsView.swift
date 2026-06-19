import EngineCore
import SwiftUI

struct TelluricRuntimeControlsView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Controls")
                .font(.headline)

            movementGrid

            HStack(spacing: 8) {
                Button {
                    model.rebuild()
                } label: {
                    Label("Rebuild", systemImage: "hammer")
                }

                Button {
                    model.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }

            VStack(spacing: 7) {
                detailRow("Center", model.centerLabel)
                detailRow("Version", model.generatorVersionLabel)
                detailRow("Samples", "\(model.layout.samplesPerAxis)x\(model.layout.samplesPerAxis)")
                detailRow("Radii", "0 / 1 / 2 / 3 / \(model.config.evictionRadiusChunks)")
            }
        }
        .buttonStyle(.bordered)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private var movementGrid: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                Color.clear.frame(width: 78, height: 32)
                movementButton("North", systemImage: "arrow.up", action: model.moveNorth)
                Color.clear.frame(width: 78, height: 32)
            }
            GridRow {
                movementButton("West", systemImage: "arrow.left", action: model.moveWest)
                Color.clear.frame(width: 78, height: 32)
                movementButton("East", systemImage: "arrow.right", action: model.moveEast)
            }
            GridRow {
                Color.clear.frame(width: 78, height: 32)
                movementButton("South", systemImage: "arrow.down", action: model.moveSouth)
                Color.clear.frame(width: 78, height: 32)
            }
        }
    }

    private func movementButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(width: 78)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
