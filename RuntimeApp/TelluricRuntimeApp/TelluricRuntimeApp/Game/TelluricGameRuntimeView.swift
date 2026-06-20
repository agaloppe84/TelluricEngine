import RenderCoreMetal
import SwiftUI

struct TelluricGameRuntimeView: View {
    @ObservedObject var model: TelluricGameRuntimeModel
    @StateObject private var controllerInput = TelluricGameControllerInput()
    @State private var renderErrorMessage: String?
    @State private var frameStats = MetalDebugFrameStats.zero

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimelineView(.periodic(from: .now, by: 0.35)) { timeline in
                TelluricMetalViewRepresentable(
                    meshDescriptors: model.meshDescriptors,
                    uploadHash: model.uploadHash,
                    displayOptions: model.displayOptions,
                    cameraState: model.cameraState,
                    pickedPoint: nil,
                    probePoint: nil,
                    playerPoint: model.playerPoint,
                    isViewportPickingEnabled: false,
                    statsTick: timeline.date,
                    renderErrorMessage: $renderErrorMessage,
                    frameStats: $frameStats,
                    onPickResult: { _ in },
                    onHoverResult: { _ in },
                    onScrollZoom: { deltaY in
                        if deltaY > 0 {
                            model.zoomCameraOut()
                        } else {
                            model.zoomCameraIn()
                        }
                    },
                    onOrbitDrag: { deltaX, _ in
                        if deltaX < 0 {
                            model.rotateCameraLeft()
                        } else if deltaX > 0 {
                            model.rotateCameraRight()
                        }
                    },
                    onPanDrag: { _, _ in }
                )
            }
            .ignoresSafeArea()

            TelluricGameKeyboardCaptureView { input in
                model.applyKeyboardInput(input)
            }
            .frame(width: 1, height: 1)
            .opacity(0.01)

            VStack(alignment: .leading, spacing: 10) {
                TelluricGameHUDView(
                    model: model,
                    frameStats: frameStats,
                    controllerStatus: controllerInput.statusLabel
                )

                if let message = renderErrorMessage ?? model.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.red.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)

            VStack {
                HStack {
                    Spacer()
                    controls
                }
                Spacer()
            }
            .padding(14)
        }
        .background(Color.black)
        .onAppear {
            controllerInput.onMoveVector = { x, z in
                model.applyControllerInput(moveX: x, moveZ: z)
            }
            controllerInput.refreshControllers()
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button("Follow") {
                model.setCameraMode(.followIso)
            }
            Button("Top") {
                model.setCameraMode(.topDown)
            }
            Button("Reset cam") {
                model.resetCamera()
            }
            Button("Reset player") {
                model.resetPlayer()
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(8)
        .background(Color.black.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    TelluricGameRuntimeView(model: TelluricGameRuntimeModel())
}
