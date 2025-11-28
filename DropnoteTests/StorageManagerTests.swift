//
//  StorageManagerTests.swift
//  DropnoteTests
//
//  Created by Antti Mattila on 28.11.2025.
//

import Testing
import Foundation
@testable import Dropnote

// MARK: - TestableStorageManager

/// A testable version of StorageManager that uses a custom directory
final class TestableStorageManager {
    private let fileManager = FileManager.default
    let baseURL: URL
    private let notesURL: URL
    private let stateURL: URL
    private let settingsURL: URL
    
    init(testDirectory: URL) {
        baseURL = testDirectory
        notesURL = baseURL.appendingPathComponent("notes")
        stateURL = baseURL.appendingPathComponent("state.json")
        settingsURL = baseURL.appendingPathComponent("settings.json")
        
        try? fileManager.createDirectory(at: notesURL, withIntermediateDirectories: true)
    }
    
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
    
    func loadNote(id: UUID) -> Note? {
        let url = notesURL.appendingPathComponent("\(id.uuidString).txt")
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        
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
    
    func loadAllNotes(ids: [UUID]) -> [Note] {
        ids.compactMap { loadNote(id: $0) }
    }
    
    func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: settingsURL, options: .atomic)
    }
    
    func cleanup() {
        try? fileManager.removeItem(at: baseURL)
    }
}

// MARK: - Storage Tests

struct StorageManagerTests {
    private func createTestStorage() -> TestableStorageManager {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropnote-test-\(UUID().uuidString)")
        return TestableStorageManager(testDirectory: tempDir)
    }
    
    @Test func saveAndLoadNote() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let note = Note(content: "Test content 🚀")
        storage.saveNote(note)
        
        let loaded = storage.loadNote(id: note.id)
        
        #expect(loaded != nil)
        #expect(loaded?.id == note.id)
        #expect(loaded?.content == note.content)
    }
    
    @Test func loadNonExistentNoteReturnsNil() {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let loaded = storage.loadNote(id: UUID())
        #expect(loaded == nil)
    }
    
    @Test func deleteNote() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let note = Note(content: "To be deleted")
        storage.saveNote(note)
        
        // Verify saved
        #expect(storage.loadNote(id: note.id) != nil)
        
        // Delete
        storage.deleteNote(id: note.id)
        
        // Verify gone
        #expect(storage.loadNote(id: note.id) == nil)
    }
    
    @Test func saveAndLoadState() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let ids = [UUID(), UUID(), UUID()]
        let state = AppState(noteIds: ids, currentIndex: 2, version: 1)
        
        storage.saveState(state)
        let loaded = storage.loadState()
        
        #expect(loaded.noteIds == ids)
        #expect(loaded.currentIndex == 2)
    }
    
    @Test func loadStateReturnsDefaultWhenMissing() {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let state = storage.loadState()
        
        #expect(state.noteIds.isEmpty)
        #expect(state.currentIndex == 0)
    }
    
    @Test func saveAndLoadSettings() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        var settings = AppSettings()
        settings.hotkeyEnabled = false
        settings.launchAtStartup = true
        settings.hotkeyKeyCode = 15
        
        storage.saveSettings(settings)
        let loaded = storage.loadSettings()
        
        #expect(loaded.hotkeyEnabled == false)
        #expect(loaded.launchAtStartup == true)
        #expect(loaded.hotkeyKeyCode == 15)
    }
    
    @Test func loadSettingsReturnsDefaultWhenMissing() {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let settings = storage.loadSettings()
        
        #expect(settings.hotkeyEnabled == true)
        #expect(settings.launchAtStartup == false)
    }
    
    @Test func loadAllNotes() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        let note3 = Note(content: "Third")
        
        storage.saveNote(note1)
        storage.saveNote(note2)
        storage.saveNote(note3)
        
        let loaded = storage.loadAllNotes(ids: [note1.id, note2.id, note3.id])
        
        #expect(loaded.count == 3)
        #expect(loaded.map(\.content).sorted() == ["First", "Second", "Third"])
    }
    
    @Test func loadAllNotesFiltersOutMissing() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let note1 = Note(content: "Exists")
        let missingId = UUID()
        
        storage.saveNote(note1)
        
        let loaded = storage.loadAllNotes(ids: [note1.id, missingId])
        
        #expect(loaded.count == 1)
        #expect(loaded[0].id == note1.id)
    }
    
    @Test func noteContentWithSpecialCharacters() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let specialContent = """
        # Markdown Header
        
        - List item with emoji 🎉
        - Japanese: こんにちは
        - Math: √2 ≈ 1.414
        
        ```swift
        let code = "example"
        ```
        
        > Quote with "quotes" and 'apostrophes'
        """
        
        let note = Note(content: specialContent)
        storage.saveNote(note)
        
        let loaded = storage.loadNote(id: note.id)
        
        #expect(loaded?.content == specialContent)
    }
    
    @Test func emptyNoteContent() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let note = Note(content: "")
        storage.saveNote(note)
        
        let loaded = storage.loadNote(id: note.id)
        
        #expect(loaded?.content == "")
    }
    
    @Test func overwriteExistingNote() throws {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        let id = UUID()
        var note = Note(id: id, content: "Original")
        storage.saveNote(note)
        
        note.content = "Updated"
        storage.saveNote(note)
        
        let loaded = storage.loadNote(id: id)
        #expect(loaded?.content == "Updated")
    }
    
    @Test func deleteNonExistentNoteDoesNotThrow() {
        let storage = createTestStorage()
        defer { storage.cleanup() }
        
        // Should not throw or crash
        storage.deleteNote(id: UUID())
    }
}

