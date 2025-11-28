//
//  SettingsView.swift
//  Dropnote
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var keyCode: UInt32
    @State private var modifiers: UInt32
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init() {
        let settings = SettingsManager.shared.settings
        _keyCode = State(initialValue: settings.hotkeyKeyCode)
        _modifiers = State(initialValue: settings.hotkeyModifiers)
    }
    
    private var displayPath: String {
        if let path = settingsManager.settings.dataDirectory {
            return (path as NSString).abbreviatingWithTildeInPath
        }
        return (StorageManager.defaultDataDirectory.path as NSString).abbreviatingWithTildeInPath
    }
    
    private var isUsingCustomDirectory: Bool {
        settingsManager.settings.dataDirectory != nil
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Startup", isOn: Binding(
                    get: { LaunchAtStartupManager.isEnabled },
                    set: { LaunchAtStartupManager.setEnabled($0) }
                ))
            } header: {
                Text("General")
            }
            
            Section {
                HStack {
                    Text(displayPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Change...") {
                        chooseDirectory()
                    }
                }
                
                HStack {
                    Button("Reset to Default") {
                        resetToDefault()
                    }
                    .disabled(!isUsingCustomDirectory)
                    
                    Spacer()
                    
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: StorageManager.shared.dataDirectory.path)
                    }
                }
            } header: {
                Text("Storage")
            } footer: {
                Text("Notes are stored in this directory as plain text files.")
                    .foregroundColor(.secondary)
            }
            
            Section {
                Toggle("Enable global hotkey", isOn: $settingsManager.settings.hotkeyEnabled)
                
                HStack {
                    Text("Global hotkey")
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
            
            Section {
                Button("Quit Dropnote") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 515)
        .scrollDisabled(true)
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Choose a directory to store your notes"
        
        if panel.runModal() == .OK, let url = panel.url {
            // Verify writable
            if !FileManager.default.isWritableFile(atPath: url.path) {
                errorMessage = "The selected directory is not writable."
                showingError = true
                return
            }
            
            do {
                try settingsManager.updateDataDirectory(url.path)
            } catch {
                errorMessage = "Failed to migrate data: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func resetToDefault() {
        do {
            try settingsManager.updateDataDirectory(nil)
        } catch {
            errorMessage = "Failed to migrate data: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    SettingsView()
}

