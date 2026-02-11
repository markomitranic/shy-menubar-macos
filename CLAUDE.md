# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make        # Build the app bundle (build/Shy.app)
make run    # Build and open the app
make clean  # Remove build directory
make install # Copy Shy.app to /Applications/
```

No Xcode project or Swift Package Manager — the app compiles directly with `swiftc` via the Makefile. Target is `arm64-apple-macosx26.0` (macOS Tahoe only). There are no tests or linter configured.

Always kill, rebuild and reopen the app after making changes to the code.

## Architecture

Shy is a minimal macOS menu bar app that toggles the system "auto-hide menu bar" setting. It runs as an LSUIElement (no Dock icon, no windows).

**Entry point** (`Sources/main.swift`): Creates `NSApplication` with `.accessory` activation policy and starts the run loop.

**AppDelegate** (`Sources/AppDelegate.swift`): Owns the `NSStatusItem` (menu bar icon). Left-click toggles menu bar visibility, right-click shows a Quit context menu. The icon is drawn programmatically with `NSBezierPath` — a character peeking over a wall when the menu bar is visible, just hands gripping the wall when hidden. Listens for `com.apple.dock.prefchanged` distributed notifications to sync state when the user changes the setting externally.

**MenuBarManager** (`Sources/MenuBarManager.swift`): Reads and writes the auto-hide state via `NSAppleScript` calling `System Events > dock preferences > autohide menu bar`. All AppleScript execution runs on a background queue.

## macOS Tahoe Menu Bar Hiding — Critical

Do **not** use `_HIHideMenuBar` via `UserDefaults` or `defaults write`. On macOS Tahoe (26.x), this key propagates to multiple preference layers (NSGlobalDomain, ByHost, app bundle domain) and gets permanently stuck — surviving reboots and not clearable from System Settings.

The current approach (AppleScript via System Events) is correct. If you ever need a `defaults`-based approach, use `com.apple.controlcenter AutoHideMenuBarOption` (0=Never, 2=On Desktop, 3=Always) and restart the Dock (`killall Dock`), not SystemUIServer.
