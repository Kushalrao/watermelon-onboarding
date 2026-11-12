# DsText

The only way to render text. `Sources/DesignSystem/Components/DsText.swift`

```swift
DsText("Fixed Deposits", variant: .h1)
DsText("7.85%", variant: .n3, color: .statusSuccessText)
```

| Parameter | Type | Default | What it is |
|---|---|---|---|
| (first) | `String` | required | The text, rendered verbatim. |
| `variant` | `TypographyVariant` | required | The Figma text style: `.d1` … `.n6`. |
| `color` | `TextColor` | `.contentPrimary` | A content / `*Text` colour token. |

**Tokens used:** `TypographyScale.<variant>` (family, weight, size, line height, tracking), `ColorScale` via `TextColor`.

**Allowed around it:** layout and behaviour modifiers (`fixedSize`, `frame`, `multilineTextAlignment`, `lineLimit`,
`contentTransition`, accessibility). **Not allowed:** `.font`, `.tracking`, `.lineSpacing`, `.foregroundStyle`.

**Gaps:** before iOS 26, wrapped `h1` and `n2` keep the font's natural line pitch (ADR 005). No Dynamic Type.
No attributed / mixed-style text yet.
