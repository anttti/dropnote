//
//  NoteViewModel.swift
//  Dropnote
//

import Foundation
import Combine

final class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var currentIndex: Int = 0
    
    private let storage: StorageProviding
    private var saveTimer: Timer?
    
    private var isValidIndex: Bool { notes.indices.contains(currentIndex) }
    
    private var currentState: AppState {
        AppState(noteIds: notes.map(\.id), currentIndex: currentIndex)
    }
    
    var currentNote: Note? {
        guard isValidIndex else { return nil }
        return notes[currentIndex]
    }
    
    var currentContent: String {
        get { currentNote?.content ?? "" }
        set {
            guard isValidIndex else { return }
            notes[currentIndex].content = newValue
            notes[currentIndex].updatedAt = Date()
            scheduleSave()
        }
    }
    
    var canGoPrevious: Bool { notes.count > 1 && currentIndex > 0 }
    var canGoNext: Bool { notes.count > 1 && currentIndex < notes.count - 1 }
    var noteCountText: String { notes.isEmpty ? "0 of 0" : "\(currentIndex + 1) of \(notes.count)" }
    
    init(storage: StorageProviding = StorageManager.shared) {
        self.storage = storage
        load()
        
        // Reload notes when data directory changes
        SettingsManager.shared.onDataDirectoryChanged = { [weak self] in
            self?.reload()
        }
    }
    
    deinit {
        saveTimer?.invalidate()
    }
    
    func reload() {
        saveTimer?.invalidate()
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
        storage.saveState(currentState)
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
        storage.saveState(currentState)
    }
    
    func goToNext() {
        guard canGoNext else { return }
        save()
        currentIndex += 1
        storage.saveState(currentState)
    }
    
    // MARK: - CRUD
    
    func createNote() {
        let note = Note()
        notes.append(note)
        currentIndex = notes.count - 1
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


