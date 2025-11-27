//
//  MarkdownHighlighter.swift
//  Dropnote
//

import AppKit

struct MarkdownHighlighter {
    
    private static let headingPattern = try! NSRegularExpression(pattern: "^#{1,6}\\s+.+$", options: .anchorsMatchLines)
    private static let boldPattern = try! NSRegularExpression(pattern: "\\*[^*\n]+\\*", options: [])
    private static let italicPattern = try! NSRegularExpression(pattern: "_[^_\n]+_", options: [])
    
    static func applyHighlighting(to textStorage: NSTextStorage, baseFont: NSFont) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let text = textStorage.string
        
        textStorage.beginEditing()
        
        // Reset to base font
        textStorage.addAttribute(.font, value: baseFont, range: fullRange)
        
        // Apply heading styles (bold)
        let boldFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
        headingPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            textStorage.addAttribute(.font, value: boldFont, range: range)
        }
        
        // Apply bold styles
        boldPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            textStorage.addAttribute(.font, value: boldFont, range: range)
        }
        
        // Apply italic styles
        let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
        italicPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            textStorage.addAttribute(.font, value: italicFont, range: range)
        }
        
        textStorage.endEditing()
    }
}

