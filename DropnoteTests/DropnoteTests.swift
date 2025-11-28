//
//  DropnoteTests.swift
//  DropnoteTests
//
//  Created by Antti Mattila on 27.11.2025.
//

import Testing
import Foundation
@testable import Dropnote

// MARK: - Note Tests

struct NoteTests {
    @Test func noteInitializesWithDefaults() {
        let note = Note()
        #expect(note.content == "")
        #expect(note.id != UUID())
    }
    
    @Test func noteInitializesWithCustomValues() {
        let id = UUID()
        let content = "Test content"
        let created = Date(timeIntervalSince1970: 1000)
        let updated = Date(timeIntervalSince1970: 2000)
        
        let note = Note(id: id, content: content, createdAt: created, updatedAt: updated)
        
        #expect(note.id == id)
        #expect(note.content == content)
        #expect(note.createdAt == created)
        #expect(note.updatedAt == updated)
    }
    
    @Test func noteEquality() {
        let id = UUID()
        let fixedDate = Date(timeIntervalSince1970: 1000)
        let note1 = Note(id: id, content: "Test", createdAt: fixedDate, updatedAt: fixedDate)
        let note2 = Note(id: id, content: "Test", createdAt: fixedDate, updatedAt: fixedDate)
        let note3 = Note(content: "Test")
        
        #expect(note1 == note2)
        #expect(note1 != note3)
    }
    
    @Test func noteIsCodable() throws {
        let note = Note(content: "Hello, World!")
        let encoded = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(Note.self, from: encoded)
        
        #expect(decoded == note)
    }
}

// MARK: - AppState Tests

struct AppStateTests {
    @Test func appStateInitializesWithDefaults() {
        let state = AppState()
        #expect(state.noteIds.isEmpty)
        #expect(state.currentIndex == 0)
        #expect(state.version == 1)
    }
    
    @Test func appStateInitializesWithCustomValues() {
        let ids = [UUID(), UUID(), UUID()]
        let state = AppState(noteIds: ids, currentIndex: 2, version: 3)
        
        #expect(state.noteIds == ids)
        #expect(state.currentIndex == 2)
        #expect(state.version == 3)
    }
    
    @Test func appStateIsCodable() throws {
        let ids = [UUID(), UUID()]
        let state = AppState(noteIds: ids, currentIndex: 1, version: 2)
        
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(AppState.self, from: encoded)
        
        #expect(decoded.noteIds == state.noteIds)
        #expect(decoded.currentIndex == state.currentIndex)
        #expect(decoded.version == state.version)
    }
}

// MARK: - AppSettings Tests

struct AppSettingsTests {
    @Test func settingsInitializesWithDefaults() {
        let settings = AppSettings()
        #expect(settings.hotkeyEnabled == true)
        #expect(settings.hotkeyKeyCode == 2) // 'd' key
        #expect(settings.launchAtStartup == false)
        #expect(settings.dataDirectory == nil)
    }
    
    @Test func hotkeyDisplayStringShowsCorrectModifiers() {
        // Cmd+Shift+D (default)
        let settings = AppSettings()
        let display = settings.hotkeyDisplayString
        
        #expect(display.contains("⇧"))
        #expect(display.contains("⌘"))
        #expect(display.contains("D"))
    }
    
    @Test func displayStringWithAllModifiers() {
        // controlKey = 0x1000, optionKey = 0x0800, shiftKey = 0x0200, cmdKey = 0x0100
        let controlKey: UInt32 = 0x1000
        let optionKey: UInt32 = 0x0800
        let shiftKey: UInt32 = 0x0200
        let cmdKey: UInt32 = 0x0100
        
        let modifiers = controlKey | optionKey | shiftKey | cmdKey
        let display = AppSettings.displayString(keyCode: 0, modifiers: modifiers)
        
        #expect(display.contains("⌃"))
        #expect(display.contains("⌥"))
        #expect(display.contains("⇧"))
        #expect(display.contains("⌘"))
        #expect(display.contains("A"))
    }
    
