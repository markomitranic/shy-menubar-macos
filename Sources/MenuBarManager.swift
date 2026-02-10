import AppKit

class MenuBarManager {
    private(set) var isMenuBarHidden: Bool

    init() {
        isMenuBarHidden = Self.readSystemState()
    }

    func toggle() {
        let newValue = !isMenuBarHidden
        isMenuBarHidden = newValue

        DispatchQueue.global(qos: .userInitiated).async {
            let script = NSAppleScript(source: """
                tell application "System Events" to tell dock preferences to set autohide menu bar to \(newValue)
            """)
            script?.executeAndReturnError(nil)
        }
    }

    func syncFromSystem() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let current = Self.readSystemState()
            DispatchQueue.main.async {
                self?.isMenuBarHidden = current
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
