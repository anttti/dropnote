//
//  HotkeyRecorderView.swift
//  Dropnote
//

import SwiftUI
import Carbon

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    
    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.keyCode = keyCode
        view.modifiers = modifiers
        view.onHotkeyChanged = { newKeyCode, newModifiers in
            keyCode = newKeyCode
            modifiers = newModifiers
        }
        return view
    }
    
    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        nsView.keyCode = keyCode
        nsView.modifiers = modifiers
        nsView.updateDisplay()
    }
}

final class HotkeyRecorderNSView: NSView {
    var keyCode: UInt32 = 0
    var modifiers: UInt32 = 0
    var onHotkeyChanged: ((UInt32, UInt32) -> Void)?
    
    private var isRecording = false
    private var monitor: Any?
    private let textField = NSTextField()
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        textField.isEditable = false
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.alignment = .center
        textField.font = .systemFont(ofSize: 13)
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        updateDisplay()
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        textField.addGestureRecognizer(clickGesture)
    }
    
    @objc private func handleClick() {
        startRecording()
    }
    
    private func startRecording() {
        isRecording = true
        textField.stringValue = "Press shortcut..."
        textField.textColor = .systemBlue
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        updateDisplay()
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        // Escape cancels recording
        if event.keyCode == 53 {
            stopRecording()
            return
        }
        
        // Only process keyDown with valid key (not just modifier keys)
        guard event.type == .keyDown else { return }
        
        let carbonModifiers = carbonModifiersFromNSEvent(event)
        
        // Require at least Cmd or Ctrl
        guard carbonModifiers & UInt32(cmdKey) != 0 || carbonModifiers & UInt32(controlKey) != 0 else {
            return
        }
        
        keyCode = UInt32(event.keyCode)
        modifiers = carbonModifiers
        onHotkeyChanged?(keyCode, modifiers)
        stopRecording()
    }
    
    private func carbonModifiersFromNSEvent(_ event: NSEvent) -> UInt32 {
        var carbonMods: UInt32 = 0
        let flags = event.modifierFlags
        
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
        if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
        
        return carbonMods
    }
    
    func updateDisplay() {
        guard !isRecording else { return }
        textField.stringValue = AppSettings(hotkeyKeyCode: keyCode, hotkeyModifiers: modifiers).hotkeyDisplayString
        textField.textColor = .labelColor
    }
    
    override var intrinsicContentSize: NSSize {
        NSSize(width: 120, height: 22)
    }
}

