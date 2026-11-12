# ADR 005 — The SwiftUI port: where it mirrors the RN port and where the platform forced a decision

**Status:** Accepted
**Date:** 2026-11-11

## Context

The Horse Design System was first ported to React Native (`horse-design-system/packages/tokens`). This repo
is the SwiftUI port. It reads the same Figma snapshot and keeps the same three tiers and token names
(ADR 001–004). React Native made several platform decisions (Android elevation, platform font names,
percent → points); each needs its own answer in SwiftUI. They are all in one hand-authored file,
`Sources/DesignSystem/Tokens/DSPlatform.swift`.

## Decisions

### 1. The snapshot is copied, not shared
`tools/tokens/figma-variables.json` is a copy of the RN repo's snapshot. A re-export in the RN repo does not
change this build until the file is copied over and regenerated, so both the snapshot diff and the code diff
are reviewed here. Each generated file carries the snapshot's sha256; a build phase and a unit test fail on drift.

### 2. `Foundation` is called `FoundationTokens`
A Swift type named `Foundation` shadows Apple's Foundation module for qualified names. Every other name matches
the RN port: `SpacingPrimitives`, `ColorPrimitives`, `ShadowPrimitives`, `BorderTokens`, `TypographyScale`,
`ColorScale`, `SpacingScale`, `ShadowScale`, and each constant inside them (`fontSize17`, `spaceMd`, `brand500`).

### 3. Token keys are enums
RN passes tokens as string keys typed by `keyof`. Swift uses enums: `TypographyVariant`, `SpacingToken`,
`RadiusToken`, `ShadowToken`, and three generated colour roles, `SurfaceFill`, `BorderColor`, `TextColor`,
built with the RN port's name rules (`surface*` / `*Solid` / `*Subtle`; `border*` / `*Border`; `content*` / `*Text`).
One difference: `border/subtle` matches both the fill and the stroke rule in RN; here it is a stroke only.

### 4. Fonts: PostScript names, fixed sizes
SwiftUI does not pick a weight from a family name for custom fonts. `DSPlatform.postScriptNames` maps each
Figma family + style to the PostScript name of a bundled face (all four are trial cuts; TODO in the file).
`DSPlatform.fontWeights` maps the Figma style names to `Font.Weight`. Sizes do not scale with Dynamic Type.

### 5. Letter spacing: `tracking = fontSize × percent / 100`
As ADR 003, but not rounded to two places: SwiftUI takes a `CGFloat`, so there is nothing to round for.

### 6. Line height: exact on iOS 26+, a gap for two styles before that
- **iOS 26+:** `lineHeight(.exact(points:))`. One line is exactly the token tall and wrapped lines sit exactly
  that far apart, for all 21 styles (`testRenderedLineHeightEqualsTheToken`).
- **iOS 18–25** (the deployment target is 18.0): SwiftUI can only add space between lines. `lineSpacing` gets
  `lineHeight − font line height`, with half of it padded above and below, which is exact wherever that is ≥ 0.
  **H1 (45/49, font 49.3) and N2 (27/29, font 30.9) are below their font's own line height**; when they wrap on
  iOS 18–25 they keep the font's natural pitch. Nothing is rounded to hide this.
- Open: raise the deployment target to 26, or accept the gap on older systems.

### 7. Shadows: `radius = blur / 2`; spread is dropped
`.shadow(color:radius:x:y:)` gets the Figma colour, opacity and offset verbatim and half the blur (Figma's blur
is the whole falloff, SwiftUI's radius about half of it, the same choice as RN's iOS mapping). **SwiftUI has no
spread.** Shadow/1–3 have 12 / 7 / 7 pt of it; it is not drawn and not faked with a larger radius or a second
shadow. There is no Android elevation table here.

### 8. Enforcement
- Build phase "Check design tokens": `generate.py --check` fails the build if a generated file differs.
- `Tests/TokenContractTests.swift`: every snapshot variable has a constant of the same value, the scales match
  the text styles and aliases, every style has a bundled face, rendered line height equals the token.
- `tools/lint/check_ds_rules.py`: no Tier 1, literals or hand-set type in `Sources/DesignSystem/Components`
  and in screens listed as adopted.

## Consequences

- A Figma change is: copy the snapshot, `python3 tools/tokens/generate.py`, review the diff.
- Shadows look slightly tighter than in Figma until SwiftUI can draw spread.
- Screens adopt the system one at a time; each adopted file is added to the lint's list.
