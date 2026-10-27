// Kullanım: swift scripts/make-icon.swift Resources/AppIcon.icns
// Sarı bir not kağıdı çizer, iconset üretir ve iconutil ile .icns'e çevirir.
import AppKit

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let inset = s * 0.09
    let body = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let path = NSBezierPath(roundedRect: body, xRadius: s * 0.2, yRadius: s * 0.2)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.3)
    shadow.shadowBlurRadius = s * 0.035
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.015)
    shadow.set()
    NSColor(red: 1, green: 0.93, blue: 0.55, alpha: 1).setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(colors: [NSColor(white: 1, alpha: 0.35), NSColor(white: 1, alpha: 0)])!
        .draw(in: path, angle: -90)

    // Üst şerit
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSColor(red: 0.96, green: 0.82, blue: 0.30, alpha: 1).setFill()
    NSRect(x: body.minX, y: body.maxY - s * 0.17, width: body.width, height: s * 0.17).fill()
    NSGraphicsContext.restoreGraphicsState()

    // Yazı çizgileri
    NSColor(red: 0.45, green: 0.36, blue: 0.10, alpha: 0.55).setFill()
    let widths: [CGFloat] = [0.54, 0.54, 0.34]
    for (i, w) in widths.enumerated() {
        let y = body.maxY - s * (0.34 + 0.15 * CGFloat(i))
        NSBezierPath(
            roundedRect: NSRect(x: body.minX + s * 0.13, y: y, width: s * w, height: s * 0.045),
            xRadius: s * 0.022, yRadius: s * 0.022).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/AppIcon.icns"
let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("mininot-\(UUID().uuidString).iconset")
try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: tmp.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(base * 2).write(to: tmp.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", tmp.path, "-o", out]
try p.run()
p.waitUntilExit()
try? FileManager.default.removeItem(at: tmp)
exit(p.terminationStatus)
