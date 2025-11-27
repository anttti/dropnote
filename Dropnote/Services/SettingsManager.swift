//
//  SettingsManager.swift
//  Dropnote
//

import Foundation
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: AppSettings {
        didSet {
            storage.saveSettings(settings)
            onSettingsChanged?(settings)
        }
    }
    
    var onSettingsChanged: ((AppSettings) -> Void)?
    
    private let storage = StorageManager.shared
    
    private init() {
        settings = storage.loadSettings()
    }
    
    func updateHotkeyEnabled(_ enabled: Bool) {
        settings.hotkeyEnabled = enabled
    }
    
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        settings.hotkeyKeyCode = keyCode
        settings.hotkeyModifiers = modifiers
    }
}

