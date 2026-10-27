import AppKit
import Combine
import TopnoteCore

/// Ekrandaki notun tek doğruluk kaynağı. Değişiklikler kısa bir gecikmeyle diske yazılır.
final class NoteModel: ObservableObject {
    @Published var state: NoteState
    private let storage: NoteStorage
    private var saveTimer: Timer?

    init(storage: NoteStorage = NoteStorage(fileURL: NoteStorage.defaultURL)) {
        self.storage = storage
        self.state = storage.load()
    }

    func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.saveNow()
        }
    }

    func saveNow() {
        saveTimer?.invalidate()
        saveTimer = nil
        do {
            try storage.save(state)
        } catch {
            NSLog("Topnote: not kaydedilemedi: \(error.localizedDescription)")
        }
    }

    func changeFontSize(by delta: Double) {
        state.fontSize += delta
        scheduleSave()
    }
}
