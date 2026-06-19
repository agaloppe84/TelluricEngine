import SwiftUI

struct TelluricMetalCameraControlsView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        HStack(spacing: 8) {
            cameraButton("Fit", systemImage: "viewfinder", action: model.fitDebugCameraToTerrain)
            cameraButton("Reset", systemImage: "arrow.counterclockwise", action: model.resetDebugCamera)
            Divider().frame(height: 22)
            cameraButton("Zoom in", systemImage: "plus.magnifyingglass", action: model.zoomDebugCameraIn)
            cameraButton("Zoom out", systemImage: "minus.magnifyingglass", action: model.zoomDebugCameraOut)
            Divider().frame(height: 22)
            cameraButton("Left", systemImage: "rotate.left", action: model.rotateDebugCameraLeft)
            cameraButton("Right", systemImage: "rotate.right", action: model.rotateDebugCameraRight)
            cameraButton("Pitch up", systemImage: "arrow.up.to.line", action: model.pitchDebugCameraUp)
            cameraButton("Pitch down", systemImage: "arrow.down.to.line", action: model.pitchDebugCameraDown)
            Divider().frame(height: 22)
            cameraButton("North", systemImage: "arrow.up", action: model.panDebugCameraNorth)
            cameraButton("South", systemImage: "arrow.down", action: model.panDebugCameraSouth)
            cameraButton("West", systemImage: "arrow.left", action: model.panDebugCameraWest)
            cameraButton("East", systemImage: "arrow.right", action: model.panDebugCameraEast)
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
