import SwiftUI

struct TelluricRootView: View {
    static let usesSeparateDebugDashboard = false

    @StateObject private var runtimeScene: TelluricRuntimeSceneController

    init() {
        let scene = TelluricRuntimeSceneController()
        _runtimeScene = StateObject(wrappedValue: scene)
    }

    var body: some View {
        TelluricGameRuntimeView(model: runtimeScene)
    }
}

#Preview {
    TelluricRootView()
}