    @Test func displayStringMapsKeyCodesCorrectly() {
        let testCases: [(UInt32, String)] = [
            (0, "A"), (1, "S"), (2, "D"), (3, "F"),
            (12, "Q"), (13, "W"), (14, "E"), (15, "R"),
            (36, "↩"), (48, "⇥"), (49, "Space"), (51, "⌫"), (53, "⎋"),
            (120, "F1"), (119, "F2"), (99, "F3"), (118, "F4"),
            (123, "←"), (124, "→"), (125, "↓"), (126, "↑"),
        ]
        
        for (keyCode, expected) in testCases {
            let display = AppSettings.displayString(keyCode: keyCode, modifiers: 0)
            #expect(display == expected, "KeyCode \(keyCode) should map to \(expected), got \(display)")
        }
    }
    
    @Test func displayStringReturnsQuestionMarkForUnknownKeyCode() {
        let display = AppSettings.displayString(keyCode: 999, modifiers: 0)
        #expect(display == "?")
    }
}

// MARK: - Mock Storage for Testing

final class MockStorage: StorageProviding {
    var state = AppState()
    var notes: [UUID: Note] = [:]
    
    // Track calls for verification
    var saveStateCalls: [AppState] = []
    var saveNoteCalls: [Note] = []
    var deleteNoteCalls: [UUID] = []
    
    func loadState() -> AppState { state }
    
    func saveState(_ state: AppState) {
        self.state = state
        saveStateCalls.append(state)
    }
    
    func loadNote(id: UUID) -> Note? { notes[id] }
    
    func saveNote(_ note: Note) {
        notes[note.id] = note
        saveNoteCalls.append(note)
    }
    
    func deleteNote(id: UUID) {
        notes.removeValue(forKey: id)
        deleteNoteCalls.append(id)
    }
    
    func loadAllNotes(ids: [UUID]) -> [Note] {
        ids.compactMap { notes[$0] }
    }
    
    // Helper to seed data
    func seed(notes: [Note], currentIndex: Int = 0) {
        for note in notes {
            self.notes[note.id] = note
        }
        state = AppState(noteIds: notes.map(\.id), currentIndex: currentIndex)
    }
}

// MARK: - NoteViewModel Tests

struct NoteViewModelTests {
    
    @Test func initWithEmptyStorageCreatesOneNote() {
        let storage = MockStorage()
        let vm = NoteViewModel(storage: storage)
        
        #expect(vm.notes.count == 1)
        #expect(vm.currentIndex == 0)
        #expect(vm.currentNote != nil)
        #expect(vm.noteCountText == "1 of 1")
    }
    
