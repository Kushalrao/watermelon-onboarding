// GENERATED — do not edit. Source: Figma › local effect styles.
// Regenerate with `python3 tools/tokens/generate.py`. Snapshot sha256: fb198f0505d1f9e9209abad0cc128a28da57eb535d12076419b1a7b202ca205a

import CoreGraphics

/// One Figma drop shadow, verbatim. `color` is 0xRRGGBB; `opacity` 0–1; `blur` and `spread` as Figma states them.
struct ShadowParams: Equatable {
    let figmaName: String
    let color: UInt32
    let opacity: Double
    let offsetX: CGFloat
    let offsetY: CGFloat
    let blur: CGFloat
    let spread: CGFloat
}

/// Tier 1: drop-shadow parameters as designed in Figma. Never used directly; `ShadowScale` maps them to SwiftUI.
enum ShadowPrimitives {
    /// Shadow/1 — Resting surface lift. Blur 100, y 4, spread 12, 5%.
    static let shadow1 = ShadowParams(figmaName: "Shadow/1", color: 0x000000, opacity: 0.05, offsetX: 0, offsetY: 4, blur: 100, spread: 12)
    /// Shadow/2 — Raised surface. Blur 97, y 4, spread 7, 7%.
    static let shadow2 = ShadowParams(figmaName: "Shadow/2", color: 0x000000, opacity: 0.07, offsetX: 0, offsetY: 4, blur: 97, spread: 7)
    /// Shadow/3 — Strongest lift (floating / dark card). Blur 85, y 2, spread 7, 11%.
    static let shadow3 = ShadowParams(figmaName: "Shadow/3", color: 0x000000, opacity: 0.11, offsetX: 0, offsetY: 2, blur: 85, spread: 7)

    static let all: [ShadowParams] = [shadow1, shadow2, shadow3]
}
