import AppKit
import MetalKit
import simd

final class TelluricInteractiveMTKView: MTKView {
    var onClick: ((SIMD2<Float>, SIMD2<Float>) -> Void)?
    var onHover: ((SIMD2<Float>, SIMD2<Float>) -> Void)?
    var onScroll: ((Float) -> Void)?
    var onOrbitDrag: ((Float, Float) -> Void)?
    var onPanDrag: ((Float, Float) -> Void)?

    private var trackingAreaRef: NSTrackingArea?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func updateTrackingAreas() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .activeInKeyWindow,
            .inVisibleRect
        ]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self)
        addTrackingArea(area)
        trackingAreaRef = area
        super.updateTrackingAreas()
    }

    override func mouseMoved(with event: NSEvent) {
        let point = screenPoint(from: event)
        onHover?(point, viewportSize)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = screenPoint(from: event)
        onClick?(point, viewportSize)
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = screenPoint(from: event)
        onClick?(point, viewportSize)
    }

    override func mouseDragged(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            onPanDrag?(Float(event.deltaX), Float(event.deltaY))
        } else {
            onOrbitDrag?(Float(event.deltaX), Float(event.deltaY))
        }
    }

    override func rightMouseDragged(with event: NSEvent) {
        onPanDrag?(Float(event.deltaX), Float(event.deltaY))
    }

    override func scrollWheel(with event: NSEvent) {
        onScroll?(Float(event.scrollingDeltaY))
    }

    private var viewportSize: SIMD2<Float> {
        let scale = window?.backingScaleFactor ?? 1
        return SIMD2<Float>(
            Float(max(bounds.width * scale, 1)),
            Float(max(bounds.height * scale, 1))
        )
    }

    private func screenPoint(from event: NSEvent) -> SIMD2<Float> {
        let point = convert(event.locationInWindow, from: nil)
        let scale = window?.backingScaleFactor ?? 1
        return SIMD2<Float>(
            Float(point.x * scale),
            Float((bounds.height - point.y) * scale)
        )
    }
}
