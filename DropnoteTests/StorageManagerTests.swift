//
//  StorageManagerTests.swift
//  DropnoteTests
//
//  Created by Antti Mattila on 28.11.2025.
//

import Testing
import Foundation
@testable import Dropnote

// MARK: - Storage Tests

struct StorageManagerTests {
    private func createTestStorage() -> (StorageManager, URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropnote-test-\(UUID().uuidString)")
        return (StorageManager(dataDirectory: tempDir), tempDir)
    }
    
    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    @Test func saveAndLoadNote() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        let note = Note(content: "Test content 🚀")
        storage.saveNote(note)
        
        let loaded = storage.loadNote(id: note.id)
        
        #expect(loaded != nil)
        #expect(loaded?.id == note.id)
        #expect(loaded?.content == note.content)
    }
    
    @Test func loadNonExistentNoteReturnsNil() {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        let loaded = storage.loadNote(id: UUID())
        #expect(loaded == nil)
    }
    
    @Test func deleteNote() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
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
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        let ids = [UUID(), UUID(), UUID()]
        let state = AppState(noteIds: ids, currentIndex: 2, version: 1)
        
        storage.saveState(state)
        let loaded = storage.loadState()
        
        #expect(loaded.noteIds == ids)
        #expect(loaded.currentIndex == 2)
    }
    
    @Test func loadStateReturnsDefaultWhenMissing() {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        let state = storage.loadState()
        
        #expect(state.noteIds.isEmpty)
        #expect(state.currentIndex == 0)
    }
    
    @Test func loadAllNotes() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
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
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        let note1 = Note(content: "Exists")
        let missingId = UUID()
        
        storage.saveNote(note1)
        
        let loaded = storage.loadAllNotes(ids: [note1.id, missingId])
        
        #expect(loaded.count == 1)
        #expect(loaded[0].id == note1.id)
    }
    
    @Test func noteContentWithSpecialCharacters() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
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
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        let note = Note(content: "")
        storage.saveNote(note)
        
        let loaded = storage.loadNote(id: note.id)
        
        #expect(loaded?.content == "")
    }
    
    @Test func overwriteExistingNote() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        let id = UUID()
        var note = Note(id: id, content: "Original")
        storage.saveNote(note)
        
        note.content = "Updated"
        storage.saveNote(note)
        
        let loaded = storage.loadNote(id: id)
        #expect(loaded?.content == "Updated")
    }
    
    @Test func deleteNonExistentNoteDoesNotThrow() {
        let (storage, tempDir) = createTestStorage()
        defer { cleanup(tempDir) }
        
        // Should not throw or crash
        storage.deleteNote(id: UUID())
    }
}

