//
//  StorageManager.swift
//  Dropnote
//

import Foundation

// MARK: - Protocol for dependency injection

protocol StorageProviding {
    func loadState() -> AppState
    func saveState(_ state: AppState)
    func loadNote(id: UUID) -> Note?
    func saveNote(_ note: Note)
    func deleteNote(id: UUID)
    func loadAllNotes(ids: [UUID]) -> [Note]
}

// MARK: - Implementation

final class StorageManager: StorageProviding {
    static let shared = StorageManager()
    
    static var defaultDataDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/dropnote/data")
    }
    
    private let fileManager = FileManager.default
    private(set) var dataDirectory: URL
    private var notesURL: URL
    private var stateURL: URL
    
    private convenience init() {
        let customPath = UserDefaults.standard.string(forKey: AppSettings.Key.dataDirectory.rawValue)
        let directory = customPath.map { URL(fileURLWithPath: $0) } ?? Self.defaultDataDirectory
        self.init(dataDirectory: directory)
    }
    
    /// Testable initializer that accepts a custom data directory
    init(dataDirectory: URL) {
        self.dataDirectory = dataDirectory
        notesURL = dataDirectory.appendingPathComponent("notes")
        stateURL = dataDirectory.appendingPathComponent("state.json")
        createDirectoriesIfNeeded()
    }
    
    func reloadDataDirectory() {
        let customPath = UserDefaults.standard.string(forKey: AppSettings.Key.dataDirectory.rawValue)
        dataDirectory = customPath.map { URL(fileURLWithPath: $0) } ?? Self.defaultDataDirectory
        notesURL = dataDirectory.appendingPathComponent("notes")
        stateURL = dataDirectory.appendingPathComponent("state.json")
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: notesURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Migration
    
    func migrateData(from source: URL, to destination: URL) throws {
        guard source != destination else { return }
        
        let sourceNotes = source.appendingPathComponent("notes")
        let sourceState = source.appendingPathComponent("state.json")
        let destNotes = destination.appendingPathComponent("notes")
        let destState = destination.appendingPathComponent("state.json")
        
        // Create destination directories
        try fileManager.createDirectory(at: destNotes, withIntermediateDirectories: true)
        
        // Copy notes
        if fileManager.fileExists(atPath: sourceNotes.path) {
            let noteFiles = try fileManager.contentsOfDirectory(at: sourceNotes, includingPropertiesForKeys: nil)
            for file in noteFiles {
                let destFile = destNotes.appendingPathComponent(file.lastPathComponent)
                if fileManager.fileExists(atPath: destFile.path) {
                    try fileManager.removeItem(at: destFile)
                }
                try fileManager.copyItem(at: file, to: destFile)
            }
        }
        
        // Copy state.json
        if fileManager.fileExists(atPath: sourceState.path) {
            if fileManager.fileExists(atPath: destState.path) {
                try fileManager.removeItem(at: destState)
            }
            try fileManager.copyItem(at: sourceState, to: destState)
        }
    }
    
    // MARK: - State
    
    func loadState() -> AppState {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(AppState.self, from: data) else {
            return AppState()
        }
        return state
    }
    
    func saveState(_ state: AppState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }
    
    // MARK: - Notes
    
    func loadNote(id: UUID) -> Note? {
        let url = notesURL.appendingPathComponent("\(id.uuidString).txt")
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        
        // Get file dates
        let attrs = try? fileManager.attributesOfItem(atPath: url.path)
        let createdAt = attrs?[.creationDate] as? Date ?? Date()
        let updatedAt = attrs?[.modificationDate] as? Date ?? Date()
        
        return Note(id: id, content: content, createdAt: createdAt, updatedAt: updatedAt)
    }
    
    func saveNote(_ note: Note) {
        let url = notesURL.appendingPathComponent("\(note.id.uuidString).txt")
        try? note.content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func deleteNote(id: UUID) {
        let url = notesURL.appendingPathComponent("\(id.uuidString).txt")
        try? fileManager.removeItem(at: url)
    }
    
    // MARK: - Bulk Operations
    
    func loadAllNotes(ids: [UUID]) -> [Note] {
        ids.compactMap { loadNote(id: $0) }
    }
}


