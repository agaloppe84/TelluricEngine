import SwiftUI

struct TelluricDebugDashboardView: View {
    @ObservedObject var model: TelluricDebugRuntimeModel

    var body: some View {
        TelluricDebugView(model: model)
    }
}
