//
//  LaunchAtStartupManager.swift
//  Dropnote
//

import Foundation
import ServiceManagement

enum LaunchAtStartupManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at startup: \(error)")
        }
    }
}

