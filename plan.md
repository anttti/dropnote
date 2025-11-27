# Markdown Formatting Implementation Plan

## Overview
Replace SwiftUI's basic `TextEditor` with a custom `NSTextView` wrapper that supports live Markdown syntax highlighting while preserving the raw Markdown text.

## Tasks

### 1. Create `MarkdownTextView.swift` - NSViewRepresentable wrapper
- Create new file in `Views/` folder
- Implement `NSViewRepresentable` protocol wrapping `NSTextView`
- Set up two-way binding for text content with the ViewModel
- Configure NSTextView with monospaced font, proper padding, and scroll behavior
- Implement `Coordinator` as `NSTextViewDelegate` to handle text changes

### 2. Create `MarkdownHighlighter.swift` - Syntax highlighting logic
- Create new file in `Services/` folder
- Define regex patterns for:
  - Headings: `^#{1,6}\s+.+$` (lines starting with 1-6 `#`)
  - Bold: `\*[^*]+\*` or `\*\*[^*]+\*\*`
  - Italic: `_[^_]+_`
- Create function `applyHighlighting(to textStorage: NSTextStorage)` that:
  - Resets all attributes to default
  - Scans text with regex patterns
  - Applies appropriate `NSFont` traits (bold, italic) to matched ranges

### 3. Implement list auto-continuation
- In the `Coordinator`, override/handle the Enter key press
- Detect if current line starts with `- ` or `* `
- If so, insert `\n- ` or `\n* ` instead of just `\n`
- Handle edge case: if line is just `- ` or `* ` with no content, remove the prefix and don't continue

### 4. Update `ContentView.swift`
- Replace `TextEditor` with the new `MarkdownTextView`
- Pass the same binding: `viewModel.currentContent`
- Maintain focus behavior and styling

### 5. Testing
- Verify headings (`# `, `## `, etc.) display bold
- Verify `*text*` displays bold
- Verify `_text_` displays italic
- Verify list continuation works for both `-` and `*`
- Verify empty list item removal works
- Verify text content is saved correctly (raw Markdown preserved)

## File Changes Summary
| File | Action |
|------|--------|
| `Views/MarkdownTextView.swift` | Create |
| `Services/MarkdownHighlighter.swift` | Create |
| `ContentView.swift` | Modify |

## Technical Notes
- SwiftUI's `TextEditor` doesn't support `NSAttributedString`, hence the need for `NSTextView`
- Highlighting must be re-applied on every text change (performance consideration for large texts)
- Use `textStorage.beginEditing()` / `endEditing()` for batch attribute changes
- The raw Markdown syntax stays visible - we're just styling it, not hiding it

