import AppKit
import Dispatch
import SwiftUI

struct TelluricGameKeyboardCaptureView: NSViewRepresentable {
    let onInput: (TelluricGameInputState) -> Void

    func makeNSView(context: Context) -> KeyboardView {
        let view = KeyboardView()
        view.onInput = onInput
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyboardView, context: Context) {
        nsView.onInput = onInput
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class KeyboardView: NSView {
        var onInput: ((TelluricGameInputState) -> Void)?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func keyDown(with event: NSEvent) {
            if let input = Self.input(for: event) {
                onInput?(input)
                return
            }
            super.keyDown(with: event)
        }

        private static func input(for event: NSEvent) -> TelluricGameInputState? {
            switch event.keyCode {
            case 126:
                return TelluricGameInputState(moveX: 0, moveZ: 1, source: .keyboard)
            case 125:
                return TelluricGameInputState(moveX: 0, moveZ: -1, source: .keyboard)
            case 123:
                return TelluricGameInputState(moveX: -1, moveZ: 0, source: .keyboard)
            case 124:
                return TelluricGameInputState(moveX: 1, moveZ: 0, source: .keyboard)
            default:
                break
            }

            let key = event.charactersIgnoringModifiers?.lowercased()
            switch key {
            case "w", "z":
                return TelluricGameInputState(moveX: 0, moveZ: 1, source: .keyboard)
            case "s":
                return TelluricGameInputState(moveX: 0, moveZ: -1, source: .keyboard)
            case "a", "q":
                return TelluricGameInputState(moveX: -1, moveZ: 0, source: .keyboard)
            case "d":
                return TelluricGameInputState(moveX: 1, moveZ: 0, source: .keyboard)
            default:
                return nil
            }
        }
    }
}
