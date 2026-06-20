enum TelluricGameCameraMode: String, CaseIterable, Hashable {
    case playableCloseFollow
    case followIso
    case topDown
    case freeOrbit

    var label: String {
        switch self {
        case .playableCloseFollow:
            return "playable close follow"
        case .followIso:
            return "follow iso"
        case .topDown:
            return "top-down"
        case .freeOrbit:
            return "free orbit"
        }
    }
}
