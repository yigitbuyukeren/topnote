import Foundation

/// Kağıdın renkleri. RGB değerleri 0...1 aralığındadır.
public enum NoteColor: String, Codable, CaseIterable {
    case yellow, pink, green, blue, orange, gray

    public var title: String {
        switch self {
        case .yellow: return "Sarı"
        case .pink: return "Pembe"
        case .green: return "Yeşil"
        case .blue: return "Mavi"
        case .orange: return "Turuncu"
        case .gray: return "Gri"
        }
    }

    public var rgb: (r: Double, g: Double, b: Double) {
        switch self {
        case .yellow: return (1.00, 0.93, 0.55)
        case .pink: return (1.00, 0.80, 0.86)
        case .green: return (0.79, 0.94, 0.74)
        case .blue: return (0.75, 0.88, 1.00)
        case .orange: return (1.00, 0.82, 0.60)
        case .gray: return (0.90, 0.90, 0.91)
        }
    }
}

/// Pencerenin ekrandaki konumu ve boyutu.
public struct NoteFrame: Codable, Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Diske yazılan her şey: metin ve görünüm ayarları.
public struct NoteState: Codable, Equatable {
    public static let fontSizeRange: ClosedRange<Double> = 10...32
    public static let opacityRange: ClosedRange<Double> = 0.4...1.0
    public static let minimumSize = (width: 160.0, height: 120.0)

    public var text: String
    public var color: NoteColor
    public var fontSize: Double { didSet { fontSize = Self.clamp(fontSize, Self.fontSizeRange) } }
    public var opacity: Double { didSet { opacity = Self.clamp(opacity, Self.opacityRange) } }
    public var pinned: Bool
    public var frame: NoteFrame?

    public init(
        text: String = "",
        color: NoteColor = .yellow,
        fontSize: Double = 15,
        opacity: Double = 1,
        pinned: Bool = true,
        frame: NoteFrame? = nil
    ) {
        self.text = text
        self.color = color
        self.fontSize = Self.clamp(fontSize, Self.fontSizeRange)
        self.opacity = Self.clamp(opacity, Self.opacityRange)
        self.pinned = pinned
        self.frame = frame
    }

    // Alanlar sonradan eklenebilsin diye eksik anahtarlar varsayılana düşer.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = NoteState()
        self.init(
            text: try c.decodeIfPresent(String.self, forKey: .text) ?? d.text,
            color: (try? c.decodeIfPresent(NoteColor.self, forKey: .color)) ?? d.color,
            fontSize: try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? d.fontSize,
            opacity: try c.decodeIfPresent(Double.self, forKey: .opacity) ?? d.opacity,
            pinned: try c.decodeIfPresent(Bool.self, forKey: .pinned) ?? d.pinned,
            frame: try c.decodeIfPresent(NoteFrame.self, forKey: .frame)
        )
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
