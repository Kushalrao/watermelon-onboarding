// GENERATED — do not edit. Source: Figma › Typography collection.
// Regenerate with `python3 tools/tokens/generate.py`. Snapshot sha256: fb198f0505d1f9e9209abad0cc128a28da57eb535d12076419b1a7b202ca205a

import CoreGraphics

/// Tier 1: raw typography primitives. Never reference this in a component or screen; use `TypographyScale`
/// through `DsText`. (Named FoundationTokens, not Foundation, so it can't shadow Apple's Foundation module; ADR 005.)
enum FoundationTokens {
    // ── Font families (Figma family names; DSPlatform maps them to the PostScript names the app ships) ──
    /// Serif. Display (D1–D2) and large headings (H1–H2).
    static let fontFamilyReckless = "Reckless Standard S-TRIAL"
    /// Sans. Headings H3–H6, paragraph, labels, numericals.
    static let fontFamilyGtWalsheim = "GT Walsheim Trial"

    // ── Font weights (the Figma style names each family exposes; DSPlatform maps them to Font.Weight) ──
    static let fontWeightRecklessRegular = "Regular"
    static let fontWeightRecklessMedium = "Medium"
    static let fontWeightGtwalsheimRegular = "Rg"
    static let fontWeightGtwalsheimMedium = "Md"

    // ── Font sizes, pt ──
    static let fontSize12: CGFloat = 12
    static let fontSize13: CGFloat = 13
    static let fontSize15: CGFloat = 15
    static let fontSize17: CGFloat = 17
    static let fontSize19: CGFloat = 19
    static let fontSize23: CGFloat = 23
    static let fontSize27: CGFloat = 27
    static let fontSize35: CGFloat = 35
    static let fontSize45: CGFloat = 45
    static let fontSize53: CGFloat = 53
    static let fontSize67: CGFloat = 67

    // ── Line heights, pt ──
    static let fontLineheight17: CGFloat = 17
    static let fontLineheight19: CGFloat = 19
    static let fontLineheight21: CGFloat = 21
    static let fontLineheight23: CGFloat = 23
    static let fontLineheight25: CGFloat = 25
    static let fontLineheight27: CGFloat = 27
    static let fontLineheight29: CGFloat = 29
    static let fontLineheight35: CGFloat = 35
    static let fontLineheight39: CGFloat = 39
    static let fontLineheight43: CGFloat = 43
    static let fontLineheight49: CGFloat = 49
    static let fontLineheight51: CGFloat = 51
    static let fontLineheight66: CGFloat = 66
    static let fontLineheight79: CGFloat = 79

    // ── Letter spacing, PERCENT of font size (ADR 003); DSPlatform converts to points ──
    /// Default letter spacing (0%) for all non-numerical styles.
    static let fontKerningNone: CGFloat = 0
    /// Letter spacing (%) for numerical styles N1–N6.
    static let fontKerningNum: CGFloat = 9

    /// Every string constant by its Figma variable name, for the contract tests
    static let stringsByFigmaName: [String: String] = [
        "font/family/Reckless": fontFamilyReckless,
        "font/family/GT Walsheim": fontFamilyGtWalsheim,
        "font/weight/reckless/regular": fontWeightRecklessRegular,
        "font/weight/reckless/medium": fontWeightRecklessMedium,
        "font/weight/gtwalsheim/regular": fontWeightGtwalsheimRegular,
        "font/weight/gtwalsheim/medium": fontWeightGtwalsheimMedium,
    ]

    /// Every numeric constant by its Figma variable name, for the contract tests
    static let numbersByFigmaName: [String: CGFloat] = [
        "font/size/12": fontSize12,
        "font/size/13": fontSize13,
        "font/size/15": fontSize15,
        "font/size/17": fontSize17,
        "font/size/19": fontSize19,
        "font/size/23": fontSize23,
        "font/size/27": fontSize27,
        "font/size/35": fontSize35,
        "font/size/45": fontSize45,
        "font/size/53": fontSize53,
        "font/size/67": fontSize67,
        "font/lineheight/17": fontLineheight17,
        "font/lineheight/19": fontLineheight19,
        "font/lineheight/21": fontLineheight21,
        "font/lineheight/23": fontLineheight23,
        "font/lineheight/25": fontLineheight25,
        "font/lineheight/27": fontLineheight27,
        "font/lineheight/29": fontLineheight29,
        "font/lineheight/35": fontLineheight35,
        "font/lineheight/39": fontLineheight39,
        "font/lineheight/43": fontLineheight43,
        "font/lineheight/49": fontLineheight49,
        "font/lineheight/51": fontLineheight51,
        "font/lineheight/66": fontLineheight66,
        "font/lineheight/79": fontLineheight79,
        "font/kerning/none": fontKerningNone,
        "font/kerning/num": fontKerningNum,
    ]
}
