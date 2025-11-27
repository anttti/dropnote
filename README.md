# Dropnote

A minimal macOS menubar app for quick notes.

## Features

- **Menubar-only** — Lives in your menubar, no Dock icon clutter
- **Multi-note support** — Create, navigate, and delete notes
- **Plain text** — No formatting, just text
- **Persistent storage** — Notes saved to `~/.config/dropnote/data/`
- **Global hotkey** — `Cmd+Shift+D` to toggle from anywhere
- **Keyboard shortcuts**:
  - `Cmd+N` — New note
  - `Cmd+Delete` — Delete note
  - `Cmd+Option+←/→` — Navigate between notes

## Architecture

```
Dropnote/
├── DropnoteApp.swift        # App entry point, menubar setup, global hotkey
├── ContentView.swift        # Main UI: toolbar + text editor
├── Models/
│   ├── Note.swift           # Note struct (id, content, timestamps)
│   └── AppState.swift       # Persisted state (note order, current index)
├── ViewModels/
│   └── NoteViewModel.swift  # Note CRUD, navigation, auto-save logic
├── Services/
│   └── StorageManager.swift # File I/O for ~/.config/dropnote/data/
└── Info.plist               # LSUIElement=true (menubar-only)
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

