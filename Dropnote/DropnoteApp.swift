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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var noteViewModel = NoteViewModel()
    private var eventMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    private let settingsManager = SettingsManager.shared
    private let settingsWindowController = SettingsWindowController()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
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
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView(viewModel: noteViewModel, onSettingsPressed: { [weak self] in
                self?.openSettings()
            })
        )
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
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
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func openSettings() {
        popover.performClose(nil)
        settingsWindowController.showSettings()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        unregisterGlobalHotkey()
    }
}
