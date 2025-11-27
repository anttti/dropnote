//
//  NoteViewModel.swift
//  Dropnote
//

import Foundation
import Combine

final class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentIndex: Int = 0
    
    private let storage = StorageManager.shared
    private var saveTimer: Timer?
    
    var currentNote: Note? {
        guard currentIndex >= 0 && currentIndex < notes.count else { return nil }
        return notes[currentIndex]
    }
    
    var currentContent: String {
        get { currentNote?.content ?? "" }
        set {
            guard currentIndex >= 0 && currentIndex < notes.count else { return }
            notes[currentIndex].content = newValue
            notes[currentIndex].updatedAt = Date()
            scheduleSave()
        }
    }
    
    var canGoPrevious: Bool { notes.count > 1 && currentIndex > 0 }
    var canGoNext: Bool { notes.count > 1 && currentIndex < notes.count - 1 }
    var noteCountText: String { notes.isEmpty ? "0 of 0" : "\(currentIndex + 1) of \(notes.count)" }
    
    init() {
        load()
    }
    
    // MARK: - Persistence
    
    private func load() {
        let state = storage.loadState()
        
        if state.noteIds.isEmpty {
            // First launch: create initial note
            let note = Note()
            notes = [note]
            currentIndex = 0
            save()
        } else {
            notes = storage.loadAllNotes(ids: state.noteIds)
            // Handle case where some notes failed to load
            if notes.isEmpty {
                let note = Note()
                notes = [note]
                currentIndex = 0
            } else {
                currentIndex = min(state.currentIndex, notes.count - 1)
            }
        }
    }
    
    private func save() {
        let state = AppState(
            noteIds: notes.map(\.id),
            currentIndex: currentIndex
        )
        storage.saveState(state)
        
        // Save current note
        if let note = currentNote {
            storage.saveNote(note)
        }
    }
    
    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.save()
        }
    }
    
    // MARK: - Navigation
    
    func goToPrevious() {
        guard canGoPrevious else { return }
        save()
        currentIndex -= 1
        storage.saveState(AppState(noteIds: notes.map(\.id), currentIndex: currentIndex))
    }
    
    func goToNext() {
        guard canGoNext else { return }
        save()
        currentIndex += 1
        storage.saveState(AppState(noteIds: notes.map(\.id), currentIndex: currentIndex))
    }
    
    // MARK: - CRUD
    
    func createNote() {
        save()
        let note = Note()
        notes.append(note)
        currentIndex = notes.count - 1
        storage.saveNote(note)
        save()
    }
    
    func deleteCurrentNote() {
        guard let note = currentNote else { return }
        
        storage.deleteNote(id: note.id)
        notes.remove(at: currentIndex)
        
        if notes.isEmpty {
            // Always keep at least one note
            let newNote = Note()
            notes = [newNote]
            currentIndex = 0
            storage.saveNote(newNote)
        } else {
            currentIndex = min(currentIndex, notes.count - 1)
        }
        
        save()
    }
}


