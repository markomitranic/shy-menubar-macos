import AppKit

class MenuBarModule: NSObject, ShyModule {
    let id = "menuBar"
    let name = "Menu Bar"
    var onStateChanged: (() -> Void)?

    private(set) var isMenuBarHidden: Bool

    /// Active when the menu bar is visible (character peeks = thing is showing)
    var isActive: Bool { !isMenuBarHidden }

    override init() {
        isMenuBarHidden = Self.readSystemState()
        super.init()

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(menuBarSettingChanged),
            name: NSNotification.Name("com.apple.dock.prefchanged"),
            object: nil
        )
    }

    func toggle() {
        let newValue = !isMenuBarHidden
        isMenuBarHidden = newValue
        onStateChanged?()

        DispatchQueue.global(qos: .userInitiated).async {
            let script = NSAppleScript(source: """
                tell application "System Events" to tell dock preferences to set autohide menu bar to \(newValue)
            """)
            script?.executeAndReturnError(nil)
        }
    }

    func drawPeek(in rect: NSRect, wallY: CGFloat, cx: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: 0, width: rect.width, height: wallY))

        let headR: CGFloat = 7.5
        let cy: CGFloat = wallY - headR + 2.5

        // Corgi ears
        let leftEar = NSBezierPath()
        leftEar.move(to: NSPoint(x: cx - headR + 1, y: cy - headR + 4))
        leftEar.curve(
            to: NSPoint(x: cx - headR - 1, y: cy - headR - 2),
            controlPoint1: NSPoint(x: cx - headR - 3, y: cy - headR + 4),
            controlPoint2: NSPoint(x: cx - headR - 3, y: cy - headR))
        leftEar.curve(
            to: NSPoint(x: cx - headR + 6, y: cy - headR + 2),
            controlPoint1: NSPoint(x: cx - headR + 1, y: cy - headR - 3),
            controlPoint2: NSPoint(x: cx - headR + 5, y: cy - headR - 1))
        leftEar.lineWidth = 1.5
        leftEar.stroke()

        let rightEar = NSBezierPath()
        rightEar.move(to: NSPoint(x: cx + headR - 1, y: cy - headR + 4))
        rightEar.curve(
            to: NSPoint(x: cx + headR + 1, y: cy - headR - 2),
            controlPoint1: NSPoint(x: cx + headR + 3, y: cy - headR + 4),
            controlPoint2: NSPoint(x: cx + headR + 3, y: cy - headR))
        rightEar.curve(
            to: NSPoint(x: cx + headR - 6, y: cy - headR + 2),
            controlPoint1: NSPoint(x: cx + headR - 1, y: cy - headR - 3),
            controlPoint2: NSPoint(x: cx + headR - 5, y: cy - headR - 1))
        rightEar.lineWidth = 1.5
        rightEar.stroke()

        // Head
        let head = NSBezierPath(
            ovalIn: NSRect(
                x: cx - headR, y: cy - headR,
                width: headR * 2, height: headR * 2
            ))
        head.lineWidth = 1.5
        head.stroke()

        // Eyes
        let eyeR: CGFloat = 1.2
        let eyeY = cy - headR * 0.2
        NSBezierPath(
            ovalIn: NSRect(
                x: cx - 3.5 - eyeR, y: eyeY - eyeR,
                width: eyeR * 2, height: eyeR * 2
            )
        ).fill()
        NSBezierPath(
            ovalIn: NSRect(
                x: cx + 3.5 - eyeR, y: eyeY - eyeR,
                width: eyeR * 2, height: eyeR * 2
            )
        ).fill()

        // Smile
        let smile = NSBezierPath()
        smile.move(to: NSPoint(x: cx - 2.5, y: cy + headR * 0.1))
        smile.curve(
            to: NSPoint(x: cx + 2.5, y: cy + headR * 0.1),
            controlPoint1: NSPoint(x: cx - 1, y: cy + headR * 0.4),
            controlPoint2: NSPoint(x: cx + 1, y: cy + headR * 0.4))
        smile.lineWidth = 1.2
        smile.lineCapStyle = .round
        smile.stroke()

        ctx.restoreGState()
    }

    @objc private func menuBarSettingChanged() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let current = Self.readSystemState()
            DispatchQueue.main.async {
                self?.isMenuBarHidden = current
                self?.onStateChanged?()
            }
        }
    }

    private static func readSystemState() -> Bool {
        let script = NSAppleScript(source: """
            tell application "System Events" to tell dock preferences to get autohide menu bar
        """)
        guard let result = script?.executeAndReturnError(nil) else { return false }
        return result.booleanValue
    }
}
