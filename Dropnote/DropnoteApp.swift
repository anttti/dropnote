//
//  DropnoteApp.swift
//  Dropnote
//

import SwiftUI
import Carbon

@main
struct DropnoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private enum PanelAnimation {
    static let duration: CFTimeInterval = 0.05
    static let slideOffset: CGFloat = 20
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: KeyablePanel!
    private var noteViewModel = NoteViewModel()
    private var eventMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    private let settingsManager = SettingsManager.shared
    private let settingsWindowController = SettingsWindowController()
    
    private var statusItemCenterX: CGFloat = 0
    
    private let panelWidthKey = "panelWidth"
    private let panelHeightKey = "panelHeight"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        setupGlobalHotkey()
        setupEventMonitor()
        setupSettingsObserver()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Dropnote")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPanel() {
        let savedWidth = UserDefaults.standard.double(forKey: panelWidthKey)
        let savedHeight = UserDefaults.standard.double(forKey: panelHeightKey)
        let width = savedWidth > 0 ? savedWidth : 400
        let height = savedHeight > 0 ? savedHeight : 400
        
        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = false
        panel.minSize = NSSize(width: 350, height: 200)
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        
        let hostingView = NSHostingController(
            rootView: ContentView(viewModel: noteViewModel, settingsManager: settingsManager, onSettingsPressed: { [weak self] in
                self?.openSettings()
            }, onDismiss: { [weak self] in
                self?.dismissPanel()
            })
        )
        panel.contentViewController = hostingView
        panel.setContentSize(NSSize(width: width, height: height))
        
        hostingView.view.wantsLayer = true
        hostingView.view.layer?.cornerRadius = 12
        hostingView.view.layer?.masksToBounds = true
        hostingView.view.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillResize(_:)),
            name: NSWindow.willStartLiveResizeNotification,
            object: panel
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize(_:)),
            name: NSWindow.didResizeNotification,
            object: panel
        )
    }
    
    @objc private func windowWillResize(_ notification: Notification) {
        updateStatusItemCenterX()
    }
    
    @objc private func windowDidResize(_ notification: Notification) {
        guard panel.isVisible else { return }
        centerPanelHorizontally()
        savePanelSize()
    }
    
    private func savePanelSize() {
        UserDefaults.standard.set(panel.frame.width, forKey: panelWidthKey)
        UserDefaults.standard.set(panel.frame.height, forKey: panelHeightKey)
    }
    
    private func updateStatusItemCenterX() {
        guard let button = statusItem.button,
              let window = button.window else { return }
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = window.convertToScreen(buttonFrame)
        statusItemCenterX = screenFrame.midX
    }
    
    private func centerPanelHorizontally() {
        var frame = panel.frame
        frame.origin.x = statusItemCenterX - frame.width / 2
        panel.setFrameOrigin(frame.origin)
    }
    
    private func dismissPanel() {
        guard panel.isVisible, let layer = panel.contentView?.layer else { return }
        
        let slideAnim = CABasicAnimation(keyPath: "transform.translation.y")
        slideAnim.fromValue = 0
        slideAnim.toValue = PanelAnimation.slideOffset
        slideAnim.duration = PanelAnimation.duration
        slideAnim.timingFunction = CAMediaTimingFunction(name: .easeIn)
        slideAnim.isRemovedOnCompletion = false
        slideAnim.fillMode = .forwards
        layer.add(slideAnim, forKey: "slideUp")
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = PanelAnimation.duration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
            self?.panel.alphaValue = 1
            layer.removeAllAnimations()
        })
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return }
            // Don't close if pinned
            if self.settingsManager.settings.isPinned { return }
            // Don't close if clicking on the status item button
            if let button = self.statusItem.button,
               let buttonWindow = button.window {
                let buttonFrame = button.convert(button.bounds, to: nil)
                let screenFrame = buttonWindow.convertToScreen(buttonFrame)
                if screenFrame.contains(NSEvent.mouseLocation) { return }
            }
            self.dismissPanel()
        }
    }
    
    private func setupSettingsObserver() {
        settingsManager.onSettingsChanged = { [weak self] settings in
            self?.handleSettingsChanged(settings)
        }
    }
    
    private func handleSettingsChanged(_ settings: AppSettings) {
        unregisterGlobalHotkey()
        if settings.hotkeyEnabled {
            registerGlobalHotkey(keyCode: settings.hotkeyKeyCode, modifiers: settings.hotkeyModifiers)
        }
    }
    
    private func setupGlobalHotkey() {
        let settings = settingsManager.settings
        guard settings.hotkeyEnabled else { return }
        registerGlobalHotkey(keyCode: settings.hotkeyKeyCode, modifiers: settings.hotkeyModifiers)
    }
    
    private func registerGlobalHotkey(keyCode: UInt32, modifiers: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x444E4F54) // "DNOT"
        hotKeyID.id = 1
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                appDelegate.togglePopover()
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandlerRef)
    }
    
    private func unregisterGlobalHotkey() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }
        
        if panel.isVisible {
            // Reset pin state when manually dismissing via menu bar
            if settingsManager.settings.isPinned {
                settingsManager.updateIsPinned(false)
            }
            dismissPanel()
        } else {
            updateStatusItemCenterX()
            
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(buttonFrame)
            
            let panelWidth = panel.frame.width
            let panelHeight = panel.frame.height
            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.minY - panelHeight - 4
            
            panel.setFrameOrigin(NSPoint(x: x, y: y))
            showPanel()
        }
    }
    
    private func showPanel() {
        guard let layer = panel.contentView?.layer else {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        panel.alphaValue = 0
        layer.transform = CATransform3DMakeTranslation(0, PanelAnimation.slideOffset, 0)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        let slideAnim = CABasicAnimation(keyPath: "transform.translation.y")
        slideAnim.fromValue = PanelAnimation.slideOffset
        slideAnim.toValue = 0
        slideAnim.duration = PanelAnimation.duration
        slideAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(slideAnim, forKey: "slideDown")
        layer.transform = CATransform3DIdentity
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = PanelAnimation.duration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        })
    }
    
    func openSettings() {
        dismissPanel()
        settingsWindowController.showSettings()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        unregisterGlobalHotkey()
    }
}
