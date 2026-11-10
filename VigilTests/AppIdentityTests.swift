import AppKit
import Testing

@testable import Vigil

/// A Debug build runs next to the installed app, so the two must be easy to tell apart.
struct AppIdentityTests {
    @Test func debugBuildHasItsOwnName() throws {
        let id = try #require(Bundle.main.bundleIdentifier)
        #if DEBUG
            #expect(id.hasSuffix(".debug"))
            #expect(AppInfo.name == "Vigil Dev")
        #else
            #expect(AppInfo.name == "Vigil")
        #endif
    }

    @Test(arguments: [EyeGlyph.closed, .open])
    func menuBarIconMarksDebugBuilds(glyph: EyeGlyph) throws {
        let image = MenuBarIcon.image(glyph, text: nil)
        let tiff = try #require(image.tiffRepresentation)
        let rep = try #require(NSBitmapImageRep(data: tiff))
        let scale = CGFloat(rep.pixelsWide) / image.size.width
        // The dot's centre, at the lower right; NSBitmapImageRep counts rows from the top.
        let alpha = rep.colorAt(x: rep.pixelsWide - Int(3 * scale), y: rep.pixelsHigh - Int(3 * scale))?.alphaComponent ?? 0
        #if DEBUG
            #expect(alpha > 0.9)
        #else
            #expect(alpha < 0.1)
        #endif
    }
}
