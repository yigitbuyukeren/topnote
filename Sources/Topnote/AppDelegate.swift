import AppKit
import Carbon.HIToolbox
import Combine
import TopnoteCore
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model = NoteModel()
    private var panel: NotePanel!
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if activateRunningInstance() { NSApp.terminate(nil); return }

        NSApp.setActivationPolicy(.accessory)
        NSApp.mainMenu = makeMainMenu()
        setUpPanel()
        setUpStatusItem()
        // ⌃⌥N: nereden olursa olsun notu aç/gizle.
        hotKey = HotKey(keyCode: kVK_ANSI_N, modifiers: controlKey | optionKey) { [weak self] in
            self?.toggle()
        }
        show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        storeFrame()
        model.saveNow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show()
        return true
    }

    // MARK: Pencere

    private func setUpPanel() {
        panel = NotePanel(frame: NotePanel.restoredFrame(model.state.frame))
        let host = NSHostingView(rootView: NoteView(model: model) { [weak self] in self?.hide() })
        host.wantsLayer = true
        host.layer?.cornerRadius = 10
        host.layer?.masksToBounds = true
        panel.contentView = host
        applyAppearance(model.state)

        model.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.applyAppearance($0) }
            .store(in: &cancellables)

        for name in [NSWindow.didMoveNotification, NSWindow.didEndLiveResizeNotification] {
            NotificationCenter.default.addObserver(
                forName: name, object: panel, queue: .main
            ) { [weak self] _ in
                self?.storeFrame()
                self?.model.scheduleSave()
            }
        }
    }

    private func applyAppearance(_ state: NoteState) {
        panel.applyPinned(state.pinned)
        panel.alphaValue = state.opacity
        panel.invalidateShadow()
    }

    private func storeFrame() {
        let f = panel.frame
        model.state.frame = NoteFrame(x: f.origin.x, y: f.origin.y, width: f.width, height: f.height)
    }

    private func show() {
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hide() {
        storeFrame()
        model.saveNow()
        panel.orderOut(nil)
    }

    @objc private func toggle() {
        if panel.isVisible && panel.isKeyWindow { hide() } else { show() }
    }

    /// Aynı uygulamanın ikinci kopyası açılırsa mevcut olanı öne getirir.
    private func activateRunningInstance() -> Bool {
        guard let id = Bundle.main.bundleIdentifier else { return false }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .filter { $0 != NSRunningApplication.current }
        guard let other = others.first else { return false }
        other.activate()
        return true
    }

    // MARK: Menüler

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Topnote")
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let visible = panel.isVisible
        menu.addItem(item(visible ? "Notu Gizle" : "Notu Göster", #selector(toggle), key: "n", mods: [.control, .option]))
        menu.addItem(.separator())
        addOptions(to: menu)
        menu.addItem(.separator())
        menu.addItem(item("Çıkış", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp))
    }

    /// Hem menü çubuğu ikonunda hem uygulama menüsünde görünen ortak ayarlar.
    private func addOptions(to menu: NSMenu) {
        let pin = item("Her Zaman Üstte", #selector(togglePinned), key: "p")
        pin.state = model.state.pinned ? .on : .off
        menu.addItem(pin)

        let colors = NSMenuItem(title: "Renk", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        for c in NoteColor.allCases {
            let it = item(c.title, #selector(pickColor(_:)))
            it.representedObject = c.rawValue
            it.state = model.state.color == c ? .on : .off
            colorMenu.addItem(it)
        }
        colors.submenu = colorMenu
        menu.addItem(colors)

        let opacity = NSMenuItem(title: "Saydamlık", action: nil, keyEquivalent: "")
        let opacityMenu = NSMenu()
        for percent in [100, 85, 70, 55] {
            let it = item("%\(percent)", #selector(pickOpacity(_:)))
            it.tag = percent
            it.state = Int((model.state.opacity * 100).rounded()) == percent ? .on : .off
            opacityMenu.addItem(it)
        }
        opacity.submenu = opacityMenu
        menu.addItem(opacity)

        menu.addItem(item("Yazıyı Büyüt", #selector(biggerText), key: "+"))
        menu.addItem(item("Yazıyı Küçült", #selector(smallerText), key: "-"))

        menu.addItem(.separator())
        let login = item("Girişte Başlat", #selector(toggleLaunchAtLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
    }

    private func makeMainMenu() -> NSMenu {
        let main = NSMenu()

        let app = NSMenu()
        app.addItem(item("Topnote Hakkında", #selector(NSApplication.orderFrontStandardAboutPanel(_:)), target: NSApp))
        app.addItem(.separator())
        app.addItem(item("Topnote'u Gizle", #selector(NSApplication.hide(_:)), key: "h", target: NSApp))
        app.addItem(item("Çıkış", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp))
        main.addItem(submenuItem(app))

        let edit = NSMenu(title: "Düzen")
        edit.addItem(item("Geri Al", Selector(("undo:")), key: "z", target: nil))
        edit.addItem(item("Yinele", Selector(("redo:")), key: "Z", target: nil))
        edit.addItem(.separator())
        edit.addItem(item("Kes", #selector(NSText.cut(_:)), key: "x", target: nil))
        edit.addItem(item("Kopyala", #selector(NSText.copy(_:)), key: "c", target: nil))
        edit.addItem(item("Yapıştır", #selector(NSText.paste(_:)), key: "v", target: nil))
        edit.addItem(item("Tümünü Seç", #selector(NSText.selectAll(_:)), key: "a", target: nil))
        main.addItem(submenuItem(edit))

        let note = NSMenu(title: "Not")
        note.addItem(item("Notu Gizle", #selector(hideAction), key: "w"))
        note.addItem(.separator())
        note.delegate = noteMenuDelegate
        main.addItem(submenuItem(note))
        return main
    }

    /// "Not" menüsü açılırken ortak ayarları taze durumla doldurur.
    private lazy var noteMenuDelegate = NoteMenuDelegate { [unowned self] menu in
        while menu.items.count > 2 { menu.removeItem(at: 2) }
        addOptions(to: menu)
    }

    private func submenuItem(_ menu: NSMenu) -> NSMenuItem {
        let it = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
        it.submenu = menu
        return it
    }

    private func item(
        _ title: String, _ action: Selector, key: String = "",
        mods: NSEvent.ModifierFlags = [.command], target: AnyObject? = .some(NSNull())
    ) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: action, keyEquivalent: key)
        it.keyEquivalentModifierMask = key.isEmpty ? [] : mods
        // `target` verilmediyse (NSNull) AppDelegate; nil ise first responder zinciri.
        it.target = target is NSNull ? self : target
        return it
    }

    // MARK: Eylemler

    @objc private func hideAction() { hide() }

    @objc private func togglePinned() {
        model.state.pinned.toggle()
        model.scheduleSave()
    }

    @objc private func pickColor(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let c = NoteColor(rawValue: raw) else { return }
        model.state.color = c
        model.scheduleSave()
    }

    @objc private func pickOpacity(_ sender: NSMenuItem) {
        model.state.opacity = Double(sender.tag) / 100
        model.scheduleSave()
    }

    @objc private func biggerText() { model.changeFontSize(by: 1) }
    @objc private func smallerText() { model.changeFontSize(by: -1) }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Girişte başlatma değiştirilemedi"
            alert.informativeText = "Uygulamayı Uygulamalar klasörüne taşıyıp tekrar dene.\n\(error.localizedDescription)"
            alert.runModal()
        }
    }
}

private final class NoteMenuDelegate: NSObject, NSMenuDelegate {
    private let refresh: (NSMenu) -> Void
    init(refresh: @escaping (NSMenu) -> Void) { self.refresh = refresh }
    func menuNeedsUpdate(_ menu: NSMenu) { refresh(menu) }
}
