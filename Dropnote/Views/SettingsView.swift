//
//  SettingsView.swift
//  Dropnote
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var keyCode: UInt32
    @State private var modifiers: UInt32
    
    init() {
        let settings = SettingsManager.shared.settings
        _keyCode = State(initialValue: settings.hotkeyKeyCode)
        _modifiers = State(initialValue: settings.hotkeyModifiers)
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable global hotkey", isOn: $settingsManager.settings.hotkeyEnabled)
                
                HStack {
                    Text("Shortcut:")
                    Spacer()
                    HotkeyRecorderView(keyCode: $keyCode, modifiers: $modifiers)
                        .frame(width: 120)
                        .onChange(of: keyCode) { _, newValue in
                            settingsManager.updateHotkey(keyCode: newValue, modifiers: modifiers)
                        }
                        .onChange(of: modifiers) { _, newValue in
                            settingsManager.updateHotkey(keyCode: keyCode, modifiers: newValue)
                        }
                }
                .disabled(!settingsManager.settings.hotkeyEnabled)
                .opacity(settingsManager.settings.hotkeyEnabled ? 1 : 0.5)
            } header: {
                Text("Global Hotkey")
            } footer: {
                Text("Use the global hotkey to show/hide Dropnote from anywhere.")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 180)
    }
}

#Preview {
    SettingsView()
}

