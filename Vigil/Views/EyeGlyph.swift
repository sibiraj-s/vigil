import AppKit
import SwiftUI

/// Vigil's eye mark: closed while the Mac sleeps normally, open while it is held awake.
enum EyeGlyph {
    case closed
    case open
    /// Open eye with a bolt, for sessions started by a trigger.
    case trigger

    var viewBox: CGSize {
        self == .trigger ? CGSize(width: 28, height: 18) : CGSize(width: 24, height: 16)
    }

    /// Draws the glyph scaled to fit `rect` in a top-left-origin context.
    func draw(in context: CGContext, rect: CGRect, color: CGColor) {
        let box = viewBox
        let scale = min(rect.width / box.width, rect.height / box.height)
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: rect.midX - box.width * scale / 2, y: rect.midY - box.height * scale / 2)
        context.scaleBy(x: scale, y: scale)
        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineCap(.round)

        switch self {
        case .closed:
            let lid = CGMutablePath()
            lid.move(to: CGPoint(x: 1.5, y: 6))
            lid.addCurve(to: CGPoint(x: 12, y: 11.5), control1: CGPoint(x: 4.5, y: 10), control2: CGPoint(x: 8, y: 11.5))
            lid.addCurve(to: CGPoint(x: 22.5, y: 6), control1: CGPoint(x: 16, y: 11.5), control2: CGPoint(x: 19.5, y: 10))
            stroke(lid, width: 1.8, in: context)

            let lashes = CGMutablePath()
            lashes.addLines(between: [CGPoint(x: 6, y: 10.5), CGPoint(x: 4.5, y: 13)])
            lashes.addLines(between: [CGPoint(x: 12, y: 11.5), CGPoint(x: 12, y: 14.5)])
            lashes.addLines(between: [CGPoint(x: 18, y: 10.5), CGPoint(x: 19.5, y: 13)])
            stroke(lashes, width: 1.6, in: context)

        case .open:
            drawOpenEye(in: context, dy: 0)

        case .trigger:
            drawOpenEye(in: context, dy: 1)
            let bolt = CGMutablePath()
            bolt.addLines(between: [
                CGPoint(x: 24.5, y: 1), CGPoint(x: 22, y: 5.5), CGPoint(x: 25, y: 5.5), CGPoint(x: 23.5, y: 10),
            ])
            context.setLineJoin(.round)
            stroke(bolt, width: 1.5, in: context)
        }
    }

    private func drawOpenEye(in context: CGContext, dy: CGFloat) {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y + dy) }
        let outline = CGMutablePath()
        outline.move(to: p(1.5, 8))
        outline.addCurve(to: p(12, 1.5), control1: p(1.5, 8), control2: p(5.5, 1.5))
        outline.addCurve(to: p(22.5, 8), control1: p(18.5, 1.5), control2: p(22.5, 8))
        outline.addCurve(to: p(12, 14.5), control1: p(22.5, 8), control2: p(18.5, 14.5))
        outline.addCurve(to: p(1.5, 8), control1: p(5.5, 14.5), control2: p(1.5, 8))
        outline.closeSubpath()
        context.setLineJoin(.miter)
        stroke(outline, width: 1.8, in: context)

        context.addEllipse(in: CGRect(x: 12 - 3.4, y: 8 + dy - 3.4, width: 6.8, height: 6.8))
        context.fillPath()
    }

    private func stroke(_ path: CGPath, width: CGFloat, in context: CGContext) {
        context.setLineWidth(width)
        context.addPath(path)
        context.strokePath()
    }
}

/// SwiftUI rendering of an `EyeGlyph`.
struct EyeView: View {
    var glyph: EyeGlyph
    var color: Color
    @Environment(\.self) private var environment

    var body: some View {
        // Resolve here so appearance-dependent colors match the view's light or dark mode.
        let cgColor = color.resolve(in: environment).cgColor
        Canvas { context, size in
            context.withCGContext { cg in
                glyph.draw(in: cg, rect: CGRect(origin: .zero, size: size), color: cgColor)
            }
        }
        .aspectRatio(glyph.viewBox, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

enum MenuBarIcon {
    /// Amber on dark menu bars, deeper amber on light ones.
    static let activeColor = NSColor(name: "VigilMenuBarActive") { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0xF5 / 255, green: 0xA5 / 255, blue: 0x24 / 255, alpha: 1)
            : NSColor(srgbRed: 0xB4 / 255, green: 0x53 / 255, blue: 0x09 / 255, alpha: 1)
    }

    static func image(_ glyph: EyeGlyph, text: String?) -> NSImage {
        let height: CGFloat = 16
        let iconSize = CGSize(width: glyph.viewBox.width * 0.85, height: height)
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let textSize = text.map { ($0 as NSString).size(withAttributes: [.font: font]) } ?? .zero
        let width = ceil(iconSize.width + (text == nil ? 0 : 4 + textSize.width))

        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            let color = glyph == .closed ? NSColor.black : activeColor
            glyph.draw(in: context, rect: CGRect(origin: .zero, size: iconSize), color: color.cgColor)
            if let text {
                (text as NSString).draw(
                    at: CGPoint(x: iconSize.width + 4, y: (height - textSize.height) / 2),
                    withAttributes: [.font: font, .foregroundColor: color]
                )
            }
            return true
        }
        // The closed eye follows the menu bar's own color; the open eye keeps its amber.
        image.isTemplate = glyph == .closed
        image.accessibilityDescription = glyph == .closed ? "Vigil, off" : "Vigil, keeping Mac awake"
        return image
    }
}
