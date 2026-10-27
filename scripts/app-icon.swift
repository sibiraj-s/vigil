// Draws Vigil's app icon (the open eye on an amber squircle) at every size macOS uses,
// into Vigil/Assets.xcassets/AppIcon.appiconset.
//
//   swift scripts/app-icon.swift
//
// The eye's path matches EyeGlyph.open in Vigil/Views/EyeGlyph.swift.
import AppKit

let output = URL(fileURLWithPath: "Vigil/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

/// The icon on a 1024-point canvas, top-left origin; `context` is already scaled to the pixel size.
func drawIcon(in context: CGContext) {
    // Apple's macOS grid: an 824-point rounded square centred on the canvas, with room for its shadow.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    context.saveGState()
    // Shadow offsets ignore the flip above, so a negative height still casts downward.
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: rgb(0x000000, 0.3))
    context.addPath(shape)
    context.setFillColor(rgb(0xB45309))
    context.fillPath()
    context.restoreGState()

    // Lighter amber at the top, the accent at the bottom.
    context.saveGState()
    context.addPath(shape)
    context.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [rgb(0xF5A524), rgb(0xB45309)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 512, y: tile.minY), end: CGPoint(x: 512, y: tile.maxY), options: [])
    context.restoreGState()

    // The eye, in EyeGlyph's 24×16 view box, scaled to 560 points wide.
    let scale: CGFloat = 560 / 24
    context.saveGState()
    context.translateBy(x: 512 - 12 * scale, y: 512 - 8 * scale)
    context.scaleBy(x: scale, y: scale)
    let white = rgb(0xFFFFFF)
    context.setStrokeColor(white)
    context.setFillColor(white)
    context.setLineCap(.round)
    context.setLineJoin(.miter)

    let outline = CGMutablePath()
    outline.move(to: CGPoint(x: 1.5, y: 8))
    outline.addCurve(to: CGPoint(x: 12, y: 1.5), control1: CGPoint(x: 1.5, y: 8), control2: CGPoint(x: 5.5, y: 1.5))
    outline.addCurve(to: CGPoint(x: 22.5, y: 8), control1: CGPoint(x: 18.5, y: 1.5), control2: CGPoint(x: 22.5, y: 8))
    outline.addCurve(to: CGPoint(x: 12, y: 14.5), control1: CGPoint(x: 22.5, y: 8), control2: CGPoint(x: 18.5, y: 14.5))
    outline.addCurve(to: CGPoint(x: 1.5, y: 8), control1: CGPoint(x: 5.5, y: 14.5), control2: CGPoint(x: 1.5, y: 8))
    outline.closeSubpath()
    context.setLineWidth(1.8)
    context.addPath(outline)
    context.strokePath()

    context.addEllipse(in: CGRect(x: 12 - 3.4, y: 8 - 3.4, width: 6.8, height: 6.8))
    context.fillPath()
    context.restoreGState()
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    // Flip to a top-left origin, like EyeGlyph's paths expect.
    context.translateBy(x: 0, y: CGFloat(pixels))
    context.scaleBy(x: CGFloat(pixels) / 1024, y: -CGFloat(pixels) / 1024)
    drawIcon(in: context)
    return rep.representation(using: .png, properties: [:])!
}

try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try png(pixels: points * scale).write(to: output.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: output.appendingPathComponent("Contents.json"))
print("Wrote \(images.count) sizes to \(output.path)")
