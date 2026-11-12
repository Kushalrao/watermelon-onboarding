# Typography

> Load before setting any text in a component.

## The rule in one line

```swift
DsText("Supporting copy", variant: .p2, color: .contentPrimary)
```

Never build a `Font` from numbers. Never call `.font(…)`, `.tracking(…)`, `.kerning(…)`, `.lineSpacing(…)`,
`.fontWeight(…)` or `FigmaFont.*` in a component or an adopted screen. Pick a variant.

## Font families

| Family | Token | Use when |
|---|---|---|
| Reckless Standard | `font/family/Reckless` | Display and the two largest headings. Editorial, serif. |
| GT Walsheim | `font/family/GT Walsheim` | Everything else: headings H3–H6, paragraph, labels, numerals. |

Weights: Reckless Regular / Medium, GT Walsheim Rg / Md. `DSPlatform` maps them to `Font.Weight` `.regular` / `.medium` and to the PostScript name of each bundled face.

## Style catalogue

Names match the Figma text styles exactly. `variant` on `DsText` is the lower-camel form (`.d1` … `.n6`).

### Display — Reckless Medium
| Variant | Size / lh | Use when |
|---|---|---|
| `d1` | 67 / 79 | Hero statements, full-screen takeovers. One per screen at most. |
| `d2` | 53 / 66 | Secondary display moments. |

### Headings
| Variant | Font | Size / lh | Use when |
|---|---|---|---|
| `h1` | Reckless Regular | 45 / 49 | Page title. |
| `h2` | Reckless Regular | 35 / 51 | Section hero heading. |
| `h3` | GT Walsheim Md | 27 / 39 | Section heading, modal title. |
| `h4` | GT Walsheim Md | 23 / 35 | Sub-section title, card title. |
| `h5` | GT Walsheim Md | 19 / 27 | List item heading, prominent CTA label. |
| `h6` | GT Walsheim Md | 17 / 23 | Compact heading, inline action label. |

### Paragraph — GT Walsheim Rg
| Variant | Size / lh | Use when |
|---|---|---|
| `p1` | 23 / 35 | Lead paragraph, pull quote. |
| `p2` | 19 / 29 | Elevated body. |
| `p3` | 17 / 23 | Primary body copy, form values. |
| `p4` | 15 / 23 | Supporting body: subtitles, helper text, card descriptions. |
| `p5` | 13 / 21 | Fine print, terms, small helper paragraphs. |

### Labels — GT Walsheim Rg
| Variant | Size / lh | Use when |
|---|---|---|
| `lb1` | 13 / 21 | Category labels, timestamps, short metadata. |
| `lb2` | 12 / 19 | Overlines, legal copy, reference IDs. |

### Numericals — GT Walsheim, 9% tracking
| Variant | Weight | Size / lh | Use when |
|---|---|---|---|
| `n1` | Md | 35 / 43 | Hero figures: balances, totals. |
| `n2` | Md | 27 / 29 | Prominent figures in cards. |
| `n3` | Rg | 19 / 25 | Figures in lists and tables. |
| `n4` | Rg | 17 / 23 | Inline figures with body copy. |
| `n5` | Rg | 15 / 23 | Supporting figures. |
| `n6` | Rg | 12 / 17 | Micro figures, chart labels. |

Use `n*` for anything that is a number the user reads as a value. The 9% tracking keeps digits legible.

## Choosing between similar styles

- **`p3` vs `h6`** (both 17px): `p3` is read (body), `h6` is scanned (a label the user acts on or orients by).
- **`p5` vs `lb1`** (both 13/21): `lb1` annotates other content (timestamps, categories); `p5` is reading copy that happens to be small.
- **`h2` vs `h3`**: `h2` is the editorial serif for a section hero; `h3` is the working sans heading inside the content.

## What NOT to do

- `d*` styles inside UI chrome. They are brand moments.
- Two heading levels adjacent in one visual group.
- Any `n*` style for text that is not a number.
- `.bold()`, `.fontWeight(.bold)` or any weight the families do not ship.

## Shipping the fonts

Reckless Standard and GT Walsheim are trial fonts. The four faces the scale needs are bundled in
`Resources/Fonts` and listed under `UIAppFonts` in `project.yml`:

| Figma family · style | File | PostScript name |
|---|---|---|
| Reckless Standard S-TRIAL · Regular | `RecklessStandardS-TRIAL-Regular.otf` | `RecklessStandardS-TRIAL-Regular` |
| Reckless Standard S-TRIAL · Medium | `RecklessStandardS-TRIAL-Medium.otf` | `RecklessStandardS-TRIAL-Medium` |
| GT Walsheim Trial · Rg | `GT-Walsheim-Regular-Trial.otf` | `GTWalsheimTrial-Rg` |
| GT Walsheim Trial · Md | `GT-Walsheim-Medium-Trial.otf` | `GTWalsheimTrial-Md` |

The table lives in `DSPlatform.postScriptNames`. To license: replace the files, update the names there.
A style whose face is missing fails `TokenContractTests.testEveryStyleHasABundledFaceAndWeight`.

## SwiftUI implementation notes (ADR 005)

- **Line height.** On iOS 26+ `DsText` applies `lineHeight(.exact(points:))`, so one line of any variant is exactly
  its Figma line height tall and wrapped lines sit exactly that far apart (tested). Before iOS 26 SwiftUI can only
  add space between lines: every style is still exact except `h1` (45/49) and `n2` (27/29), whose line height is
  below the font's own; those two keep the font's natural pitch when they wrap. A documented gap, not rounded.
- **Letter spacing** is percent in Figma and points in SwiftUI: `tracking = fontSize × pct / 100`
  (`DSPlatform.trackingPoints`, ADR 003), unrounded.
- **Sizes are fixed** (no Dynamic Type scaling), as the design states them.
- Colour is never part of a variant. Pass `color` on `DsText`.
