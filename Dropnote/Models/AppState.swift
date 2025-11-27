//
//  AppState.swift
//  Dropnote
//

import Foundation

struct AppState: Codable {
    var noteIds: [UUID]
    var currentIndex: Int
    var version: Int
    
    init(noteIds: [UUID] = [], currentIndex: Int = 0, version: Int = 1) {
        self.noteIds = noteIds
        self.currentIndex = currentIndex
        self.version = version
    }
}


