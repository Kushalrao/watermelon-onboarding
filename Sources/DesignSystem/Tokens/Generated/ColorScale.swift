// GENERATED — do not edit. Source: Figma › Color Semantics collection (Light mode).
// Regenerate with `python3 tools/tokens/generate.py`. Snapshot sha256: fb198f0505d1f9e9209abad0cc128a28da57eb535d12076419b1a7b202ca205a

import SwiftUI

/// Tier 2: semantic colours, what components and screens use. Every value is a reference to a `ColorPrimitives`
/// constant, mirroring the alias in Figma. A Dark mode arrives as a second Figma mode and a second table here.
enum ColorScale {
    // ── surface ──
    /// Page background — everything sits on this.
    static let surfaceBase = ColorPrimitives.ivory50
    /// Widget / card surface on the base, carries Shadow/1.
    static let surfaceWidget = ColorPrimitives.staticWhite
    /// One level sunk into its parent surface.
    static let surfaceSunken1 = ColorPrimitives.ivory100
    /// Two levels sunk into its parent surface.
    static let surfaceSunken2 = ColorPrimitives.ivory200
    /// Raised element on a surface, carries Shadow/1.
    static let surfaceRaised = ColorPrimitives.staticWhite
    /// Focused / highlighted raised element, carries Shadow/2.
    static let surfaceFocus = ColorPrimitives.staticWhite
    /// Inverse surface; pair with content/inverse.
    static let surfaceInverse = ColorPrimitives.staticBlack
    // ── content ──
    /// Default text and icons. 14.99:1 on surface/base.
    static let contentPrimary = ColorPrimitives.stone900
    /// Supporting text. 6.13:1 on base.
    static let contentSecondary = ColorPrimitives.stone700
    /// De-emphasised text. 4.56:1 on base.
    static let contentTertiary = ColorPrimitives.stone600
    /// Decorative / metadata only. 3.41:1 — never body text.
    static let contentQuaternary = ColorPrimitives.stone500
    /// Disabled state.
    static let contentDisabled = ColorPrimitives.stone400
    /// Text on surface/inverse.
    static let contentInverse = ColorPrimitives.stone50
    /// Text on solid brand/status fills. Audit per fill — fails on status/success/solid for small text.
    static let contentOnColor = ColorPrimitives.staticWhite
    // ── border ──
    /// Hairline on widgets and dividers.
    static let borderSubtle = ColorPrimitives.ivory300
    /// Default control border.
    static let borderDefault = ColorPrimitives.ivory400
    /// Emphasised border. 3.41:1 vs base.
    static let borderStrong = ColorPrimitives.stone500
    /// Disabled state.
    static let borderDisabled = ColorPrimitives.ivory300
    // ── brand ──
    /// Primary brand fill. White ink 5.06:1.
    static let brandSolid = ColorPrimitives.brand600
    /// Hover / pressed state of brand/solid.
    static let brandSolidHover = ColorPrimitives.brand700
    /// Tinted brand surface.
    static let brandSubtle = ColorPrimitives.brand50
    /// Brand-coloured text. 5.79:1 on brand/subtle.
    static let brandText = ColorPrimitives.brand700
    /// Brand border.
    static let brandBorder = ColorPrimitives.brand300
    // ── secondary ──
    /// Secondary brand fill.
    static let secondarySolid = ColorPrimitives.secondary600
    /// Tinted secondary surface.
    static let secondarySubtle = ColorPrimitives.secondary50
    // ── status ──
    /// White ink 4.26:1 — large text / UI only.
    static let statusSuccessSolid = ColorPrimitives.utilityGreen600
    /// Success tint.
    static let statusSuccessSubtle = ColorPrimitives.utilityGreen50
    /// 5.37:1 on status/success/subtle.
    static let statusSuccessText = ColorPrimitives.utilityGreen700
    static let statusSuccessBorder = ColorPrimitives.utilityGreen300
    /// White ink 5.07:1.
    static let statusErrorSolid = ColorPrimitives.utilityRed600
    /// Error tint.
    static let statusErrorSubtle = ColorPrimitives.utilityRed50
    /// 5.81:1 on status/error/subtle.
    static let statusErrorText = ColorPrimitives.utilityRed700
    static let statusErrorBorder = ColorPrimitives.utilityRed300
    /// White ink 4.56:1.
    static let statusWarningSolid = ColorPrimitives.utilityYellow600
    /// Warning tint.
    static let statusWarningSubtle = ColorPrimitives.utilityYellow50
    /// 5.58:1 on status/warning/subtle.
    static let statusWarningText = ColorPrimitives.utilityYellow700
    static let statusWarningBorder = ColorPrimitives.utilityYellow300

