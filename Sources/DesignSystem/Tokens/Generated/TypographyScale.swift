// GENERATED — do not edit. Source: Figma › local text styles (bound to the Typography collection).
// Regenerate with `python3 tools/tokens/generate.py`. Snapshot sha256: fb198f0505d1f9e9209abad0cc128a28da57eb535d12076419b1a7b202ca205a

import CoreGraphics

/// Tier 2: the typography scale. One entry per Figma text style, named like the style; every value is a
/// reference to a `FoundationTokens` constant (the alias chain mirrors the variable bindings in Figma).
/// Render it with `DsText(_:variant:color:)`; colour is applied there, never here.
enum TypographyScale {
    /// D1 — Reckless Standard S-TRIAL Medium 67/79
    static let d1 = TextStyleSpec(
        family: FoundationTokens.fontFamilyReckless,
        weight: FoundationTokens.fontWeightRecklessMedium,
        size: FoundationTokens.fontSize67,
        lineHeight: FoundationTokens.fontLineheight79,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// D2 — Reckless Standard S-TRIAL Medium 53/66
    static let d2 = TextStyleSpec(
        family: FoundationTokens.fontFamilyReckless,
        weight: FoundationTokens.fontWeightRecklessMedium,
        size: FoundationTokens.fontSize53,
        lineHeight: FoundationTokens.fontLineheight66,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// H1 — Reckless Standard S-TRIAL Regular 45/49
    static let h1 = TextStyleSpec(
        family: FoundationTokens.fontFamilyReckless,
        weight: FoundationTokens.fontWeightRecklessRegular,
        size: FoundationTokens.fontSize45,
        lineHeight: FoundationTokens.fontLineheight49,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// H2 — Reckless Standard S-TRIAL Regular 35/51
    static let h2 = TextStyleSpec(
        family: FoundationTokens.fontFamilyReckless,
        weight: FoundationTokens.fontWeightRecklessRegular,
        size: FoundationTokens.fontSize35,
        lineHeight: FoundationTokens.fontLineheight51,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// H3 — GT Walsheim Trial Md 27/39
    static let h3 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimMedium,
        size: FoundationTokens.fontSize27,
        lineHeight: FoundationTokens.fontLineheight39,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// H4 — GT Walsheim Trial Md 23/35
    static let h4 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimMedium,
        size: FoundationTokens.fontSize23,
        lineHeight: FoundationTokens.fontLineheight35,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// H5 — GT Walsheim Trial Md 19/27
    static let h5 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimMedium,
        size: FoundationTokens.fontSize19,
        lineHeight: FoundationTokens.fontLineheight27,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// H6 — GT Walsheim Trial Md 17/23
    static let h6 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimMedium,
        size: FoundationTokens.fontSize17,
        lineHeight: FoundationTokens.fontLineheight23,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// P1 — GT Walsheim Trial Rg 23/35
    static let p1 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize23,
        lineHeight: FoundationTokens.fontLineheight35,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// P2 — GT Walsheim Trial Rg 19/29
    static let p2 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize19,
        lineHeight: FoundationTokens.fontLineheight29,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// P3 — GT Walsheim Trial Rg 17/25
    static let p3 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize17,
        lineHeight: FoundationTokens.fontLineheight25,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// P4 — GT Walsheim Trial Rg 15/23
    static let p4 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize15,
        lineHeight: FoundationTokens.fontLineheight23,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// P5 — GT Walsheim Trial Rg 13/21
    static let p5 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize13,
        lineHeight: FoundationTokens.fontLineheight21,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// Lb1 — GT Walsheim Trial Rg 13/21
    static let lb1 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize13,
        lineHeight: FoundationTokens.fontLineheight21,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// Lb2 — GT Walsheim Trial Rg 12/19
    static let lb2 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize12,
        lineHeight: FoundationTokens.fontLineheight19,
        trackingPercent: FoundationTokens.fontKerningNone
    )
    /// N1 — GT Walsheim Trial Md 35/43, tracking 9%
    static let n1 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimMedium,
        size: FoundationTokens.fontSize35,
        lineHeight: FoundationTokens.fontLineheight43,
        trackingPercent: FoundationTokens.fontKerningNum
    )
    /// N2 — GT Walsheim Trial Md 27/29, tracking 9%
    static let n2 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimMedium,
        size: FoundationTokens.fontSize27,
        lineHeight: FoundationTokens.fontLineheight29,
        trackingPercent: FoundationTokens.fontKerningNum
    )
    /// N3 — GT Walsheim Trial Rg 19/25, tracking 9%
    static let n3 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize19,
        lineHeight: FoundationTokens.fontLineheight25,
        trackingPercent: FoundationTokens.fontKerningNum
    )
    /// N4 — GT Walsheim Trial Rg 17/23, tracking 9%
    static let n4 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize17,
        lineHeight: FoundationTokens.fontLineheight23,
        trackingPercent: FoundationTokens.fontKerningNum
    )
    /// N5 — GT Walsheim Trial Rg 15/23, tracking 9%
    static let n5 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize15,
        lineHeight: FoundationTokens.fontLineheight23,
        trackingPercent: FoundationTokens.fontKerningNum
    )
    /// N6 — GT Walsheim Trial Rg 12/17, tracking 9%
    static let n6 = TextStyleSpec(
        family: FoundationTokens.fontFamilyGtWalsheim,
        weight: FoundationTokens.fontWeightGtwalsheimRegular,
        size: FoundationTokens.fontSize12,
        lineHeight: FoundationTokens.fontLineheight17,
        trackingPercent: FoundationTokens.fontKerningNum
    )
}

/// The Figma text style to render, by its lower-camel name; the raw value is the Figma style name.
enum TypographyVariant: String, CaseIterable {
    case d1 = "D1"
    case d2 = "D2"
    case h1 = "H1"
    case h2 = "H2"
    case h3 = "H3"
    case h4 = "H4"
    case h5 = "H5"
    case h6 = "H6"
    case p1 = "P1"
    case p2 = "P2"
    case p3 = "P3"
    case p4 = "P4"
    case p5 = "P5"
    case lb1 = "Lb1"
    case lb2 = "Lb2"
    case n1 = "N1"
    case n2 = "N2"
    case n3 = "N3"
    case n4 = "N4"
    case n5 = "N5"
    case n6 = "N6"

    var spec: TextStyleSpec {
        switch self {
        case .d1: TypographyScale.d1
        case .d2: TypographyScale.d2
        case .h1: TypographyScale.h1
        case .h2: TypographyScale.h2
        case .h3: TypographyScale.h3
        case .h4: TypographyScale.h4
        case .h5: TypographyScale.h5
        case .h6: TypographyScale.h6
        case .p1: TypographyScale.p1
        case .p2: TypographyScale.p2
        case .p3: TypographyScale.p3
        case .p4: TypographyScale.p4
        case .p5: TypographyScale.p5
        case .lb1: TypographyScale.lb1
        case .lb2: TypographyScale.lb2
        case .n1: TypographyScale.n1
        case .n2: TypographyScale.n2
        case .n3: TypographyScale.n3
        case .n4: TypographyScale.n4
        case .n5: TypographyScale.n5
        case .n6: TypographyScale.n6
        }
    }
}
