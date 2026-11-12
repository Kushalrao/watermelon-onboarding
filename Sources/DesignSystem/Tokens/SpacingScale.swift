import CoreGraphics

// Hand-authored Tier 2: semantic spacing aliases over SpacingPrimitives, exactly as in the RN port
// (packages/tokens/src/spacingScale.ts: same names, same primitives).
//
// Figma's "Container styles" collection only holds the raw steps (Spacing/2 … Spacing/115). The names below are
// the code-side layer components and screens use; each is a reference to a primitive, never a literal. When the
// semantic layer is mirrored into Figma, this file becomes generated (ADR 001).

enum SpacingScale {
    /// Intentional zero: explicitly remove default padding.
    static let spaceNone: CGFloat = 0
    /// 2: icon-to-badge nudge, hairline gap, pixel-level alignment.
    static let space2xs = SpacingPrimitives.spacing2
    /// 5: icon-to-label gap, tight chip internal padding.
    static let spaceXs = SpacingPrimitives.spacing5
    /// 7: internal padding for small components: tag, badge, chip.
    static let spaceSm = SpacingPrimitives.spacing7
    /// 9: standard gap between sibling elements.
    static let spaceMd = SpacingPrimitives.spacing9
    /// 13: relaxed card inset, section with more visual weight.
    static let spaceMdLg = SpacingPrimitives.spacing13
    /// 15: standard component vertical padding: buttons, inputs.
    static let spaceLg = SpacingPrimitives.spacing15
    /// 21: card internal padding, section inset.
    static let spaceXl = SpacingPrimitives.spacing21
    /// 25: page horizontal margin.
    static let space2xl = SpacingPrimitives.spacing25
    /// 29: button horizontal padding, large section leading space.
    static let space3xl = SpacingPrimitives.spacing29
    /// 35: between major page sections.
    static let space4xl = SpacingPrimitives.spacing35
    /// 39: large list item height, section separator.
    static let space5xl = SpacingPrimitives.spacing39
    /// 47: bottom sheet top padding, modal inset.
    static let space6xl = SpacingPrimitives.spacing47
    /// 65: navigation bar height, fixed bottom area.
    static let space7xl = SpacingPrimitives.spacing65
    /// 75: tab bar + content offset.
    static let space8xl = SpacingPrimitives.spacing75
    /// 95: scroll offset for sticky headers.
    static let space9xl = SpacingPrimitives.spacing95
    /// 115: full-bleed hero image height, large illustration area.
    static let space10xl = SpacingPrimitives.spacing115
}

/// A `SpacingScale` step, as `Stack`'s gap and padding take it.
enum SpacingToken: CaseIterable {
    case spaceNone, space2xs, spaceXs, spaceSm, spaceMd, spaceMdLg, spaceLg, spaceXl, space2xl, space3xl
    case space4xl, space5xl, space6xl, space7xl, space8xl, space9xl, space10xl

    var value: CGFloat {
        switch self {
        case .spaceNone: SpacingScale.spaceNone
        case .space2xs: SpacingScale.space2xs
        case .spaceXs: SpacingScale.spaceXs
        case .spaceSm: SpacingScale.spaceSm
        case .spaceMd: SpacingScale.spaceMd
        case .spaceMdLg: SpacingScale.spaceMdLg
        case .spaceLg: SpacingScale.spaceLg
        case .spaceXl: SpacingScale.spaceXl
        case .space2xl: SpacingScale.space2xl
        case .space3xl: SpacingScale.space3xl
        case .space4xl: SpacingScale.space4xl
        case .space5xl: SpacingScale.space5xl
        case .space6xl: SpacingScale.space6xl
        case .space7xl: SpacingScale.space7xl
        case .space8xl: SpacingScale.space8xl
        case .space9xl: SpacingScale.space9xl
        case .space10xl: SpacingScale.space10xl
        }
    }
}
