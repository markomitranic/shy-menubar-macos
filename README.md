# Shy

A minimal macOS menu bar utility that toggles the system's "auto-hide menu bar" setting. Left-click the shy piggy to toggle, right-click to quit. No dock icon, no windows, no settings.

macOS Tahoe (26.x) only.

![demo](demo.gif)

## Install

1. Download `Shy.zip` from the [latest release](../../releases/latest)
2. Unzip it and drag `Shy.app` to your `/Applications/` folder
3. Right-click (or Control-click) `Shy.app` and select **Open**
4. In the dialog that appears, click **Open**

Step 3–4 is needed only once because the app is not signed with an Apple Developer certificate. macOS will block it on first launch, but once you confirm, it remembers your choice.

If you prefer the terminal, you can skip the right-click dance with:

```
xattr -cr /Applications/Shy.app
open /Applications/Shy.app
```

---

## Build from source

```
make        # Build the app bundle (build/Shy.app)
make run    # Build and open the app
make install # Copy Shy.app to /Applications/
```

## Packaging a release

```
make package
```

This produces `build/Shy.zip`. To publish it as a GitHub Release:

```bash
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 build/Shy.zip --title "Shy v1.0.0" --notes "Release notes here"
```
