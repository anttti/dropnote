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
    }
    
    @Test func settingsIsCodable() throws {
        var settings = AppSettings()
        settings.hotkeyEnabled = false
        settings.launchAtStartup = true
        
        let encoded = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)
        
        #expect(decoded.hotkeyEnabled == settings.hotkeyEnabled)
        #expect(decoded.hotkeyKeyCode == settings.hotkeyKeyCode)
        #expect(decoded.hotkeyModifiers == settings.hotkeyModifiers)
        #expect(decoded.launchAtStartup == settings.launchAtStartup)
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

// MARK: - NoteViewModel Logic Tests

struct NoteViewModelLogicTests {
    @Test func noteCountTextFormatsCorrectly() {
        // Simulate the logic without storage dependency
        func formatNoteCount(isEmpty: Bool, index: Int, count: Int) -> String {
            isEmpty ? "0 of 0" : "\(index + 1) of \(count)"
        }
        
        #expect(formatNoteCount(isEmpty: true, index: 0, count: 0) == "0 of 0")
        #expect(formatNoteCount(isEmpty: false, index: 0, count: 1) == "1 of 1")
        #expect(formatNoteCount(isEmpty: false, index: 2, count: 5) == "3 of 5")
    }
    
    @Test func navigationGuardLogic() {
        // Test canGoPrevious logic
        func canGoPrevious(noteCount: Int, currentIndex: Int) -> Bool {
            noteCount > 1 && currentIndex > 0
        }
        
        #expect(canGoPrevious(noteCount: 0, currentIndex: 0) == false)
        #expect(canGoPrevious(noteCount: 1, currentIndex: 0) == false)
        #expect(canGoPrevious(noteCount: 2, currentIndex: 0) == false)
        #expect(canGoPrevious(noteCount: 2, currentIndex: 1) == true)
        #expect(canGoPrevious(noteCount: 5, currentIndex: 3) == true)
        
        // Test canGoNext logic
        func canGoNext(noteCount: Int, currentIndex: Int) -> Bool {
            noteCount > 1 && currentIndex < noteCount - 1
        }
        
        #expect(canGoNext(noteCount: 0, currentIndex: 0) == false)
        #expect(canGoNext(noteCount: 1, currentIndex: 0) == false)
        #expect(canGoNext(noteCount: 2, currentIndex: 0) == true)
        #expect(canGoNext(noteCount: 2, currentIndex: 1) == false)
        #expect(canGoNext(noteCount: 5, currentIndex: 3) == true)
        #expect(canGoNext(noteCount: 5, currentIndex: 4) == false)
    }
    
    @Test func deleteIndexAdjustmentLogic() {
        // After deletion, currentIndex should be min(currentIndex, notes.count - 1)
        func adjustedIndex(deletedAt: Int, remainingCount: Int) -> Int {
            min(deletedAt, max(remainingCount - 1, 0))
        }
        
        // Deleting last of 5 notes (index 4) → stay at 3
        #expect(adjustedIndex(deletedAt: 4, remainingCount: 4) == 3)
        
        // Deleting middle (index 2 of 5) → stay at 2
        #expect(adjustedIndex(deletedAt: 2, remainingCount: 4) == 2)
        
        // Deleting first (index 0) → stay at 0
        #expect(adjustedIndex(deletedAt: 0, remainingCount: 4) == 0)
        
        // Deleting only note → 0
        #expect(adjustedIndex(deletedAt: 0, remainingCount: 0) == 0)
    }
}
