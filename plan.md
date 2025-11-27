# Settings Dialog Implementation Plan

## Overview
Add a settings dialog to configure global hotkey (enable/disable + custom key combination). Accessible via Cmd-, or cogwheel button in toolbar.

---

## Tasks

### 1. Create Settings Model
**File:** `Dropnote/Models/Settings.swift`

- Create `Settings` struct with:
  - `hotkeyEnabled: Bool` (default: true)
  - `hotkeyKeyCode: UInt32` (default: 2 for 'd')
  - `hotkeyModifiers: UInt32` (default: cmdKey | shiftKey)
- Make it `Codable` for persistence
- Add computed property for human-readable hotkey string (e.g., "⌘⇧D")

### 2. Add Settings Persistence to StorageManager
**File:** `Dropnote/Services/StorageManager.swift`

- Add `settingsURL` property pointing to `settings.json`
- Add `loadSettings() -> Settings` method
- Add `saveSettings(_ settings: Settings)` method

### 3. Create SettingsManager
**File:** `Dropnote/Services/SettingsManager.swift`

- Singleton `SettingsManager` class
- `@Published var settings: Settings` for reactive updates
- Methods to update individual settings
- Notify AppDelegate when hotkey settings change (via callback or NotificationCenter)

### 4. Create HotkeyRecorder View Component
**File:** `Dropnote/Views/HotkeyRecorderView.swift`

- Custom NSViewRepresentable that captures key presses
- Display current hotkey combination
- On focus, listen for new key combination
- Validate that modifiers include at least Cmd or Ctrl
- Return captured keyCode and modifiers

### 5. Create SettingsView
**File:** `Dropnote/Views/SettingsView.swift`

- SwiftUI view with settings form:
  - Section: "Global Hotkey"
    - Toggle for enable/disable hotkey
    - HotkeyRecorder for setting the key combination
    - Label showing current hotkey (e.g., "⌘⇧D")
- Bind to SettingsManager
- Standard macOS settings window styling

### 6. Add Cogwheel Button to ContentView
**File:** `Dropnote/ContentView.swift`

- Add settings button with `gear` SF Symbol to the right side of toolbar (before the Spacer or after trash)
- Button triggers `onSettingsPressed` callback (passed from parent)

### 7. Create SettingsWindowController
**File:** `Dropnote/SettingsWindowController.swift`

- NSWindowController subclass to manage settings window
- Create NSWindow with SettingsView as content
- Handle window lifecycle (show, close, bring to front if already open)
- Make it a proper macOS preferences window (no resize, centered)

### 8. Update AppDelegate for Settings Integration
**File:** `Dropnote/DropnoteApp.swift`

- Add `settingsManager` property
- Add `settingsWindowController` property
- Add `openSettings()` method
- Pass settings callback to ContentView
- Refactor `setupGlobalHotkey()` to use settings values
- Add method to re-register hotkey when settings change
- Subscribe to SettingsManager changes

### 9. Add Cmd-, Keyboard Shortcut
**File:** `Dropnote/DropnoteApp.swift` or `ContentView.swift`

- Add `.keyboardShortcut(",", modifiers: .command)` to settings button
- Ensure it works from anywhere in the app

### 10. Handle Hotkey Registration/Unregistration
**File:** `Dropnote/DropnoteApp.swift`

- Create `unregisterGlobalHotkey()` method
- Create `registerGlobalHotkey(keyCode:modifiers:)` method
- Call unregister before register when changing hotkey
- Handle enable/disable by register/unregister

---

## File Structure After Implementation

```
Dropnote/
├── Models/
│   ├── AppState.swift
│   ├── Note.swift
│   └── Settings.swift          [NEW]
├── Services/
│   ├── StorageManager.swift    [MODIFIED]
│   └── SettingsManager.swift   [NEW]
├── Views/
│   ├── HotkeyRecorderView.swift [NEW]
│   └── SettingsView.swift       [NEW]
├── ViewModels/
│   └── NoteViewModel.swift
├── ContentView.swift            [MODIFIED]
├── DropnoteApp.swift            [MODIFIED]
└── SettingsWindowController.swift [NEW]
```

---

## Implementation Order

1. Settings model (foundation)
2. StorageManager updates (persistence)
3. SettingsManager (state management)
4. HotkeyRecorderView (complex UI component)
5. SettingsView (main settings UI)
6. SettingsWindowController (window management)
7. AppDelegate updates (integration)
8. ContentView cogwheel button (final UI touch)

---

## Notes

- Use Carbon APIs for hotkey recording (same as current implementation)
- Settings window should be a separate NSWindow, not in the popover
- Hotkey changes should take effect immediately without app restart
- Consider using `NSEvent.addLocalMonitorForEvents` for key capture in settings

