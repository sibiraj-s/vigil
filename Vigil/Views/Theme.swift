import AppKit
import SwiftUI

/// Colors from the Vigil design canvas, with a matching warm dark palette.
enum Theme {
    /// Fill behind white text; dark enough for white text in both modes.
    static let accent = Color(light: 0xB45309, dark: 0xB45309)
    static let accentSoft = Color(light: 0xFDF0E1, dark: 0x3A2A17)
    /// Accent used as text or line color on neutral or soft backgrounds.
    static let accentText = Color(light: 0xB45309, dark: 0xF5A524)
    static let accentDeep = Color(light: 0x8A3D05, dark: 0xF5A524)

    static let text = Color(light: 0x1A1A1A, dark: 0xEDEBE7)
    static let textSecondary = Color(light: 0x5C5A55, dark: 0xA8A49C)
    static let textTertiary = Color(light: 0x6B6862, dark: 0x9A968E)

    static let panel = Color(light: 0xF6F5F2, dark: 0x262523)
    static let neutralFill = Color(light: 0xE4E2DC, dark: 0x3A3835)
    static let switchOff = Color(light: 0xC9C6BF, dark: 0x4A4844)
    static let divider = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.1)
    static let hover = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.06)
    static let pressed = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.1)

    static let window = Color(light: 0xFBFAF8, dark: 0x1F1E1C)
    static let sidebar = Color(light: 0xEFEDE8, dark: 0x2A2926)
    static let sidebarBorder = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.08)
    static let card = Color(light: 0xFFFFFF, dark: 0x292826)
    static let cardBorder = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.1)
    static let rowDivider = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.07)
    static let outlineButton = Color(light: 0xFFFFFF, dark: 0x33312E)
    /// Background of inline controls (menus, key recorders) sitting on a card.
    static let field = Color(light: 0xF3F1EC, dark: 0x383633)
    static let outlineBorder = Color(light: 0x000000, dark: 0xFFFFFF, opacity: 0.15)
}

/// Rounded, bordered background for inline controls on a card.
struct FieldBackground: ViewModifier {
    var highlighted = false

    func body(content: Content) -> some View {
        content
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(highlighted ? Theme.accentText : Theme.outlineBorder, lineWidth: highlighted ? 1.5 : 1)
            )
    }
}

extension View {
    func fieldBackground(highlighted: Bool = false) -> some View {
        modifier(FieldBackground(highlighted: highlighted))
    }
}

/// The app-wide appearance setting.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(nsColor: NSColor(hex: hex, opacity: opacity))
    }

    /// A color that follows the light or dark appearance it is drawn in.
    init(light: UInt32, dark: UInt32, opacity: Double = 1) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(hex: dark, opacity: opacity)
                : NSColor(hex: light, opacity: opacity)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32, opacity: Double = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: opacity
        )
    }
}

/// The design's pill switch. `compact` is the 30×18 size used inside the menu.
struct DesignSwitchStyle: ToggleStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            SwitchTrack(isOn: configuration.isOn, compact: compact)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

struct SwitchTrack: View {
    var isOn: Bool
    var compact = false

    var body: some View {
        let knob: CGFloat = compact ? 14 : 16
        Capsule()
            .fill(isOn ? Theme.accent : Theme.switchOff)
            .frame(width: compact ? 30 : 34, height: knob + 4)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(compact ? 0.3 : 0), radius: 1, y: 1)
                    .frame(width: knob, height: knob)
                    .padding(2)
            }
            .animation(.snappy(duration: 0.15), value: isOn)
    }
}

/// Line icons drawn on the design's 16×16 grid, stroked in the current foreground color.
enum DesignIcon {
    case general, triggers, battery, shortcuts, about
    case apps, display, power, drive, wifi, schedule
    case plus, check

    fileprivate var lineWidth: CGFloat {
        switch self {
        case .plus: 1.6
        case .check: 1.8
        default: 1.4
        }
    }

    /// Size of the grid the path is drawn on.
    fileprivate var grid: CGSize {
        switch self {
        case .plus: CGSize(width: 12, height: 12)
        case .check: CGSize(width: 12, height: 10)
        default: CGSize(width: 16, height: 16)
        }
    }

