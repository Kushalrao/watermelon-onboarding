// GENERATED — do not edit. Source: Figma › Container styles collection.
// Regenerate with `python3 tools/tokens/generate.py`. Snapshot sha256: fb198f0505d1f9e9209abad0cc128a28da57eb535d12076419b1a7b202ca205a

import CoreGraphics

/// Corner radii in points: the Figma Radius/<n> variables. No semantic layer yet, so components use these
/// directly, through `Surface(radius:)`.
enum RadiusToken: CaseIterable {
    case radius15
    case radius23
    case radius27
    case radius35

    var value: CGFloat {
        switch self {
        case .radius15: 15
        case .radius23: 23
        case .radius27: 27
        case .radius35: 35
        }
    }

    /// The Figma variable it comes from
    var figmaName: String {
        switch self {
        case .radius15: "Radius/15"
        case .radius23: "Radius/23"
        case .radius27: "Radius/27"
        case .radius35: "Radius/35"
        }
    }
}

/// Stroke widths in points: the Figma Border/<name> variables. Used through `Surface(border:)`.
enum BorderTokens {
    /// 0.7px hairline stroke used by borders and separators.
    static let hairline: CGFloat = 0.7

    /// Every constant by its Figma variable name, for the contract tests
    static let byFigmaName: [String: CGFloat] = [
        "Border/hairline": hairline,
    ]
}
