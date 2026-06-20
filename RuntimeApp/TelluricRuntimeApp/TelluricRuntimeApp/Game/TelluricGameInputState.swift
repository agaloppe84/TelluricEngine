enum TelluricGameInputSource: String, Hashable {
    case none
    case keyboard
    case controller

    var label: String {
        switch self {
        case .none:
            return "none"
        case .keyboard:
            return "keyboard"
        case .controller:
            return "controller"
        }
    }
}

struct TelluricGameInputState: Hashable {
    var moveX: Float
    var moveZ: Float
    var source: TelluricGameInputSource

    init(
        moveX: Float = 0,
        moveZ: Float = 0,
        source: TelluricGameInputSource = .none
    ) {
        self.moveX = moveX.isFinite ? moveX : 0
        self.moveZ = moveZ.isFinite ? moveZ : 0
        self.source = source
    }

    static let idle = TelluricGameInputState()

    var hasMovement: Bool {
        moveX != 0 || moveZ != 0
    }
}
