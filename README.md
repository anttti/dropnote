# Dropnote

A minimal macOS menubar app for quick notes.

## Features

- **Menubar-only** — Lives in your menubar, no Dock icon clutter
- **Multi-note support** — Create, navigate, and delete notes
- **Markdown formatting** — Live syntax highlighting for headings, bold, italic, and clickable links
- **Smart lists** — Auto-continues `- ` and `* ` list prefixes on Enter
- **Persistent storage** — Notes saved to `~/.config/dropnote/data/`
- **Configurable global hotkey** — Toggle from anywhere (default: `Cmd+Shift+D`)
- **Settings window** — Customize hotkey via right-click menu
- **Keyboard shortcuts**:
  - `Cmd+N` — New note
  - `Cmd+Delete` — Delete note
  - `Cmd+Option+←/→` — Navigate between notes

## Architecture

```
Dropnote/
├── DropnoteApp.swift              # App entry, menubar setup, global hotkey
├── ContentView.swift              # Main UI: toolbar + Markdown editor
├── SettingsWindowController.swift # Settings window management
├── Models/
│   ├── Note.swift                 # Note struct (id, content, timestamps)
│   └── AppState.swift             # Persisted state (note order, current index)
├── ViewModels/
│   └── NoteViewModel.swift        # Note CRUD, navigation, auto-save logic
├── Views/
│   ├── SettingsView.swift         # Settings UI (hotkey config)
│   ├── HotkeyRecorderView.swift   # Custom hotkey capture field
│   └── MarkdownTextView.swift     # NSTextView wrapper with list auto-continuation
├── Services/
│   ├── StorageManager.swift       # File I/O for notes
│   ├── SettingsManager.swift      # User preferences persistence
│   └── MarkdownHighlighter.swift  # Regex-based syntax highlighting
└── Info.plist                     # LSUIElement=true (menubar-only)
```

**Data flow:** `ContentView` ↔ `NoteViewModel` ↔ `StorageManager` ↔ filesystem

**Storage format:**
- `~/.config/dropnote/data/state.json` — Note IDs and current index
- `~/.config/dropnote/data/notes/{uuid}.txt` — Individual note content

## Requirements

- macOS 14.0+
- Xcode 16+

## Build

Open `Dropnote.xcodeproj` in Xcode and run.

