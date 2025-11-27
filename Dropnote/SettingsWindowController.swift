//
//  SettingsWindowController.swift
//  Dropnote
//

import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?
    
    func showSettings() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Dropnote Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        
        // Position in center of visible screen area (below menubar)
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let windowSize = window.frame.size
            let x = visibleFrame.midX - windowSize.width / 2
            let y = visibleFrame.midY - windowSize.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeSettings() {
        window?.close()
    }
}

