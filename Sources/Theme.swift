import SwiftUI

// Fonts bundled from the Figma file (Decade-UI-Iter). Fixed sizes to match the design 1:1.
enum FigmaFont {
    static func walsheim(_ size: CGFloat) -> Font { .custom("GTWalsheimTrial-Rg", fixedSize: size) }
    static func walsheimMedium(_ size: CGFloat) -> Font { .custom("GTWalsheimTrial-Md", fixedSize: size) }
    static func reckless(_ size: CGFloat) -> Font { .custom("RecklessStandardS-TRIAL-Medium", fixedSize: size) }
    static func recklessRegular(_ size: CGFloat) -> Font { .custom("RecklessStandardS-TRIAL-Regular", fixedSize: size) }
    static func superMedium(_ size: CGFloat) -> Font { .custom("GTSuperTxtTrial-Md", fixedSize: size) }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    static let screenBackground = Color(hex: 0xFCFCFC)
    static let ink = Color(hex: 0x212121)
    static let gain = Color(hex: 0x139100)
}

extension View {
    /// Positions a view's top-leading corner at (x, y) inside a `ZStack(alignment: .topLeading)`.
    func at(_ x: CGFloat, _ y: CGFloat) -> some View {
        padding(.leading, x).padding(.top, y)
    }
}

/// Timing for things that appear one after another, each quicker than the last.
/// Item n starts once item n-1 has mostly landed and takes ~65% of its time.
enum Stagger {
    /// Overall speed-up applied to every staggered sequence
    static let speed: Double = 1.7

    static func arrival(_ order: Int, first: Double = 0.42, acceleration: Double = 0.65, lead: Double = 0.55) -> (delay: Double, response: Double) {
        var delay = 0.0
        var response = first
        for _ in 0..<order {
            delay += response * lead
            response *= acceleration
        }
        return (delay / speed, max(response / speed, 0.1))
    }
}