    /// Every token by its Figma variable name, for the contract tests
    static let byFigmaName: [String: Color] = [
        "surface/base": surfaceBase,
        "surface/widget": surfaceWidget,
        "surface/sunken-1": surfaceSunken1,
        "surface/sunken-2": surfaceSunken2,
        "surface/raised": surfaceRaised,
        "surface/focus": surfaceFocus,
        "surface/inverse": surfaceInverse,
        "content/primary": contentPrimary,
        "content/secondary": contentSecondary,
        "content/tertiary": contentTertiary,
        "content/quaternary": contentQuaternary,
        "content/disabled": contentDisabled,
        "content/inverse": contentInverse,
        "content/on-color": contentOnColor,
        "border/subtle": borderSubtle,
        "border/default": borderDefault,
        "border/strong": borderStrong,
        "border/disabled": borderDisabled,
        "brand/solid": brandSolid,
        "brand/solid-hover": brandSolidHover,
        "brand/subtle": brandSubtle,
        "brand/text": brandText,
        "brand/border": brandBorder,
        "secondary/solid": secondarySolid,
        "secondary/subtle": secondarySubtle,
        "status/success/solid": statusSuccessSolid,
        "status/success/subtle": statusSuccessSubtle,
        "status/success/text": statusSuccessText,
        "status/success/border": statusSuccessBorder,
        "status/error/solid": statusErrorSolid,
        "status/error/subtle": statusErrorSubtle,
        "status/error/text": statusErrorText,
        "status/error/border": statusErrorBorder,
        "status/warning/solid": statusWarningSolid,
        "status/warning/subtle": statusWarningSubtle,
        "status/warning/text": statusWarningText,
        "status/warning/border": statusWarningBorder,
    ]

    /// The Colors primitives variable each token aliases, by Figma name, for the contract tests
    static let aliasByFigmaName: [String: String] = [
        "surface/base": "ivory/50",
        "surface/widget": "static/white",
        "surface/sunken-1": "ivory/100",
        "surface/sunken-2": "ivory/200",
        "surface/raised": "static/white",
        "surface/focus": "static/white",
        "surface/inverse": "static/black",
        "content/primary": "stone/900",
        "content/secondary": "stone/700",
        "content/tertiary": "stone/600",
        "content/quaternary": "stone/500",
        "content/disabled": "stone/400",
        "content/inverse": "stone/50",
        "content/on-color": "static/white",
        "border/subtle": "ivory/300",
        "border/default": "ivory/400",
        "border/strong": "stone/500",
        "border/disabled": "ivory/300",
        "brand/solid": "brand/600",
        "brand/solid-hover": "brand/700",
        "brand/subtle": "brand/50",
        "brand/text": "brand/700",
        "brand/border": "brand/300",
        "secondary/solid": "secondary/600",
        "secondary/subtle": "secondary/50",
        "status/success/solid": "utility-green/600",
        "status/success/subtle": "utility-green/50",
        "status/success/text": "utility-green/700",
        "status/success/border": "utility-green/300",
        "status/error/solid": "utility-red/600",
        "status/error/subtle": "utility-red/50",
        "status/error/text": "utility-red/700",
        "status/error/border": "utility-red/300",
        "status/warning/solid": "utility-yellow/600",
        "status/warning/subtle": "utility-yellow/50",
        "status/warning/text": "utility-yellow/700",
        "status/warning/border": "utility-yellow/300",
    ]
}

/// Fills a `Surface` may use: surface*, *Solid, *SolidHover, *Subtle (never border*)
enum SurfaceFill: CaseIterable {
    /// Page background — everything sits on this.
    case surfaceBase
    /// Widget / card surface on the base, carries Shadow/1.
    case surfaceWidget
    /// One level sunk into its parent surface.
    case surfaceSunken1
    /// Two levels sunk into its parent surface.
    case surfaceSunken2
    /// Raised element on a surface, carries Shadow/1.
    case surfaceRaised
    /// Focused / highlighted raised element, carries Shadow/2.
    case surfaceFocus
    /// Inverse surface; pair with content/inverse.
    case surfaceInverse
    /// Primary brand fill. White ink 5.06:1.
    case brandSolid
    /// Hover / pressed state of brand/solid.
    case brandSolidHover
    /// Tinted brand surface.
    case brandSubtle
    /// Secondary brand fill.
    case secondarySolid
    /// Tinted secondary surface.
    case secondarySubtle
    /// White ink 4.26:1 — large text / UI only.
    case statusSuccessSolid
    /// Success tint.
    case statusSuccessSubtle
    /// White ink 5.07:1.
    case statusErrorSolid
    /// Error tint.
    case statusErrorSubtle
    /// White ink 4.56:1.
    case statusWarningSolid
    /// Warning tint.
    case statusWarningSubtle

