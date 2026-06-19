import SwiftUI

struct TelluricPlayerProbeControlsView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Player probe")
                    .font(.headline)
                Spacer()
                Toggle("Show", isOn: $model.showsPlayerProbe)
                    .toggleStyle(.checkbox)
            }

            HStack(spacing: 8) {
                Button {
                    model.movePlayerProbeWest()
                } label: {
                    Label("West", systemImage: "arrow.left")
                        .labelStyle(.iconOnly)
                }

                VStack(spacing: 6) {
                    Button {
                        model.movePlayerProbeNorth()
                    } label: {
                        Label("North", systemImage: "arrow.up")
                            .labelStyle(.iconOnly)
                    }
                    Button {
                        model.movePlayerProbeSouth()
                    } label: {
                        Label("South", systemImage: "arrow.down")
                            .labelStyle(.iconOnly)
                    }
                }

                Button {
                    model.movePlayerProbeEast()
                } label: {
                    Label("East", systemImage: "arrow.right")
                        .labelStyle(.iconOnly)
                }

                Button {
                    model.resetPlayerProbe()
                } label: {
                    Label("Reset", systemImage: "scope")
                }

                Button {
                    model.movePlayerProbeToPickedPoint()
                } label: {
                    Label("Move to pick", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
                .disabled(model.pickedWorldPoint == nil)
            }

            HStack(spacing: 8) {
                Text("Step")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: stepBinding, in: 0.25...8.0)
                Text(String(format: "%.2f", Double(model.playerProbeStepMeters)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .trailing)
            }
        }
        .buttonStyle(.bordered)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
    }

    private var stepBinding: Binding<Double> {
        Binding(
            get: { Double(model.playerProbeStepMeters) },
            set: { model.playerProbeStepMeters = Float($0) }
        )
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

