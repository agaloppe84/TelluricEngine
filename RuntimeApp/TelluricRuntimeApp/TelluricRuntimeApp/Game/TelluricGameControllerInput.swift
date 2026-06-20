import Combine
import GameController

@MainActor
final class TelluricGameControllerInput: ObservableObject {
    @Published private(set) var statusLabel: String = "controller none"
    var onMoveVector: ((Float, Float) -> Void)?

    init() {
        refreshControllers()
    }

    func refreshControllers() {
        let controllers = GCController.controllers()
        guard let controller = controllers.first else {
            statusLabel = "controller none"
            return
        }

        statusLabel = controller.vendorName.map { "controller \($0)" } ?? "controller connected"
        configure(controller)
    }

    private func configure(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else {
            statusLabel = "controller no extended gamepad"
            return
        }

        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            let deadzone: Float = 0.18
            let x = abs(xValue) >= deadzone ? xValue : 0
            let z = abs(yValue) >= deadzone ? yValue : 0
            guard x != 0 || z != 0 else {
                return
            }

            Task { @MainActor in
                self?.onMoveVector?(x, z)
            }
        }
    }
}
