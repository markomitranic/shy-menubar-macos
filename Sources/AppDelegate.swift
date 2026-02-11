import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let menuBarManager = MenuBarManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 30)

        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }

        updateIcon()

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(menuBarSettingChanged),
            name: NSNotification.Name("com.apple.dock.prefchanged"),
            object: nil
        )
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            menuBarManager.toggle()
            updateIcon()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "Quit Shy", action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)

        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        let w: CGFloat = 28
        let h: CGFloat = 22
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

            // Hands gripping the wall — spread wide, outside head area
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

            if !self.menuBarManager.isMenuBarHidden {
                // Peeking: upside-down head hanging below the wall
                let headR: CGFloat = 7.5
                let cy: CGFloat = wallY - headR + 2.5

                if let ctx = NSGraphicsContext.current?.cgContext {
                    ctx.saveGState()
                    ctx.clip(to: CGRect(x: 0, y: 0, width: w, height: wallY))

                    // Corgi ears (wide, rounded triangles pointing down since upside-down)
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

                    // Smile (upside-down, curves toward wall)
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
            }

            return true
        }

        image.isTemplate = true
        button.image = image
    }

    @objc private func menuBarSettingChanged() {
        menuBarManager.syncFromSystem()
        DispatchQueue.main.async { [weak self] in
            self?.updateIcon()
        }
    }
}
