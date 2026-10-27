import AppKit
import MinikNotCore

/// Başlıksız, yuvarlak köşeli, her zaman üstte duran küçük pencere.
final class NotePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false)
        isFloatingPanel = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isMovableByWindowBackground = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        appearance = NSAppearance(named: .aqua)
        minSize = NSSize(width: NoteState.minimumSize.width, height: NoteState.minimumSize.height)
        // Tüm masaüstlerinde ve tam ekran uygulamaların üstünde görünür.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func applyPinned(_ pinned: Bool) {
        level = pinned ? .floating : .normal
    }

    static func defaultFrame() -> NSRect {
        let size = NSSize(width: 240, height: 220)
        let area = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSRect(
            x: area.maxX - size.width - 24, y: area.maxY - size.height - 24,
            width: size.width, height: size.height)
    }

    /// Kayıtlı konum artık hiçbir ekranda görünmüyorsa (ekran çıkarıldıysa) varsayılana döner.
    static func restoredFrame(_ saved: NoteFrame?) -> NSRect {
        guard let f = saved else { return defaultFrame() }
        let rect = NSRect(x: f.x, y: f.y, width: f.width, height: f.height)
        let visible = NSScreen.screens.contains { $0.visibleFrame.intersection(rect).width >= 60
            && $0.visibleFrame.intersection(rect).height >= 40 }
        guard visible, rect.width >= NoteState.minimumSize.width, rect.height >= NoteState.minimumSize.height
        else { return defaultFrame() }
        return rect
    }
}
