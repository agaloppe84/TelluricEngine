import Foundation
import RenderCoreMetal
import SwiftUI

struct TelluricMetalDebugToolbarView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Picker("Color", selection: colorModeBinding) {
                    ForEach(MetalDebugTerrainColorMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)

                Toggle("Wireframe", isOn: $model.isWireframeEnabled)
                    .toggleStyle(.checkbox)
                Toggle("Picking", isOn: $model.isViewportPickingEnabled)
                    .toggleStyle(.checkbox)
            }

            HStack(spacing: 12) {
                Toggle("Bounds", isOn: $model.showsBounds)
                    .toggleStyle(.checkbox)
                Toggle("Normals", isOn: $model.showsNormals)
                    .toggleStyle(.checkbox)
                Toggle("Grid", isOn: $model.showsGrid)
                    .toggleStyle(.checkbox)
                Toggle("Pick point", isOn: $model.showsPickedPoint)
                    .toggleStyle(.checkbox)
                Toggle("Probe", isOn: $model.showsPlayerProbe)
                    .toggleStyle(.checkbox)

                HStack(spacing: 6) {
                    Text("Vertical")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: verticalScaleBinding, in: 0.1...1.0)
                        .frame(width: 120)
                    Text(String(format: "%.2f", Double(model.debugVerticalScale)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .trailing)
                }

                if model.showsNormals {
                    HStack(spacing: 6) {
                        Text("Normals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: normalLengthBinding, in: 0.5...8.0)
                            .frame(width: 120)
                        Text(String(format: "%.1f", Double(model.debugNormalLength)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }

            TelluricMetalCameraControlsView(model: model)
        }
    }

    private var colorModeBinding: Binding<MetalDebugTerrainColorMode> {
        Binding(
            get: { model.debugTerrainColorMode },
            set: { model.setDebugTerrainColorMode($0) }
        )
    }

    private var normalLengthBinding: Binding<Double> {
        Binding(
            get: { Double(model.debugNormalLength) },
            set: { model.debugNormalLength = Float($0) }
        )
    }

    private var verticalScaleBinding: Binding<Double> {
        Binding(
            get: { Double(model.debugVerticalScale) },
            set: { model.debugVerticalScale = Float($0) }
        )
    }
}
