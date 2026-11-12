# Color

> Load before applying any colour in a component.

## The rule in one line

```swift
Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle) {
    DsText("…", variant: .p3, color: .contentSecondary)
}
```

Components use `ColorScale` (Tier 2, generated from the Figma `Color Semantics` collection,
Light mode). **Never** reference `ColorPrimitives` in a component or screen and never write `Color(hex:)`,
`Color.black`, `.white` or `Color(red:…)` there; the DS lint rejects them.

Three generated enums say where a token may go: `SurfaceFill` (`Surface(surface:)`), `BorderColor`
(`Surface(border:)`, `Hairline`), `TextColor` (`DsText(color:)`). For an icon or a drawn shape, use the
token's colour directly: `.foregroundStyle(ColorScale.contentSecondary)`.

## Semantic tokens — `ColorScale`

Names are the Figma paths in lower-camel: `content/on-color` → `contentOnColor`,
`status/success/text` → `statusSuccessText`. Contrast ratios are against `surface/base` unless noted.

### Surface (fills)

| Token | Primitive | Shadow | Use when |
|---|---|---|---|
| `surfaceBase` | `ivory/50` `#FDFCFC` | none | The page background. Everything sits on this. |
| `surfaceWidget` | `static/white` | `shadow1` | A widget or card on the base. |
| `surfaceSunken1` | `ivory/100` `#F5F3F2` | none | One level sunk into its parent surface. |
| `surfaceSunken2` | `ivory/200` `#EDEBEA` | none | Two levels sunk. |
| `surfaceRaised` | `static/white` | `shadow1` | A raised element inside a widget. |
| `surfaceFocus` | `static/white` | `shadow2` | A focused or highlighted raised element. |
| `surfaceInverse` | `static/black` | none | Inverse surface; pair with `contentInverse`. |

**Depth model:** base → widget → sunken / raised inside the widget. `Surface` applies the designed
shadow automatically; pass `shadow` to override.

### Content (text and icons)

| Token | Primitive | Contrast | Use when |
|---|---|---|---|
| `contentPrimary` | `stone/900` | 14.99:1 | Default. Start here. |
| `contentSecondary` | `stone/700` | 6.13:1 | Supporting text, subtitles, helper lines. |
| `contentTertiary` | `stone/600` | 4.56:1 | De-emphasised metadata. |
| `contentQuaternary` | `stone/500` | 3.41:1 | Decorative only — **never body text**. |
| `contentDisabled` | `stone/400` | — | Disabled state. |
| `contentInverse` | `stone/50` | — | On `surfaceInverse`. |
| `contentOnColor` | `static/white` | per fill | On solid brand / status fills. Audit each: fails on `statusSuccessSolid` for small text. |

### Border (strokes, always `BorderTokens.hairline` wide)

| Token | Primitive | Use when |
|---|---|---|
| `borderSubtle` | `ivory/300` `#EBE9E8` | Widget outlines, dividers. |
| `borderDefault` | `ivory/400` `#DEDBD9` | Control borders. |
| `borderStrong` | `stone/500` | Emphasised border, 3.41:1 vs base. |
| `borderDisabled` | `ivory/300` | Disabled state. |

### Brand and secondary

| Token | Primitive | Use when |
|---|---|---|
| `brandSolid` | `brand/600` | Primary CTA fill. White ink 5.06:1. One per screen. |
| `brandSolidHover` | `brand/700` | Hover / pressed state of `brandSolid`. |
| `brandSubtle` | `brand/50` | Tinted brand surface. |
| `brandText` | `brand/700` | Brand-coloured text, 5.79:1 on `brandSubtle`. |
| `brandBorder` | `brand/300` | Brand outline. |
| `secondarySolid` | `secondary/600` | Secondary brand fill. |
| `secondarySubtle` | `secondary/50` | Tinted secondary surface. |

### Status

Each of `success`, `error`, `warning` has the same four roles: `solid` (600), `subtle` (50),
`text` (700, ≥ 5.3:1 on its subtle), `border` (300).

| Token | Primitive | Note |
|---|---|---|
| `statusSuccessSolid` | `utility-green/600` | White ink 4.26:1 — large text / UI only. |
| `statusSuccessSubtle` / `Text` / `Border` | `utility-green/50` / `700` / `300` | |
| `statusErrorSolid` | `utility-red/600` | White ink 5.07:1. |
| `statusErrorSubtle` / `Text` / `Border` | `utility-red/50` / `700` / `300` | |
| `statusWarningSolid` | `utility-yellow/600` | White ink 4.56:1. |
| `statusWarningSubtle` / `Text` / `Border` | `utility-yellow/50` / `700` / `300` | |

## Pairing rules

| Fill | Text / icon | Border |
|---|---|---|
| `surfaceBase`, `surfaceWidget`, sunken, raised | `contentPrimary` … `contentTertiary` | `borderSubtle` / `borderDefault` |
| `surfaceInverse` | `contentInverse` | — |
| `brandSolid`, `secondarySolid`, `status*Solid` | `contentOnColor` | — |
| `brandSubtle` | `brandText` | `brandBorder` |
| `status*Subtle` | `status*Text` | `status*Border` |

State is never conveyed by colour alone; pair with an icon or text.

## Primitives — `ColorPrimitives` (Tier 1, never in components)

Twelve ramps of ten steps, 900 (darkest) → 50 (lightest), built in OKLCH with even lightness
steps: `brand`, `secondary`, `accent-lavender`, `accent-pink`, `accent-lime`, `accent-yellow`,
`blue`, `stone` (warm neutral for content), `ivory` (warm neutral for surfaces and borders),
`utility-green`, `utility-red`, `utility-yellow`; plus `static/white` and `static/black`.
The accents and `blue` have no semantic tokens yet; a design using them is a gap.
There is also no border or disabled-content token for use on `surfaceInverse`.
The canvas `gray-warm` ramp is not in the collection.

## Dark mode

Not modelled yet. It arrives as a second mode on the Figma collections; the generator then emits
a second table and components keep their token names. Until then adopted screens pin `.preferredColorScheme(.light)`.
