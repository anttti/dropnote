//
//  MarkdownHighlighter.swift
//  Dropnote
//

import AppKit

struct MarkdownHighlighter {
    
    private static let headingPattern = try! NSRegularExpression(pattern: "^#{1,6}\\s+.+$", options: .anchorsMatchLines)
    private static let boldPattern = try! NSRegularExpression(pattern: "\\*[^*\n]+\\*", options: [])
    private static let italicPattern = try! NSRegularExpression(pattern: "_[^_\n]+_", options: [])
    private static let urlPattern = try! NSRegularExpression(pattern: "https?://[^\\s]+", options: [])
    
    static func applyHighlighting(to textStorage: NSTextStorage, baseFont: NSFont) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let text = textStorage.string
        
        textStorage.beginEditing()
        
        // Reset attributes
        textStorage.addAttribute(.font, value: baseFont, range: fullRange)
        textStorage.removeAttribute(.link, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        
        // Find URL ranges first (to exclude from italic detection)
        var urlRanges: [NSRange] = []
        urlPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            urlRanges.append(range)
        }
        
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
        
        // Apply italic styles (skip if inside URL)
        let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
        italicPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            let overlapsUrl = urlRanges.contains { NSIntersectionRange($0, range).length > 0 }
            if !overlapsUrl {
                textStorage.addAttribute(.font, value: italicFont, range: range)
            }
        }
        
        // Apply link styles
        for urlRange in urlRanges {
            let urlString = (text as NSString).substring(with: urlRange)
            if let url = URL(string: urlString) {
                textStorage.addAttribute(.link, value: url, range: urlRange)
                textStorage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: urlRange)
            }
        }
        
        textStorage.endEditing()
    }
}

