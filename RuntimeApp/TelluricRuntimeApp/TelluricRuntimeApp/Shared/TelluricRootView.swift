import SwiftUI

struct TelluricRootView: View {
    @State private var mode: TelluricRuntimeMode = .defaultMode
    @StateObject private var gameModel = TelluricGameRuntimeModel()
    @StateObject private var debugModel = TelluricDebugRuntimeModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Runtime mode", selection: $mode) {
                    ForEach(TelluricRuntimeMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Spacer()

                Text(mode == .game ? "Playable runtime slice" : "Debug dashboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            switch mode {
            case .game:
                TelluricGameRuntimeView(model: gameModel)
            case .debug:
                TelluricDebugDashboardView(model: debugModel)
            }
        }
    }
}

#Preview {
    TelluricRootView()
}