    var color: Color {
        switch self {
        case .surfaceBase: ColorScale.surfaceBase
        case .surfaceWidget: ColorScale.surfaceWidget
        case .surfaceSunken1: ColorScale.surfaceSunken1
        case .surfaceSunken2: ColorScale.surfaceSunken2
        case .surfaceRaised: ColorScale.surfaceRaised
        case .surfaceFocus: ColorScale.surfaceFocus
        case .surfaceInverse: ColorScale.surfaceInverse
        case .brandSolid: ColorScale.brandSolid
        case .brandSolidHover: ColorScale.brandSolidHover
        case .brandSubtle: ColorScale.brandSubtle
        case .secondarySolid: ColorScale.secondarySolid
        case .secondarySubtle: ColorScale.secondarySubtle
        case .statusSuccessSolid: ColorScale.statusSuccessSolid
        case .statusSuccessSubtle: ColorScale.statusSuccessSubtle
        case .statusErrorSolid: ColorScale.statusErrorSolid
        case .statusErrorSubtle: ColorScale.statusErrorSubtle
        case .statusWarningSolid: ColorScale.statusWarningSolid
        case .statusWarningSubtle: ColorScale.statusWarningSubtle
        }
    }
}

/// Strokes a `Surface` may draw: border*, *Border
enum BorderColor: CaseIterable {
    /// Hairline on widgets and dividers.
    case borderSubtle
    /// Default control border.
    case borderDefault
    /// Emphasised border. 3.41:1 vs base.
    case borderStrong
    /// Disabled state.
    case borderDisabled
    /// Brand border.
    case brandBorder
    case statusSuccessBorder
    case statusErrorBorder
    case statusWarningBorder

    var color: Color {
        switch self {
        case .borderSubtle: ColorScale.borderSubtle
        case .borderDefault: ColorScale.borderDefault
        case .borderStrong: ColorScale.borderStrong
        case .borderDisabled: ColorScale.borderDisabled
        case .brandBorder: ColorScale.brandBorder
        case .statusSuccessBorder: ColorScale.statusSuccessBorder
        case .statusErrorBorder: ColorScale.statusErrorBorder
        case .statusWarningBorder: ColorScale.statusWarningBorder
        }
    }
}

/// Colours for text and icons, as `DsText(color:)` takes them: content*, *Text
enum TextColor: CaseIterable {
    /// Default text and icons. 14.99:1 on surface/base.
    case contentPrimary
    /// Supporting text. 6.13:1 on base.
    case contentSecondary
    /// De-emphasised text. 4.56:1 on base.
    case contentTertiary
    /// Decorative / metadata only. 3.41:1 — never body text.
    case contentQuaternary
    /// Disabled state.
    case contentDisabled
    /// Text on surface/inverse.
    case contentInverse
    /// Text on solid brand/status fills. Audit per fill — fails on status/success/solid for small text.
    case contentOnColor
    /// Brand-coloured text. 5.79:1 on brand/subtle.
    case brandText
    /// 5.37:1 on status/success/subtle.
    case statusSuccessText
    /// 5.81:1 on status/error/subtle.
    case statusErrorText
    /// 5.58:1 on status/warning/subtle.
    case statusWarningText

    var color: Color {
        switch self {
        case .contentPrimary: ColorScale.contentPrimary
        case .contentSecondary: ColorScale.contentSecondary
        case .contentTertiary: ColorScale.contentTertiary
        case .contentQuaternary: ColorScale.contentQuaternary
        case .contentDisabled: ColorScale.contentDisabled
        case .contentInverse: ColorScale.contentInverse
        case .contentOnColor: ColorScale.contentOnColor
        case .brandText: ColorScale.brandText
        case .statusSuccessText: ColorScale.statusSuccessText
        case .statusErrorText: ColorScale.statusErrorText
        case .statusWarningText: ColorScale.statusWarningText
        }
    }
}
