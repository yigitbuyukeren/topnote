import XCTest
@testable import TopnoteCore

final class NoteStorageTests: XCTestCase {
    private var dir: URL!
    private var storage: NoteStorage!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        storage = NoteStorage(fileURL: dir.appendingPathComponent("alt/not.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testMissingFileGivesDefaults() {
        XCTAssertEqual(storage.load(), NoteState())
        XCTAssertTrue(NoteState().pinned)
    }

    func testRoundTripKeepsEverything() throws {
        let state = NoteState(
            text: "süt al\nçığ köfte 🙂", color: .blue, fontSize: 20, opacity: 0.7, pinned: false,
            frame: NoteFrame(x: 10, y: 20, width: 300, height: 240))
        try storage.save(state)
        XCTAssertEqual(storage.load(), state)
    }

    func testCorruptFileIsMovedAside() throws {
        try FileManager.default.createDirectory(
            at: storage.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ bozuk".utf8).write(to: storage.fileURL)
        XCTAssertEqual(storage.load(), NoteState())
        let aside = storage.fileURL.appendingPathExtension("bozuk")
        XCTAssertEqual(try String(contentsOf: aside), "{ bozuk")
        XCTAssertFalse(FileManager.default.fileExists(atPath: storage.fileURL.path))
    }

    func testMissingKeysFallBackToDefaults() throws {
        try FileManager.default.createDirectory(
            at: storage.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"text":"merhaba"}"#.utf8).write(to: storage.fileURL)
        let state = storage.load()
        XCTAssertEqual(state.text, "merhaba")
        XCTAssertEqual(state.color, .yellow)
        XCTAssertEqual(state.fontSize, 15)
    }

    func testUnknownColorFallsBackWithoutLosingText() throws {
        try FileManager.default.createDirectory(
            at: storage.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"text":"x","color":"mor"}"#.utf8).write(to: storage.fileURL)
        let state = storage.load()
        XCTAssertEqual(state.text, "x")
        XCTAssertEqual(state.color, .yellow)
    }

    func testValuesAreClamped() {
        var state = NoteState(fontSize: 500, opacity: 0)
        XCTAssertEqual(state.fontSize, NoteState.fontSizeRange.upperBound)
        XCTAssertEqual(state.opacity, NoteState.opacityRange.lowerBound)
        state.fontSize = 1
        state.opacity = 9
        XCTAssertEqual(state.fontSize, NoteState.fontSizeRange.lowerBound)
        XCTAssertEqual(state.opacity, NoteState.opacityRange.upperBound)
        state.opacity = .nan
        XCTAssertEqual(state.opacity, NoteState.opacityRange.lowerBound)
    }
}
