# MutualFundsPrototype — Claude Code context

SwiftUI iOS prototype. Its design system is the **Horse Design System** (Figma `TWgGkus0FyMoym2H7LNnwD`),
ported from the React Native repo at `/Users/kushal/horse-design-system`. Every token value is generated from
the Figma snapshot, never typed in.

## Layout

```
tools/tokens/figma-variables.json     copy of the Figma snapshot (collections, text styles, shadow styles)
tools/tokens/generate.py              snapshot → Sources/DesignSystem/Tokens/Generated/*
tools/lint/check_ds_rules.py          token-tier lint for components and adopted screens
Sources/DesignSystem/Tokens/Generated Tier 1 + generated Tier 2 (do not edit)
Sources/DesignSystem/Tokens/          SpacingScale, ShadowScale, DSPlatform (hand-authored)
Sources/DesignSystem/Components/      DsText, Stack, Surface, Hairline
Tests/TokenContractTests.swift        snapshot ↔ code contract tests
knowledgebase/foundations/            typography, spacing, containers, color, quality (always-on rules)
knowledgebase/components/             one doc per component
knowledgebase/decisions/              ADRs; 005 is the SwiftUI port
```

## Always-on rules: read before building or restyling any screen or component

Read `knowledgebase/foundations/quality.md`, `typography.md`, `spacing.md`, `containers.md` and `color.md` first.
New screens, and screens being updated, are built from the design system. Screens already moved over are
listed in `ADOPTED` in `tools/lint/check_ds_rules.py`; add a screen there when it is moved.

### Typography
- **Always** render text with `DsText(_:variant:color:)` and a variant from `TypographyScale` (`.d1` … `.n6`).
- **Never** call `.font`, `.tracking`, `.kerning`, `.lineSpacing`, `.fontWeight` or `FigmaFont.*`, and never use a bare `Text`.
- **Never** reference `FoundationTokens`. It is Tier 1.

### Spacing
- **Always** use `Stack`'s `gap` / `padding`, or `SpacingScale.*` (`spaceMd`, `spaceXl`, …) where `Stack` doesn't fit.
- **Never** write a raw number in `.padding(…)` or `spacing:`. Off-scale values need a `// Gap:` comment and the user's say-so.
- **Never** reference `SpacingPrimitives`. No arithmetic on tokens.
- Sizes (an icon's frame, a 44 pt tap target) are dimensions, not spacing, and stay numbers.

### Containers
- **Always** build cards, panels and pills with `Surface` (`surface`, `radius` / `shape`, `border`, `shadow`); separators with `Hairline`.
- **Never** write `cornerRadius:` numbers, `lineWidth:` numbers or `.shadow(…)`. The only stroke weight is `BorderTokens.hairline`.

### Colour
- **Always** use `ColorScale` tokens: fills through `Surface(surface:)`, strokes through `border:` / `Hairline`, text through `DsText(color:)`, icons and drawn shapes with `ColorScale.<token>` directly.
- **Never** write `Color(hex:)`, `Color.black`, `.white` or any colour literal, and never reference `ColorPrimitives`.

### Gaps
- A design value with no token is a **gap**: stop and ask. Never round to the nearest token.

## Token tiers (mirror Figma)

| Tier | Code | Figma | Who edits |
|---|---|---|---|
| 1 primitives | `FoundationTokens`, `SpacingPrimitives`, `RadiusToken`, `BorderTokens`, `ColorPrimitives`, `ShadowPrimitives` (generated) | `Typography`, `Container styles`, `Colors primitives` collections; `Shadow/*` effect styles | nobody: regenerate |
| 2 semantics | `TypographyScale`, `ColorScale` (generated); `SpacingScale`, `ShadowScale` (hand-authored, same as the RN port) | text styles D1–N6; `Color Semantics` | pipeline / humans |
| platform | `DSPlatform` (fonts, tracking, line height, shadow mapping) | none | humans, with an ADR |

## Commands

```bash
python3 tools/tokens/generate.py            # regenerate from the snapshot
python3 tools/tokens/generate.py --check    # drift guard (also a build phase)
python3 tools/lint/check_ds_rules.py        # token-tier lint
xcodegen generate -q                        # after adding or removing files
xcodebuild -project MutualFundsPrototype.xcodeproj -scheme MutualFundsPrototype \
  -destination 'id=<simulator udid>' -derivedDataPath build test -only-testing:MutualFundsPrototypeTests
```

## Trust levels

| Level | Examples |
|---|---|
| Auto | regenerate tokens from a new snapshot, tests, doc fixes |
| Ask first | new component or variant, a new `SpacingScale` alias, restyling a screen that wasn't asked for |
| Suggest only | changing a Tier 2 mapping, anything in `DSPlatform`, resolving a gap |
