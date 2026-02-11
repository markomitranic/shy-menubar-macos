import AppKit

protocol ShyModule: AnyObject {
    var id: String { get }
    var name: String { get }
    var isActive: Bool { get }
    var onStateChanged: (() -> Void)? { get set }

    func toggle()
    func drawPeek(in rect: NSRect, wallY: CGFloat, cx: CGFloat)
}

func drawModuleIcon(for module: ShyModule, width w: CGFloat = 28, height h: CGFloat = 22) -> NSImage {
    let size = NSSize(width: w, height: h)
    let image = NSImage(size: size, flipped: true) { rect in
        NSColor.black.set()

        let wallY: CGFloat = 17
        let cx: CGFloat = w / 2

        // Wall line across the top
        let wall = NSBezierPath()
        wall.move(to: NSPoint(x: 0.5, y: wallY))
        wall.line(to: NSPoint(x: w - 0.5, y: wallY))
        wall.lineWidth = 1.5
        wall.stroke()

        // Hands gripping the wall
        for handX: CGFloat in [2.5, 21.5] {
            let hand = NSBezierPath()
            hand.move(to: NSPoint(x: handX, y: wallY))
            hand.curve(
                to: NSPoint(x: handX + 4, y: wallY),
                controlPoint1: NSPoint(x: handX, y: wallY + 3),
                controlPoint2: NSPoint(x: handX + 4, y: wallY + 3))
            hand.lineWidth = 1.5
            hand.lineCapStyle = .round
            hand.stroke()
        }

        if module.isActive {
            module.drawPeek(in: rect, wallY: wallY, cx: cx)
        }

        return true
    }

    image.isTemplate = true
    return image
}
