import Foundation

/// Notu `~/Library/Application Support/Topnote/not.json` dosyasında tutar.
public struct NoteStorage {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Topnote", isDirectory: true).appendingPathComponent("not.json")
    }

    /// Dosya yoksa varsayılanı döner. Bozuksa `.bozuk` uzantısıyla kenara alır, böylece metin silinmez.
    public func load() -> NoteState {
        guard let data = try? Data(contentsOf: fileURL) else { return NoteState() }
        if let state = try? JSONDecoder().decode(NoteState.self, from: data) { return state }
        let aside = fileURL.appendingPathExtension("bozuk")
        try? FileManager.default.removeItem(at: aside)
        try? FileManager.default.moveItem(at: fileURL, to: aside)
        return NoteState()
    }

    public func save(_ state: NoteState) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(state).write(to: fileURL, options: .atomic)
    }
}
