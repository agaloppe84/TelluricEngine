enum TelluricRuntimeMode: String, CaseIterable, Hashable {
    case game
    case debug

    static let defaultMode: TelluricRuntimeMode = .game

    var label: String {
        switch self {
        case .game:
            return "Game"
        case .debug:
            return "Debug"
        }
    }
}
