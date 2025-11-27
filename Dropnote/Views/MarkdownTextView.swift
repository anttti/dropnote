//
//  MarkdownTextView.swift
//  Dropnote
//

import SwiftUI
import AppKit

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    var focusOnAppear: Bool = true
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = MarkdownNSTextView()
        
        textView.delegate = context.coordinator
        textView.font = font
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isRichText = true // Required for link attributes
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false // We handle links manually
        textView.isEditable = true
        textView.isSelectable = true
        
        // Layout config
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        // Padding
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        
        context.coordinator.textView = textView
        
        if focusOnAppear {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if text differs (avoid cursor jump)
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            applyHighlighting(to: textView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func applyHighlighting(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        MarkdownHighlighter.applyHighlighting(to: textStorage, baseFont: font)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextView
        weak var textView: NSTextView?
        
        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            
            // Re-apply highlighting
            if let textStorage = textView.textStorage {
                MarkdownHighlighter.applyHighlighting(to: textStorage, baseFont: parent.font)
            }
        }
        
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let url = link as? URL {
                NSWorkspace.shared.open(url)
                return true
            }
            return false
        }
    }
}

// Custom NSTextView subclass to handle Enter key for list continuation
final class MarkdownNSTextView: NSTextView {
    
    private static let listPattern = try! NSRegularExpression(pattern: "^(\\s*[-*]\\s+)", options: [])
    
    override func insertNewline(_ sender: Any?) {
        guard let textStorage = self.textStorage else {
            super.insertNewline(sender)
            return
        }
        
        let text = textStorage.string
        let cursorLocation = selectedRange().location
        
        // Find current line
        let lineRange = (text as NSString).lineRange(for: NSRange(location: cursorLocation, length: 0))
        let currentLine = (text as NSString).substring(with: lineRange)
        
        // Check if line matches list pattern
        if let match = Self.listPattern.firstMatch(in: currentLine, range: NSRange(location: 0, length: currentLine.count)) {
            let prefix = (currentLine as NSString).substring(with: match.range(at: 1))
            let contentAfterPrefix = currentLine.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if contentAfterPrefix.isEmpty {
                // Empty list item - remove the prefix and don't continue
                let prefixRange = NSRange(location: lineRange.location, length: prefix.count)
                if shouldChangeText(in: prefixRange, replacementString: "") {
                    replaceCharacters(in: prefixRange, with: "")
                    didChangeText()
                }
            } else {
                // Continue the list
                super.insertNewline(sender)
                insertText(prefix, replacementRange: selectedRange())
            }
        } else {
            super.insertNewline(sender)
        }
    }
}

