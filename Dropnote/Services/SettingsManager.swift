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
            settings.save()
            onSettingsChanged?(settings)
        }
    }
    
    var onSettingsChanged: ((AppSettings) -> Void)?
    var onDataDirectoryChanged: (() -> Void)?
    
    private init() {
        settings = AppSettings.load()
    }
    
    func updateHotkeyEnabled(_ enabled: Bool) {
        settings.hotkeyEnabled = enabled
    }
    
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        settings.hotkeyKeyCode = keyCode
        settings.hotkeyModifiers = modifiers
    }
    
    func updateDataDirectory(_ path: String?, migrate: Bool = true) throws {
        let oldURL = StorageManager.shared.dataDirectory
        let newURL = path.map { URL(fileURLWithPath: $0) } ?? StorageManager.defaultDataDirectory
        
        if migrate && oldURL != newURL {
            try StorageManager.shared.migrateData(from: oldURL, to: newURL)
        }
        
        settings.dataDirectory = path
        StorageManager.shared.reloadDataDirectory()
        onDataDirectoryChanged?()
    }
}

