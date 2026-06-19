enum TelluricDebugCameraPreset: String, CaseIterable, Hashable {
    case isometric
    case topDown
    case side
    case custom

    static let viewportPresets: [TelluricDebugCameraPreset] = [
        .isometric,
        .topDown,
        .side
    ]

    var label: String {
        switch self {
        case .isometric:
            return "Isometric"
        case .topDown:
            return "Top-down"
        case .side:
            return "Side"
        case .custom:
            return "Custom"
        }
    }
}
