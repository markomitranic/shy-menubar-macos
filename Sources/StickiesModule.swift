import AppKit

class StickiesModule: NSObject, ShyModule {
    let id = "stickies"
    let name = "Stickies"
    var onStateChanged: (() -> Void)?

    private let bundleID = "com.apple.Stickies"
    private(set) var isRunning: Bool

    /// Active when Stickies is running (character peeks = thing is showing)
    var isActive: Bool { isRunning }

    override init() {
        isRunning = Self.checkIfRunning(bundleID: "com.apple.Stickies")
        super.init()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    func toggle() {
        if isRunning {
            quit()
        } else {
            launch()
        }
    }

    func drawPeek(in rect: NSRect, wallY: CGFloat, cx: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: 0, width: rect.width, height: wallY))

        let noteW: CGFloat = 13
        let noteH: CGFloat = 12
        let noteX: CGFloat = cx - noteW / 2
        let noteY: CGFloat = wallY - noteH - 1
        let foldSize: CGFloat = 3.5

        // Sticky note body (fold at bottom-right)
        let note = NSBezierPath()
        note.move(to: NSPoint(x: noteX, y: noteY))
        note.line(to: NSPoint(x: noteX + noteW, y: noteY))
        note.line(to: NSPoint(x: noteX + noteW, y: noteY + noteH - foldSize))
        note.line(to: NSPoint(x: noteX + noteW - foldSize, y: noteY + noteH))
        note.line(to: NSPoint(x: noteX, y: noteY + noteH))
        note.close()
        note.lineWidth = 1.5
        note.stroke()

        // Fold line
        let fold = NSBezierPath()
        fold.move(to: NSPoint(x: noteX + noteW - foldSize, y: noteY + noteH))
        fold.line(to: NSPoint(x: noteX + noteW - foldSize, y: noteY + noteH - foldSize))
        fold.line(to: NSPoint(x: noteX + noteW, y: noteY + noteH - foldSize))
        fold.lineWidth = 1.0
        fold.stroke()

        // Eyes
        let eyeR: CGFloat = 1.2
        let eyeY = noteY + noteH * 0.35
        NSBezierPath(
            ovalIn: NSRect(
                x: cx - 3 - eyeR, y: eyeY - eyeR,
                width: eyeR * 2, height: eyeR * 2
            )
        ).fill()
        NSBezierPath(
            ovalIn: NSRect(
                x: cx + 3 - eyeR, y: eyeY - eyeR,
                width: eyeR * 2, height: eyeR * 2
            )
        ).fill()

        // Smile
        let smile = NSBezierPath()
        let smileY = noteY + noteH * 0.58
        smile.move(to: NSPoint(x: cx - 2.5, y: smileY))
        smile.curve(
            to: NSPoint(x: cx + 2.5, y: smileY),
            controlPoint1: NSPoint(x: cx - 1, y: smileY + 2.5),
            controlPoint2: NSPoint(x: cx + 1, y: smileY + 2.5))
        smile.lineWidth = 1.2
        smile.lineCapStyle = .round
        smile.stroke()

        ctx.restoreGState()
    }

    private func launch() {
        let url = URL(fileURLWithPath: "/System/Applications/Stickies.app")
        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, _ in }
    }

    private func quit() {
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID
        }
        for app in apps {
            app.terminate()
        }
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == bundleID else { return }
        isRunning = true
        onStateChanged?()
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == bundleID else { return }
        isRunning = false
        onStateChanged?()
    }

    private static func checkIfRunning(bundleID: String) -> Bool {
        return NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID
        }
    }
}
