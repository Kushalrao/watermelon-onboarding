# Container styles

> Load before building any card, panel, sheet or divider. Covers corner radius, borders, separators and elevation. Spacing is in `spacing.md`.

## The rule in one line

```swift
Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle) { … }
Surface(surface: .surfaceRaised, shape: .capsule, shadow: .token(.shadow3)) { … }   // a floating pill
Hairline(.borderSubtle)                                                             // a separator
```

Never write `.cornerRadius(…)`, `RoundedRectangle(cornerRadius: <number>)`, `lineWidth: <number>` or
`.shadow(…)` by hand in a component or an adopted screen.

## Corner radius — `RadiusTokens`

| Token | Value | Use when |
|---|---|---|
| `radius15` | 15 | Small controls: chips, inputs, small buttons. |
| `radius23` | 23 | Cards and panels — the default surface radius (every sample card on the Foundations page). |
| `radius27` | 27 | Larger containers, bottom sheets. |
| `radius35` | 35 | Hero containers, full-bleed media. |

Figma: `Container styles › Radius/<n>`. A radius not on this list is a gap.

## Borders and separators — `BorderTokens`

| Token | Value | Use when |
|---|---|---|
| `hairline` | 0.7 | Every border and separator in the system. There is one stroke weight. |

Figma: `Container styles › Border/hairline`. Border colours are `ColorScale.border*` tokens (`color.md`);
`Surface(border:)` and `Hairline` take them as `BorderColor`.

## Elevation — `ShadowScale`

Figma cannot store shadows as variables, so they are the effect styles `Shadow/1`–`Shadow/3`.
Their parameters are generated into `ShadowPrimitives`; `ShadowScale` adds the platform mapping (ADR 004).

| Token | Figma | Use when |
|---|---|---|
| `shadow1` | blur 100, y 4, spread 12, 5 % | Resting surface lift. The default for cards. |
| `shadow2` | blur 97, y 4, spread 7, 7 % | Raised surface, hover/active emphasis. |
| `shadow3` | blur 85, y 2, spread 7, 11 % | Strongest lift: floating action surfaces, the dark card. |

SwiftUI notes (ADR 005): `.shadow(color:radius:x:y:)` gets the colour and opacity verbatim, the offset
verbatim and `radius = blur / 2`. **`spread` has no SwiftUI equivalent and is dropped, not approximated**, so each
shadow reaches a little less far than in Figma (12 / 7 / 7 pt). A documented gap.

## Shapes

`Surface` takes `radius:` (a `RadiusToken`) or `shape:` (`.rectangle`, `.rounded(token)`, `.capsule`). A capsule is
a shape, not a radius: it has no value, so it needs no token.

## Rules

- One radius per container, from `RadiusTokens`.
- One border weight: `BorderTokens.hairline`. Never `lineWidth: 1`.
- Shadows only through `Surface` (or `dsShadow(_:)` for a shape `Surface` can't be).
- `Surface` owns fill, outline, border and shadow. Don't add `.background`, `.clipShape` or `.shadow` around it.
