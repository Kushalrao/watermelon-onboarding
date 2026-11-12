# Spacing

> Load before writing any layout code.

## The rule in one line

Every gap, padding and margin is a `SpacingScale` token, usually through `Stack`. No raw numbers, no arithmetic.

```swift
Stack(gap: .spaceMd, paddingHorizontal: .space2xl) { … }
```

Where `Stack` doesn't fit (one-sided padding, a `safeAreaInset`), use the scale directly:
`.padding(.leading, SpacingScale.spaceXl)`.

## The scale

| Token | Value | Use when |
|---|---|---|
| `spaceNone` | 0 | Explicitly remove default padding. |
| `space2xs` | 2 | Icon-to-badge nudge, hairline gap, pixel-level alignment. |
| `spaceXs` | 5 | Icon-to-label gap, tight chip internal padding. |
| `spaceSm` | 7 | Internal padding for small components: tag, badge, chip. |
| `spaceMd` | 9 | Standard gap between sibling elements. |
| `spaceMdLg` | 13 | Relaxed card inset, section with more visual weight. |
| `spaceLg` | 15 | Standard component vertical padding: buttons, inputs. |
| `spaceXl` | 21 | Card internal padding, section inset. |
| `space2xl` | 25 | Page horizontal margin. |
| `space3xl` | 29 | Button horizontal padding, large section leading space. |
| `space4xl` | 35 | Between major page sections. |
| `space5xl` | 39 | Large list item height, section separator. |
| `space6xl` | 47 | Bottom sheet top padding, modal inset. |
| `space7xl` | 65 | Navigation bar height, fixed bottom area. |
| `space8xl` | 75 | Tab bar + content offset. |
| `space9xl` | 95 | Scroll offset for sticky headers. |
| `space10xl` | 115 | Full-bleed hero image height, large illustration area. |

The values are the Figma `Container styles › Spacing/<n>` variables. The names are code-side
semantics (hand-authored) until the semantic layer is mirrored into Figma.

## Choosing between adjacent tokens

- **`spaceMd` (9) vs `spaceLg` (15)**: `spaceMd` is a gap *between* elements of one group (icon→label, title→subtitle); `spaceLg` is padding *inside* a component boundary.
- **`spaceXl` (21) vs `space2xl` (25)**: card internal padding vs page-level margin.
- **`spaceSm` (7) vs `spaceXs` (5)**: small-component internals; `spaceXs` when the component is very compact (tag, badge).

## Composition recipes

```swift
// Icon + label on one line
Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) { … }

// Component internal padding (button, input)
Stack(paddingHorizontal: .space3xl, paddingVertical: .spaceLg) { … }

// Vertical rhythm: label → helper tightly grouped, group → next group breathes
Stack(gap: .spaceMd) {
    Stack(gap: .space2xs) {
        DsText("Label", variant: .lb1)
        DsText("Helper", variant: .p5)
    }
    NextSection()
}

// Card
Stack(padding: .spaceXl) { … }

// Page margins: once, at the page level
Stack(paddingHorizontal: .space2xl) { … }
```

## Rules

- Zero hardcoded numbers in `.padding(…)`, `spacing:` or `Spacer(minLength:)` (zero aside). The DS lint flags them.
- `VStack` / `HStack` with a numeric `spacing:` is a raw number: use `Stack`.
- A value that is not on the scale is a **gap**: raw literal, `// Gap: Figma N pt, no token` comment, and a note in the component doc. Never round to the nearest token.
- No arithmetic on tokens (`SpacingScale.spaceMd + 4`).
- Never reference `SpacingPrimitives` in a component or screen.
- Sizes are not spacing: an icon's `frame(width:height:)` or a 44 pt tap target is a dimension and stays a number.
