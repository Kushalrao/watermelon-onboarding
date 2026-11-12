// GENERATED — do not edit. Source: Figma › Colors primitives collection (Light mode).
// Regenerate with `python3 tools/tokens/generate.py`. Snapshot sha256: fb198f0505d1f9e9209abad0cc128a28da57eb535d12076419b1a7b202ca205a

import SwiftUI

/// Tier 1: the raw palette, 900 (darkest) to 50 (lightest) per ramp. Never reference this in a component or
/// screen; use `ColorScale` (Tier 2), which aliases into it.
enum ColorPrimitives {
    // ── brand ──
    static let brand900 = Color(hex: 0x4D1C14)
    static let brand800 = Color(hex: 0x7E3125)
    static let brand700 = Color(hex: 0xA13929)
    static let brand600 = Color(hex: 0xC63F2B)
    static let brand500 = Color(hex: 0xEC452D)
    static let brand400 = Color(hex: 0xFF6F56)
    static let brand300 = Color(hex: 0xFFAA97)
    static let brand200 = Color(hex: 0xFFCCC0)
    static let brand100 = Color(hex: 0xFFDAD0)
    static let brand50 = Color(hex: 0xFFEAE3)
    // ── secondary ──
    static let secondary900 = Color(hex: 0x431B12)
    static let secondary800 = Color(hex: 0x773829)
    static let secondary700 = Color(hex: 0x98432F)
    static let secondary600 = Color(hex: 0xBA4D34)
    static let secondary500 = Color(hex: 0xD44F30)
    static let secondary400 = Color(hex: 0xFD7C5D)
    static let secondary300 = Color(hex: 0xFFAA93)
    static let secondary200 = Color(hex: 0xFFCDBD)
    static let secondary100 = Color(hex: 0xFFDBCE)
    static let secondary50 = Color(hex: 0xFFEBE2)
    // ── accent-lavender ──
    static let accentLavender900 = Color(hex: 0x322235)
    static let accentLavender800 = Color(hex: 0x5C4261)
    static let accentLavender700 = Color(hex: 0x74527B)
    static let accentLavender600 = Color(hex: 0x8D6197)
    static let accentLavender500 = Color(hex: 0xA872B3)
    static let accentLavender400 = Color(hex: 0xCC97D7)
    static let accentLavender300 = Color(hex: 0xE0B6E9)
    static let accentLavender200 = Color(hex: 0xF0D2F7)
    static let accentLavender100 = Color(hex: 0xF5DFF9)
    static let accentLavender50 = Color(hex: 0xFCEEFF)
    // ── accent-pink ──
    static let accentPink900 = Color(hex: 0x471521)
    static let accentPink800 = Color(hex: 0x7D2E41)
    static let accentPink700 = Color(hex: 0xA03450)
    static let accentPink600 = Color(hex: 0xC43960)
    static let accentPink500 = Color(hex: 0xF54979)
    static let accentPink400 = Color(hex: 0xFF678F)
    static let accentPink300 = Color(hex: 0xFFA5B8)
    static let accentPink200 = Color(hex: 0xFFC9D4)
    static let accentPink100 = Color(hex: 0xFFD8E0)
    static let accentPink50 = Color(hex: 0xFFE9EE)
    // ── accent-lime ──
    static let accentLime900 = Color(hex: 0x222F00)
    static let accentLime800 = Color(hex: 0x435600)
    static let accentLime700 = Color(hex: 0x546B00)
    static let accentLime600 = Color(hex: 0x668100)
    static let accentLime500 = Color(hex: 0x799800)
    static let accentLime400 = Color(hex: 0x94B900)
    static let accentLime300 = Color(hex: 0xBCE50F)
    static let accentLime200 = Color(hex: 0xCEED79)
    static let accentLime100 = Color(hex: 0xDCF3A5)
    static let accentLime50 = Color(hex: 0xECFBCB)
    // ── accent-yellow ──
    static let accentYellow900 = Color(hex: 0x3B2400)
    static let accentYellow800 = Color(hex: 0x684600)
    static let accentYellow700 = Color(hex: 0x815800)
    static let accentYellow600 = Color(hex: 0x9A6B00)
    static let accentYellow500 = Color(hex: 0xB47E00)
    static let accentYellow400 = Color(hex: 0xDA9B00)
    static let accentYellow300 = Color(hex: 0xFEBD12)
    static let accentYellow200 = Color(hex: 0xFFD77C)
    static let accentYellow100 = Color(hex: 0xFFE4A7)
    static let accentYellow50 = Color(hex: 0xFFF1CC)
    // ── blue ──
    static let blue900 = Color(hex: 0x223959)
    static let blue800 = Color(hex: 0x394E6C)
    static let blue700 = Color(hex: 0x4E627D)
    static let blue600 = Color(hex: 0x64768E)
    static let blue500 = Color(hex: 0x7B8AA0)
    static let blue400 = Color(hex: 0x9DA9BA)
    static let blue300 = Color(hex: 0xC0C8D4)
    static let blue200 = Color(hex: 0xD9DEE6)
    static let blue100 = Color(hex: 0xE4E8EE)
    static let blue50 = Color(hex: 0xFFFEFC)
    // ── stone ──
    static let stone900 = Color(hex: 0x282424)
    static let stone800 = Color(hex: 0x504C4C)
    static let stone700 = Color(hex: 0x645F5F)
    static let stone600 = Color(hex: 0x787373)
    static let stone500 = Color(hex: 0x8D8888)
    static let stone400 = Color(hex: 0xABA6A6)
    static let stone300 = Color(hex: 0xCBC6C6)
    static let stone200 = Color(hex: 0xE2DCDC)
    static let stone100 = Color(hex: 0xECE6E6)
    static let stone50 = Color(hex: 0xF7F2F2)
    // ── utility-green ──
    static let utilityGreen900 = Color(hex: 0x043300)
    static let utilityGreen800 = Color(hex: 0x155E03)
    static let utilityGreen700 = Color(hex: 0x037600)
    static let utilityGreen600 = Color(hex: 0x008F00)
    static let utilityGreen500 = Color(hex: 0x00A800)
    static let utilityGreen400 = Color(hex: 0x3FD519)
    static let utilityGreen300 = Color(hex: 0x7CE469)
    static let utilityGreen200 = Color(hex: 0xACF49F)
    static let utilityGreen100 = Color(hex: 0xC6F8BD)
    static let utilityGreen50 = Color(hex: 0xDFFED9)
    // ── utility-red ──
    static let utilityRed900 = Color(hex: 0x481612)
    static let utilityRed800 = Color(hex: 0x7E3029)
    static let utilityRed700 = Color(hex: 0xA2372E)
    static let utilityRed600 = Color(hex: 0xC73D33)
    static let utilityRed500 = Color(hex: 0xF0453A)
    static let utilityRed400 = Color(hex: 0xFF6E5F)
    static let utilityRed300 = Color(hex: 0xFFA99C)
    static let utilityRed200 = Color(hex: 0xFFCCC2)
    static let utilityRed100 = Color(hex: 0xFFDAD2)
    static let utilityRed50 = Color(hex: 0xFFEAE5)
    // ── utility-yellow ──
    static let utilityYellow900 = Color(hex: 0x2E2A00)
    static let utilityYellow800 = Color(hex: 0x555000)
    static let utilityYellow700 = Color(hex: 0x6A6400)
    static let utilityYellow600 = Color(hex: 0x807800)
    static let utilityYellow500 = Color(hex: 0x968D00)
    static let utilityYellow400 = Color(hex: 0xB7AD00)
    static let utilityYellow300 = Color(hex: 0xDBD213)
    static let utilityYellow200 = Color(hex: 0xE8E47B)
    static let utilityYellow100 = Color(hex: 0xEFECA7)
    static let utilityYellow50 = Color(hex: 0xF8F7CC)
    // ── ivory ──
    static let ivory900 = Color(hex: 0x2C2825)
    static let ivory800 = Color(hex: 0x504C49)
    static let ivory700 = Color(hex: 0x63605C)
    static let ivory600 = Color(hex: 0x777471)
    static let ivory500 = Color(hex: 0x8C8886)
    static let ivory400 = Color(hex: 0xDEDBD9)
    static let ivory300 = Color(hex: 0xEBE9E8)
    static let ivory200 = Color(hex: 0xEDEBEA)
    static let ivory100 = Color(hex: 0xF5F3F2)
    static let ivory50 = Color(hex: 0xFDFCFC)
    // ── static ──
    static let staticWhite = Color(hex: 0xFFFFFF)
    static let staticBlack = Color(hex: 0x000000)

