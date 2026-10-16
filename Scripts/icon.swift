import AppKit

let canvas = 1024.0
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let output = URL(filePath: "Resources/AppIcon.icns")

let ink = color(0x2A1840)
let paper = color(0xFFFFFF)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat(hex >> 16 & 0xFF) / 255,
        green: CGFloat(hex >> 8 & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func gradient(_ stops: [(CGColor, CGFloat)]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: stops.map(\.0) as CFArray, locations: stops.map(\.1))!
}

func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func fill(_ context: CGContext, _ path: CGPath, _ color: CGColor) {
    context.addPath(path)
    context.setFillColor(color)
    context.fillPath()
}

func line(_ context: CGContext, _ points: [CGPoint], width: CGFloat, _ color: CGColor) {
    context.addLines(between: points)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(color)
    context.strokePath()
}

func ray(from corner: CGPoint, angle: CGFloat, from start: CGFloat, to end: CGFloat) -> [CGPoint] {
    [start, end].map { CGPoint(x: corner.x + cos(angle) * $0, y: corner.y + sin(angle) * $0) }
}

func drawBackground(_ context: CGContext) {
    let shape = rounded(tile, 186)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.35))
    fill(context, shape, color(0xEE2F6B))
    context.restoreGState()

    context.addPath(shape)
    context.clip()
    context.drawLinearGradient(
        gradient([(color(0xFF9A5C), 0), (color(0xFF5A63), 0.55), (color(0xE5287A), 1)]),
        start: CGPoint(x: 300, y: 924), end: CGPoint(x: 724, y: 100), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    context.drawRadialGradient(
        gradient([(color(0xFFFFFF, 0.28), 0), (color(0xFFFFFF, 0), 1)]),
        startCenter: CGPoint(x: 320, y: 820), startRadius: 0,
        endCenter: CGPoint(x: 320, y: 820), endRadius: 560, options: []
    )
}

func drawLaptop(_ context: CGContext) {
    let lid = CGRect(x: -250, y: -80, width: 500, height: 340)
    let screen = lid.insetBy(dx: 28, dy: 28)
    let base = CGRect(x: -312, y: -132, width: 624, height: 46)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -16), blur: 34, color: color(0x5A0B2E, 0.35))
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    fill(context, rounded(lid, 40), paper)
    fill(context, rounded(base, 23), paper)
    context.endTransparencyLayer()
    context.restoreGState()

    fill(context, rounded(CGRect(x: -62, y: base.maxY - 14, width: 124, height: 14), 7), color(0xF1D9E2))
    fill(context, rounded(screen, 18), ink)

    let eyeY = screen.midY + 40
    for side in [-1.0, 1.0] {
        let x = side * 92
        line(context, [
            CGPoint(x: x + side * 34, y: eyeY + 36),
            CGPoint(x: x - side * 30, y: eyeY),
            CGPoint(x: x + side * 34, y: eyeY - 36),
        ], width: 26, paper)
    }
    fill(context, CGPath(ellipseIn: CGRect(x: -40, y: screen.midY - 92, width: 80, height: 66), transform: nil), color(0xFF7AA2))

    for (corner, outward) in [(CGPoint(x: lid.maxX, y: lid.maxY), CGFloat.pi / 4), (CGPoint(x: lid.minX, y: lid.maxY), 3 * .pi / 4)] {
        for spread in [-0.62, 0, 0.62] as [CGFloat] {
            line(context, ray(from: corner, angle: outward + spread, from: 56, to: spread == 0 ? 132 : 104), width: 24, paper)
        }
    }
}

func draw(_ context: CGContext) {
    drawBackground(context)
    context.translateBy(x: 512, y: 470)
    context.rotate(by: -0.11)
    drawLaptop(context)
}

func png(pixels: Int) -> Data {
    let context = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.scaleBy(x: CGFloat(pixels) / canvas, y: CGFloat(pixels) / canvas)
    draw(context)
    return NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
}

let iconset = URL.temporaryDirectory.appending(path: "AppIcon-\(getpid()).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: iconset) }
for size in [16, 32, 128, 256, 512] {
    try png(pixels: size).write(to: iconset.appending(path: "icon_\(size)x\(size).png"))
    try png(pixels: size * 2).write(to: iconset.appending(path: "icon_\(size)x\(size)@2x.png"))
}

let iconutil = try Process.run(URL(filePath: "/usr/bin/iconutil"), arguments: ["-c", "icns", iconset.path(), "-o", output.path()])
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed with status \(iconutil.terminationStatus)") }
print("Wrote \(output.path())")
