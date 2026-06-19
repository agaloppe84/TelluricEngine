//
//  ContentView.swift
//  TelluricRuntimeApp
//
//  Created by Work on 19/06/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = TelluricDebugRuntimeModel()

    var body: some View {
        TelluricDebugView(model: model)
    }
}

#Preview {
    ContentView()
}