    fileprivate var path: Path {
        Path { p in
            func line(_ points: CGPoint...) { p.addLines(points) }
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
                p.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: r, height: r))
            }
            /// An arc over the top between two points on the same horizontal line.
            func arch(from a: CGPoint, to b: CGPoint, radius r: CGFloat) {
                let half = (b.x - a.x) / 2
                let center = CGPoint(x: a.x + half, y: a.y + (r * r - half * half).squareRoot())
                let start = Angle(radians: atan2(a.y - center.y, a.x - center.x))
                let end = Angle(radians: atan2(b.y - center.y, b.x - center.x))
                p.move(to: a)
                p.addArc(center: center, radius: r, startAngle: start, endAngle: end, clockwise: false)
            }

            switch self {
            case .general:
                p.addEllipse(in: CGRect(x: 5.5, y: 5.5, width: 5, height: 5))
                line(pt(8, 1.5), pt(8, 3.5)); line(pt(8, 12.5), pt(8, 14.5))
                line(pt(1.5, 8), pt(3.5, 8)); line(pt(12.5, 8), pt(14.5, 8))
                line(pt(3.4, 3.4), pt(4.8, 4.8)); line(pt(11.2, 11.2), pt(12.6, 12.6))
                line(pt(3.4, 12.6), pt(4.8, 11.2)); line(pt(11.2, 4.8), pt(12.6, 3.4))
            case .triggers:
                line(pt(9, 1.5), pt(3, 9), pt(7.5, 9), pt(7, 14.5), pt(13, 7), pt(8.5, 7))
                p.closeSubpath()
            case .battery:
                rect(1.5, 4.5, 11.5, 7, 2)
                line(pt(14.5, 7), pt(14.5, 9))
            case .shortcuts:
                rect(1.5, 4, 13, 8, 2)
                line(pt(4.5, 9.5), pt(11.5, 9.5))
            case .about:
                p.addEllipse(in: CGRect(x: 1.5, y: 1.5, width: 13, height: 13))
                line(pt(8, 7.5), pt(8, 11.5))
                line(pt(8, 5), pt(8, 5.01))
            case .apps:
                rect(2, 2, 12, 12, 3)
            case .display:
                rect(1.5, 2.5, 13, 8.5, 1.5)
                line(pt(5.5, 14), pt(10.5, 14)); line(pt(8, 11), pt(8, 14))
            case .power:
                line(pt(6, 1.5), pt(6, 4.5)); line(pt(10, 1.5), pt(10, 4.5))
                rect(3.5, 4.5, 9, 5, 2)
                line(pt(8, 9.5), pt(8, 14.5))
            case .drive:
                rect(1.5, 4.5, 13, 7, 2)
                line(pt(11.5, 8), pt(11.5, 8.01))
                line(pt(4.5, 8), pt(8, 8))
            case .wifi:
                arch(from: pt(1.5, 6), to: pt(14.5, 6), radius: 9)
                arch(from: pt(4, 8.5), to: pt(12, 8.5), radius: 5.5)
                arch(from: pt(6.5, 11), to: pt(9.5, 11), radius: 2)
            case .schedule:
                rect(2, 3, 12, 11, 2)
                line(pt(2, 6.5), pt(14, 6.5))
                line(pt(5.5, 1.5), pt(5.5, 4.5)); line(pt(10.5, 1.5), pt(10.5, 4.5))
            case .plus:
                line(pt(6, 1.5), pt(6, 10.5)); line(pt(1.5, 6), pt(10.5, 6))
            case .check:
                line(pt(1, 5.5), pt(4.2, 8.5), pt(11, 1.5))
            }
        }
    }
}

struct DesignIconView: View {
    let icon: DesignIcon

    init(_ icon: DesignIcon) { self.icon = icon }

    var body: some View {
        icon.path
            .stroke(style: StrokeStyle(lineWidth: icon.lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: icon.grid.width, height: icon.grid.height)
            .accessibilityHidden(true)
    }
}
