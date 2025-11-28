//
//  ContentView.swift
//  Dropnote
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: NoteViewModel
    @ObservedObject var settingsManager: SettingsManager
    var onSettingsPressed: (() -> Void)?
    var onDismiss: (() -> Void)?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Button(action: viewModel.goToPrevious) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!viewModel.canGoPrevious)
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                
                Button(action: viewModel.goToNext) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.canGoNext)
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                
                Text(viewModel.noteCountText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 50)
                
                Spacer()
                
                Button(action: { settingsManager.updateIsPinned(!settingsManager.settings.isPinned) }) {
                    Image(systemName: settingsManager.settings.isPinned ? "pin.fill" : "pin.slash")
                }
                .help(settingsManager.settings.isPinned ? "Unpin window" : "Pin window")
                
                Button(action: { onSettingsPressed?() }) {
                    Image(systemName: "gear")
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button(action: viewModel.createNote) {
                    Image(systemName: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1)
            
            // Editor
            MarkdownTextView(text: Binding(
                get: { viewModel.currentContent },
                set: { viewModel.currentContent = $0 }
            ))
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(minWidth: 350, minHeight: 200)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteCurrentNote()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .background {
            Button("") { onDismiss?() }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()
        }
    }
}

#Preview {
    ContentView(viewModel: NoteViewModel(), settingsManager: .shared)
}
