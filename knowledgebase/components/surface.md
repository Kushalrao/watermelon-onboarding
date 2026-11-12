# Surface and Hairline

A container with fill, outline, hairline border and shadow, each a token.
`Sources/DesignSystem/Components/Surface.swift`, `Hairline.swift`

```swift
Surface(surface: .surfaceWidget, radius: .radius23) { … }                           // a card, with Shadow/1
Surface(surface: .surfaceRaised, shape: .capsule, shadow: .token(.shadow3)) { … }   // a floating pill
Surface(shape: .capsule, border: .borderStrong) { … }                               // an outline only
Hairline(.borderSubtle)                                                             // a separator
```

| Parameter | Type | Default | What it is |
|---|---|---|---|
| `surface` | `SurfaceFill?` | `nil` | Fill token. `surfaceWidget` / `surfaceRaised` carry `shadow1`, `surfaceFocus` `shadow2`. |
| `radius` | `RadiusToken` | — | Rounded outline (shorthand for `shape: .rounded(…)`). |
| `shape` | `SurfaceShape` | `.rectangle` | `.rectangle`, `.rounded(RadiusToken)`, `.capsule`. |
| `border` | `BorderColor?` | `nil` | Draws the hairline in this stroke token. |
| `shadow` | `.designed` / `.none` / `.token(ShadowToken)` | `.designed` | The surface's designed shadow, none, or an override. |

`Hairline(_ color: BorderColor = .borderSubtle, axis: .horizontal / .vertical)`.

**Tokens used:** `ColorScale` via `SurfaceFill` / `BorderColor`, `RadiusToken`, `BorderTokens.hairline`, `ShadowScale`.

**Gaps:** Figma's shadow spread is not drawn (ADR 005). No pressed / disabled states. No shadow without a fill.
