# Auto-Updater Design

## Overview

Add a fully automatic update mechanism that checks GitHub Releases on launch, downloads newer versions in the background, and prompts the user to relaunch. Also expose a manual "Check for Updates" button in Settings.

**Repo:** `jpwahle/ai-apple-mail`
**Release artifact:** `AIMailComposer.dmg` attached to GitHub Releases with tags `vX.Y.Z`

## Architecture

### New File: `AIMailComposer/Services/Update/UpdateChecker.swift`

A `@MainActor` `ObservableObject` that manages the full update lifecycle.

**State:**

```swift
enum UpdateState {
    case idle
    case checking
    case downloading(progress: Double)
    case readyToInstall
    case installing
    case failed(String)
}

@Published var state: UpdateState = .idle
@Published var latestVersion: String?  // e.g. "0.2.0"
@Published var releaseNotes: String?
```

**Public API:**

```swift
func checkForUpdates()           // Full flow: check -> download -> prompt
func install()                   // Mount DMG, replace app, relaunch
var currentVersion: String       // From Bundle.main CFBundleShortVersionString
var updateAvailable: Bool        // Computed from state
```

### Check Phase

1. GET `https://api.github.com/repos/jpwahle/ai-apple-mail/releases/latest`
2. Parse JSON for `tag_name` (strip leading `v`), `body` (release notes), and the first `.dmg` asset's `browser_download_url`
3. Compare remote version to `currentVersion` using numeric semantic version comparison (split on `.`, compare major, then minor, then patch)
4. If remote is newer, proceed to download. Otherwise set state back to `.idle`.

### Download Phase

1. Use `URLSession.shared.download(from: dmgURL)` with async/await
2. Track progress via `URLSessionDownloadDelegate` or `AsyncBytes` with `expectedContentLength`
3. Move downloaded file to `FileManager.default.temporaryDirectory / "AIMailComposer-update.dmg"`
4. Set state to `.readyToInstall`

### Install Phase

Triggered by user confirming the relaunch prompt.

1. **Mount DMG:** Run `hdiutil attach -nobrowse -readonly -mountpoint /tmp/aimail-update <dmg_path>` via `Process`
2. **Locate .app:** Find the `.app` bundle inside the mount point
3. **Replace:** `rsync -a --delete <mounted.app>/ <Bundle.main.bundlePath>/` — this overwrites the running app's bundle on disk. The running process keeps its already-loaded binary in memory, so this is safe.
4. **Unmount:** `hdiutil detach /tmp/aimail-update`
5. **Relaunch:** Launch the new binary via `Process` (`open <bundlePath>`), then `exit(0)` the current process

**Why rsync instead of rm + cp:** rsync atomically replaces contents without removing the bundle directory itself, which avoids issues with the running app's bundle path disappearing.

### Error Handling

- Network unreachable / API rate limited: silently set state to `.idle` on auto-check (don't bother the user). Show error message only on manual check.
- DMG download fails: set `.failed(message)`, allow retry
- hdiutil / rsync fails: set `.failed(message)`, clean up temp files
- No DMG asset in release: treat as no update available

## Integration Points

### AppDelegate

In `applicationDidFinishLaunching`, after existing setup:

```swift
let updateChecker = UpdateChecker()
// store as property for SettingsView access
self.updateChecker = updateChecker
Task { updateChecker.checkForUpdates() }
```

Pass `updateChecker` into the environment alongside `settingsStore`.

### GeneralSettingsView

Add an "Updates" section at the bottom of the General tab:

- Current version label: "Version 0.1.0"
- "Check for Updates" button
- State-dependent display:
  - `.checking` → spinner + "Checking..."
  - `.downloading(progress)` → progress bar + "Downloading v0.2.0..."
  - `.readyToInstall` → "v0.2.0 ready — Relaunch to update" button
  - `.failed(msg)` → error text + "Retry" button
  - `.idle` with no update → "You're up to date."

### Update Alert

When auto-check completes and the DMG is downloaded (state becomes `.readyToInstall`), show an `NSAlert`:
- Title: "Update Available"
- Message: "AI Mail Composer v{version} is ready. Relaunch to update?"
- Buttons: "Relaunch Now", "Later"

"Later" dismisses — the update stays downloaded and the user can relaunch from Settings.

## Version Comparison

Simple numeric comparison function:

```swift
func isNewerVersion(_ remote: String, than local: String) -> Bool
```

Split both on `.`, pad to equal length with 0s, compare each component as `Int`. `"0.2.0" > "0.1.0"` → true.

## Files Changed

| File | Change |
|---|---|
| `AIMailComposer/Services/Update/UpdateChecker.swift` | **New** — update service |
| `AIMailComposer/App/AppDelegate.swift` | Add `updateChecker` property, trigger check on launch, pass to environment |
| `AIMailComposer/Views/Settings/GeneralSettingsView.swift` | Add "Updates" section with version label, check button, state display |

## Out of Scope

- Delta/incremental updates
- Cryptographic signature verification of downloads
- Auto-check interval / background polling (only checks once on launch)
- Rollback mechanism
- Update channel selection (stable/beta)
