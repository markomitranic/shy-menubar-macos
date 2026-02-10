import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let menuBarManager = MenuBarManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

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
        menu.addItem(NSMenuItem(title: "Quit Shy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)

        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        let symbolName = menuBarManager.isMenuBarHidden ? "eye.slash" : "eye"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Menu bar visibility")
        image?.isTemplate = true
        button.image = image
    }

    @objc private func menuBarSettingChanged() {
        menuBarManager.syncFromSystem()
        DispatchQueue.main.async { [weak self] in
            self?.updateIcon()
        }
    }
}
