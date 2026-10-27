import MinikNotCore
import SwiftUI

extension NoteColor {
    var color: Color {
        Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
}

struct NoteView: View {
    @ObservedObject var model: NoteModel
    var onClose: () -> Void

    @State private var hovering = false
    private let ink = Color(white: 0.13)

    var body: some View {
        VStack(spacing: 0) {
            header
            TextEditor(text: Binding(
                get: { model.state.text },
                set: { model.state.text = $0; model.scheduleSave() }
            ))
            .font(.system(size: model.state.fontSize))
            .foregroundColor(ink)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 7)
            .padding(.bottom, 6)
        }
        .background(model.state.color.color)
        .onHover { hovering = $0 }
    }

    private var header: some View {
        HStack(spacing: 2) {
            headerButton(
                model.state.pinned ? "pin.fill" : "pin.slash",
                help: model.state.pinned ? "Her zaman üstte (kapat)" : "Üstte tut"
            ) {
                model.state.pinned.toggle()
                model.scheduleSave()
            }
            Spacer(minLength: 0)
            Menu {
                ForEach(NoteColor.allCases, id: \.self) { c in
                    Button {
                        model.state.color = c
                        model.scheduleSave()
                    } label: {
                        Label(c.title, systemImage: model.state.color == c ? "checkmark" : "circle.fill")
                    }
                }
            } label: {
                Image(systemName: "paintpalette")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Renk")
            headerButton("xmark", help: "Gizle (⌥⌘N ile geri gelir)", action: onClose)
        }
        .foregroundColor(ink.opacity(hovering ? 0.75 : 0.3))
        .padding(.horizontal, 6)
        .frame(height: 26)
        .background(Color.black.opacity(0.05))
        .animation(.easeOut(duration: 0.15), value: hovering)
    }

    private func headerButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