    @Test func initLoadsExistingNotes() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 1)
        
        let vm = NoteViewModel(storage: storage)
        
        #expect(vm.notes.count == 2)
        #expect(vm.currentIndex == 1)
        #expect(vm.currentNote?.content == "Second")
    }
    
    @Test func createNoteAppendsAndNavigates() {
        let storage = MockStorage()
        let vm = NoteViewModel(storage: storage)
        let initialCount = vm.notes.count
        
        vm.createNote()
        
        #expect(vm.notes.count == initialCount + 1)
        #expect(vm.currentIndex == vm.notes.count - 1)
        #expect(vm.currentNote?.content == "")
    }
    
    @Test func deleteCurrentNoteRemovesIt() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        let note3 = Note(content: "Third")
        storage.seed(notes: [note1, note2, note3], currentIndex: 1)
        
        let vm = NoteViewModel(storage: storage)
        vm.deleteCurrentNote()
        
        #expect(vm.notes.count == 2)
        #expect(storage.deleteNoteCalls.contains(note2.id))
        #expect(!vm.notes.contains { $0.id == note2.id })
    }
    
    @Test func deleteLastNoteCreatesNewEmptyNote() {
        let storage = MockStorage()
        let vm = NoteViewModel(storage: storage)
        let originalId = vm.currentNote?.id
        
        vm.deleteCurrentNote()
        
        #expect(vm.notes.count == 1)
        #expect(vm.currentNote?.id != originalId)
        #expect(vm.currentNote?.content == "")
    }
    
    @Test func deleteAtEndAdjustsIndex() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 1)
        
        let vm = NoteViewModel(storage: storage)
        vm.deleteCurrentNote()
        
        #expect(vm.currentIndex == 0)
        #expect(vm.currentNote?.content == "First")
    }
    
    @Test func goToNextIncrementsIndex() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 0)
        
        let vm = NoteViewModel(storage: storage)
        vm.goToNext()
        
        #expect(vm.currentIndex == 1)
        #expect(vm.currentNote?.content == "Second")
    }
    
    @Test func goToPreviousDecrementsIndex() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 1)
        
        let vm = NoteViewModel(storage: storage)
        vm.goToPrevious()
        
        #expect(vm.currentIndex == 0)
        #expect(vm.currentNote?.content == "First")
    }
    
    @Test func goToNextAtEndDoesNothing() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 1)
        
        let vm = NoteViewModel(storage: storage)
        vm.goToNext()
        
        #expect(vm.currentIndex == 1)
    }
    
    @Test func goToPreviousAtStartDoesNothing() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 0)
        
        let vm = NoteViewModel(storage: storage)
        vm.goToPrevious()
        
        #expect(vm.currentIndex == 0)
    }
    
    @Test func canGoPreviousIsFalseAtStart() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 0)
        
        let vm = NoteViewModel(storage: storage)
        
        #expect(vm.canGoPrevious == false)
        #expect(vm.canGoNext == true)
    }
    
    @Test func canGoNextIsFalseAtEnd() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 1)
        
        let vm = NoteViewModel(storage: storage)
        
        #expect(vm.canGoPrevious == true)
        #expect(vm.canGoNext == false)
    }
    
    @Test func navigationDisabledWithSingleNote() {
        let storage = MockStorage()
        let vm = NoteViewModel(storage: storage)
        
        #expect(vm.canGoPrevious == false)
        #expect(vm.canGoNext == false)
    }
    
    @Test func currentContentUpdatesNote() {
        let storage = MockStorage()
        let vm = NoteViewModel(storage: storage)
        
        vm.currentContent = "Updated content"
        
        #expect(vm.notes[0].content == "Updated content")
    }
    
    @Test func noteCountTextFormats() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        let note3 = Note(content: "Third")
        storage.seed(notes: [note1, note2, note3], currentIndex: 1)
        
        let vm = NoteViewModel(storage: storage)
        
        #expect(vm.noteCountText == "2 of 3")
    }
    
    @Test func createNoteSavesToStorage() {
        let storage = MockStorage()
        let vm = NoteViewModel(storage: storage)
        storage.saveStateCalls.removeAll()
        storage.saveNoteCalls.removeAll()
        
        vm.createNote()
        
        #expect(storage.saveStateCalls.count >= 1)
        #expect(storage.saveNoteCalls.count >= 1)
    }
    
    @Test func indexClampsWhenNotesFailToLoad() {
        let storage = MockStorage()
        // State references notes that don't exist
        storage.state = AppState(noteIds: [UUID(), UUID(), UUID()], currentIndex: 2)
        
        let vm = NoteViewModel(storage: storage)
        
        // Should create a fresh note since all failed to load
        #expect(vm.notes.count == 1)
        #expect(vm.currentIndex == 0)
    }
    
    @Test func indexClampsToMaxWhenTooHigh() {
        let storage = MockStorage()
        let note1 = Note(content: "First")
        let note2 = Note(content: "Second")
        storage.seed(notes: [note1, note2], currentIndex: 99)
        
        let vm = NoteViewModel(storage: storage)
        
        #expect(vm.currentIndex == 1) // Clamped to max valid index
    }
}
