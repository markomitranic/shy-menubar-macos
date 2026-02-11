import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private let allModules: [ShyModule] = [MenuBarModule(), StickiesModule()]
    private var statusItems: [String: NSStatusItem] = [:]
    private let enabledModulesKey = "enabledModules"

    private var enabledModuleIDs: [String] {
        get {
            if let stored = UserDefaults.standard.stringArray(forKey: enabledModulesKey) {
                return stored
            }
            return allModules.map { $0.id }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledModulesKey)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        for module in allModules {
            module.onStateChanged = { [weak self] in
                DispatchQueue.main.async {
                    self?.updateIcon(for: module)
                }
            }
        }

        rebuildStatusItems()
    }

    // MARK: - Status Items

    private func rebuildStatusItems() {
        // Remove all existing items
        for (_, item) in statusItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItems.removeAll()

        // Create items for enabled modules
        let enabled = enabledModuleIDs
        for module in allModules where enabled.contains(module.id) {
            addStatusItem(for: module)
        }
    }

    private func addStatusItem(for module: ShyModule) {
        let item = NSStatusBar.system.statusItem(withLength: 30)
        if let button = item.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.identifier = NSUserInterfaceItemIdentifier(module.id)
        }
        statusItems[module.id] = item
        updateIcon(for: module)
    }

    private func removeStatusItem(for module: ShyModule) {
        if let item = statusItems.removeValue(forKey: module.id) {
            NSStatusBar.system.removeStatusItem(item)
        }
    }

    // MARK: - Click Handling

    @objc private func statusItemClicked(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent,
              let moduleID = sender?.identifier?.rawValue,
              let module = allModules.first(where: { $0.id == moduleID }) else { return }

        switch event.type {
        case .rightMouseUp:
            showContextMenu(for: moduleID)
        default:
            module.toggle()
            updateIcon(for: module)
        }
    }

    // MARK: - Icon

    private func updateIcon(for module: ShyModule) {
        guard let item = statusItems[module.id] else { return }
        item.button?.image = drawModuleIcon(for: module)
    }

    // MARK: - Context Menu

    private func showContextMenu(for moduleID: String) {
        guard let item = statusItems[moduleID] else { return }

        let menu = NSMenu()
        let enabled = enabledModuleIDs

        // Module toggles
        for module in allModules {
            let menuItem = NSMenuItem(
                title: module.name,
                action: #selector(toggleModule(_:)),
                keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = module.id
            menuItem.state = enabled.contains(module.id) ? .on : .off

            // Prevent disabling the last enabled module
            if enabled.contains(module.id) && enabled.count == 1 {
                menuItem.isEnabled = false
            }

            menu.addItem(menuItem)
        }

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(
            title: "Open at Login",
            action: #selector(toggleOpenAtLogin(_:)),
            keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit Shy",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))

        item.menu = menu
        item.button?.performClick(nil)

        DispatchQueue.main.async {
            item.menu = nil
        }
    }

    // MARK: - Menu Actions

    @objc private func toggleModule(_ sender: NSMenuItem) {
        guard let moduleID = sender.representedObject as? String else { return }

        var enabled = enabledModuleIDs
        if let index = enabled.firstIndex(of: moduleID) {
            // Don't disable the last module
            guard enabled.count > 1 else { return }
            enabled.remove(at: index)
            enabledModuleIDs = enabled

            if let module = allModules.first(where: { $0.id == moduleID }) {
                removeStatusItem(for: module)
            }
        } else {
            enabled.append(moduleID)
            enabledModuleIDs = enabled

            if let module = allModules.first(where: { $0.id == moduleID }) {
                addStatusItem(for: module)
            }
        }
    }

    @objc private func toggleOpenAtLogin(_ sender: NSMenuItem) {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            // silently ignore
        }
    }
}
