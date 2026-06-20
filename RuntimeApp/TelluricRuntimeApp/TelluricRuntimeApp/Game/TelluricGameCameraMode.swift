enum TelluricGameCameraMode: String, CaseIterable, Hashable {
    case followIso
    case topDown
    case freeOrbit

    var label: String {
        switch self {
        case .followIso:
            return "follow iso"
        case .topDown:
            return "top-down"
        case .freeOrbit:
            return "free orbit"
        }
    }
}
