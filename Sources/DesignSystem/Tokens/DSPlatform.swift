import SwiftUI
import UIKit

// Hand-authored. The ONE place Figma's token vocabulary is turned into what SwiftUI needs (ADR 005).
//
// Figma stores a family name ("GT Walsheim Trial"), a style name ("Md"), letter spacing in percent, a line
// height in px and drop shadows with a spread. SwiftUI needs a PostScript font name, a Font.Weight, tracking in
// points, a line-height mechanism and `.shadow(color:radius:x:y:)`. Everything that converts between the two
// lives here, so the generated scales stay pure alias chains.

/// One text style as Figma binds it: five references into `FoundationTokens`.
struct TextStyleSpec: Equatable {
    /// Figma family name, e.g. "GT Walsheim Trial"
    let family: String
    /// Figma style name, e.g. "Md"
    let weight: String
    let size: CGFloat
    let lineHeight: CGFloat
    /// Letter spacing as a percent of the font size (ADR 003)
    let trackingPercent: CGFloat
}

enum DSPlatform {
    // MARK: Fonts

    /// Figma style name → SwiftUI weight. Extend when a family gains a weight; an unmapped name is a build-time
    /// test failure (TokenContractTests), never a silent fallback.
    static let fontWeights: [String: Font.Weight] = [
        FoundationTokens.fontWeightRecklessRegular: .regular,
        FoundationTokens.fontWeightRecklessMedium: .medium,
        FoundationTokens.fontWeightGtwalsheimRegular: .regular,
        FoundationTokens.fontWeightGtwalsheimMedium: .medium,
    ]

    /// Figma family + style name → the PostScript name of the face the app ships (Resources/Fonts, listed under
    /// UIAppFonts in project.yml). SwiftUI does not resolve a weight from a family name for custom fonts, so each
    /// face is named outright.
    ///
    /// TODO(licensing): all four are TRIAL cuts. Swap the files and these names for the licensed faces before
    /// anything ships.
    /// TODO(new weights): a family that gains a weight in Figma needs its face bundled and a row here.
    static let postScriptNames: [String: [String: String]] = [
        FoundationTokens.fontFamilyReckless: [
            FoundationTokens.fontWeightRecklessRegular: "RecklessStandardS-TRIAL-Regular",  // RecklessStandardS-TRIAL-Regular.otf
            FoundationTokens.fontWeightRecklessMedium: "RecklessStandardS-TRIAL-Medium",    // RecklessStandardS-TRIAL-Medium.otf
        ],
        FoundationTokens.fontFamilyGtWalsheim: [
            FoundationTokens.fontWeightGtwalsheimRegular: "GTWalsheimTrial-Rg",             // GT-Walsheim-Regular-Trial.otf
            FoundationTokens.fontWeightGtwalsheimMedium: "GTWalsheimTrial-Md",              // GT-Walsheim-Medium-Trial.otf
        ],
    ]

    /// The PostScript name for a Figma family and style, or nil if the app doesn't ship that face
    static func postScriptName(family: String, weight: String) -> String? {
        postScriptNames[family]?[weight]
    }

    /// The face a style renders in. Sizes are fixed (no Dynamic Type scaling), as the design states them.
    static func uiFont(for spec: TextStyleSpec) -> UIFont {
        guard let name = postScriptName(family: spec.family, weight: spec.weight),
              let font = UIFont(name: name, size: spec.size) else {
            assertionFailure("No bundled face for \(spec.family) \(spec.weight); add it to DSPlatform.postScriptNames")
            return .systemFont(ofSize: spec.size)
        }
        return font
    }

    static func font(for spec: TextStyleSpec) -> Font { Font(uiFont(for: spec)) }

    // MARK: Letter spacing

    /// Figma letter spacing is a percent of the font size; SwiftUI's `tracking` wants points (ADR 003).
    /// Not rounded: 9% of 19 is 1.71, and that is what's applied.
    static func trackingPoints(percent: CGFloat, fontSize: CGFloat) -> CGFloat {
        fontSize * percent / 100
    }

    // MARK: Line height

    /// How far a Figma line height is from the face's own (ascent + descent + leading). Positive: the lines sit
    /// further apart than the font would set them. Negative: closer (H1 45/49 and N2 27/29 today).
    static func extraLeading(for spec: TextStyleSpec) -> CGFloat {
        spec.lineHeight - uiFont(for: spec).lineHeight
    }

    // MARK: Shadows

    /// Figma blur → SwiftUI shadow radius. Figma's blur is the full extent of the falloff; SwiftUI's radius is
    /// about half that (as CSS blur-radius is to a Gaussian's 2σ).
    static func shadowRadius(blur: CGFloat) -> CGFloat { blur / 2 }
}

// MARK: - Applying a text style

/// Sets a view's text to one `TextStyleSpec`: face, tracking, and the Figma line height.
///
/// Line height: on iOS 26+ SwiftUI takes it exactly (`lineHeight(.exact(points:))`), for one line or many, so
/// every style matches Figma. Before iOS 26 SwiftUI can only ADD space between lines: styles at or above the
/// font's own line height are still exact (extra leading between lines, half of it above and below, as Figma
/// distributes it), but a style BELOW it (H1, N2) keeps the font's natural pitch when it wraps. That is a
/// documented gap (ADR 005), not an approximation: nothing is rounded to make it fit.
struct DsTextStyle: ViewModifier {
    let spec: TextStyleSpec

    func body(content: Content) -> some View {
        let styled = content
            .font(DSPlatform.font(for: spec))
            .tracking(DSPlatform.trackingPoints(percent: spec.trackingPercent, fontSize: spec.size))
        if #available(iOS 26.0, *) {
            styled.lineHeight(.exact(points: spec.lineHeight))
        } else {
            let extra = DSPlatform.extraLeading(for: spec)
            styled
                .lineSpacing(max(extra, 0))
                .padding(.vertical, extra / 2)
        }
    }
}
