import SwiftUI

struct TelluricMetalCameraControlsView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Camera")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .leading)

                ForEach(TelluricDebugCameraPreset.viewportPresets, id: \.self) { preset in
                    Button(preset.label) {
                        model.applyDebugCameraPreset(preset)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(model.currentCameraPreset == preset ? .accentColor : .gray)
                }

                Button("Fit terrain", action: model.fitDebugCameraToTerrain)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Reset", action: model.resetDebugCamera)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Focus probe", action: model.focusDebugCameraOnProbe)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(model.playerProbeWorldPoint == nil)
            }

            HStack(spacing: 8) {
                Text("Move")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .leading)

                cameraButton("Zoom in", systemImage: "plus.magnifyingglass", action: model.zoomDebugCameraIn)
                cameraButton("Zoom out", systemImage: "minus.magnifyingglass", action: model.zoomDebugCameraOut)
                cameraButton("Rotate left", systemImage: "rotate.left", action: model.rotateDebugCameraLeft)
                cameraButton("Rotate right", systemImage: "rotate.right", action: model.rotateDebugCameraRight)
                cameraButton("Pitch up", systemImage: "arrow.up.to.line", action: model.pitchDebugCameraUp)
                cameraButton("Pitch down", systemImage: "arrow.down.to.line", action: model.pitchDebugCameraDown)
                cameraButton("Pan north", systemImage: "arrow.up", action: model.panDebugCameraNorth)
                cameraButton("Pan south", systemImage: "arrow.down", action: model.panDebugCameraSouth)
                cameraButton("Pan west", systemImage: "arrow.left", action: model.panDebugCameraWest)
                cameraButton("Pan east", systemImage: "arrow.right", action: model.panDebugCameraEast)
            }
        }
        .buttonStyle(.bordered)
    }

    private func cameraButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .frame(width: 28)
        }
        .help(title)
    }
}
