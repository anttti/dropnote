//
//  StorageManager.swift
//  Dropnote
//

import Foundation

final class StorageManager {
    static let shared = StorageManager()
    
    private let fileManager = FileManager.default
    private let baseURL: URL
    private let notesURL: URL
    private let stateURL: URL
    
    private init() {
        let home = fileManager.homeDirectoryForCurrentUser
        baseURL = home.appendingPathComponent(".config/dropnote/data")
        notesURL = baseURL.appendingPathComponent("notes")
        stateURL = baseURL.appendingPathComponent("state.json")
        
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: notesURL, withIntermediateDirectories: true)
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