    /// Every colour by its Figma variable name, for the contract tests
    static let byFigmaName: [String: Color] = [
        "brand/900": brand900,
        "brand/800": brand800,
        "brand/700": brand700,
        "brand/600": brand600,
        "brand/500": brand500,
        "brand/400": brand400,
        "brand/300": brand300,
        "brand/200": brand200,
        "brand/100": brand100,
        "brand/50": brand50,
        "secondary/900": secondary900,
        "secondary/800": secondary800,
        "secondary/700": secondary700,
        "secondary/600": secondary600,
        "secondary/500": secondary500,
        "secondary/400": secondary400,
        "secondary/300": secondary300,
        "secondary/200": secondary200,
        "secondary/100": secondary100,
        "secondary/50": secondary50,
        "accent-lavender/900": accentLavender900,
        "accent-lavender/800": accentLavender800,
        "accent-lavender/700": accentLavender700,
        "accent-lavender/600": accentLavender600,
        "accent-lavender/500": accentLavender500,
        "accent-lavender/400": accentLavender400,
        "accent-lavender/300": accentLavender300,
        "accent-lavender/200": accentLavender200,
        "accent-lavender/100": accentLavender100,
        "accent-lavender/50": accentLavender50,
        "accent-pink/900": accentPink900,
        "accent-pink/800": accentPink800,
        "accent-pink/700": accentPink700,
        "accent-pink/600": accentPink600,
        "accent-pink/500": accentPink500,
        "accent-pink/400": accentPink400,
        "accent-pink/300": accentPink300,
        "accent-pink/200": accentPink200,
        "accent-pink/100": accentPink100,
        "accent-pink/50": accentPink50,
        "accent-lime/900": accentLime900,
        "accent-lime/800": accentLime800,
        "accent-lime/700": accentLime700,
        "accent-lime/600": accentLime600,
        "accent-lime/500": accentLime500,
        "accent-lime/400": accentLime400,
        "accent-lime/300": accentLime300,
        "accent-lime/200": accentLime200,
        "accent-lime/100": accentLime100,
        "accent-lime/50": accentLime50,
        "accent-yellow/900": accentYellow900,
        "accent-yellow/800": accentYellow800,
        "accent-yellow/700": accentYellow700,
        "accent-yellow/600": accentYellow600,
        "accent-yellow/500": accentYellow500,
        "accent-yellow/400": accentYellow400,
        "accent-yellow/300": accentYellow300,
        "accent-yellow/200": accentYellow200,
        "accent-yellow/100": accentYellow100,
        "accent-yellow/50": accentYellow50,
        "blue/900": blue900,
        "blue/800": blue800,
        "blue/700": blue700,
        "blue/600": blue600,
        "blue/500": blue500,
        "blue/400": blue400,
        "blue/300": blue300,
        "blue/200": blue200,
        "blue/100": blue100,
        "blue/50": blue50,
        "stone/900": stone900,
        "stone/800": stone800,
        "stone/700": stone700,
        "stone/600": stone600,
        "stone/500": stone500,
        "stone/400": stone400,
        "stone/300": stone300,
        "stone/200": stone200,
        "stone/100": stone100,
        "stone/50": stone50,
        "utility-green/900": utilityGreen900,
        "utility-green/800": utilityGreen800,
        "utility-green/700": utilityGreen700,
        "utility-green/600": utilityGreen600,
        "utility-green/500": utilityGreen500,
        "utility-green/400": utilityGreen400,
        "utility-green/300": utilityGreen300,
        "utility-green/200": utilityGreen200,
        "utility-green/100": utilityGreen100,
        "utility-green/50": utilityGreen50,
        "utility-red/900": utilityRed900,
        "utility-red/800": utilityRed800,
        "utility-red/700": utilityRed700,
        "utility-red/600": utilityRed600,
        "utility-red/500": utilityRed500,
        "utility-red/400": utilityRed400,
        "utility-red/300": utilityRed300,
        "utility-red/200": utilityRed200,
        "utility-red/100": utilityRed100,
        "utility-red/50": utilityRed50,
        "utility-yellow/900": utilityYellow900,
        "utility-yellow/800": utilityYellow800,
        "utility-yellow/700": utilityYellow700,
        "utility-yellow/600": utilityYellow600,
        "utility-yellow/500": utilityYellow500,
        "utility-yellow/400": utilityYellow400,
        "utility-yellow/300": utilityYellow300,
        "utility-yellow/200": utilityYellow200,
        "utility-yellow/100": utilityYellow100,
        "utility-yellow/50": utilityYellow50,
        "ivory/900": ivory900,
        "ivory/800": ivory800,
        "ivory/700": ivory700,
        "ivory/600": ivory600,
        "ivory/500": ivory500,
        "ivory/400": ivory400,
        "ivory/300": ivory300,
        "ivory/200": ivory200,
        "ivory/100": ivory100,
        "ivory/50": ivory50,
        "static/white": staticWhite,
        "static/black": staticBlack,
    ]
}
