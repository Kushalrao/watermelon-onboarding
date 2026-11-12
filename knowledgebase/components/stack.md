# Stack

Auto-layout container: gap and padding as spacing tokens. `Sources/DesignSystem/Components/Stack.swift`

```swift
Stack(gap: .spaceMd, padding: .spaceXl) { … }
Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) { … }
```

| Parameter | Type | Default | What it is |
|---|---|---|---|
| `direction` | `.vertical` / `.horizontal` | `.vertical` | Column or row. |
| `gap` | `SpacingToken` | `.spaceNone` | Space between children. |
| `padding` | `SpacingToken` | `.spaceNone` | Padding on all sides. |
| `paddingHorizontal` | `SpacingToken?` | `nil` | Overrides `padding` left and right. |
| `paddingVertical` | `SpacingToken?` | `nil` | Overrides `padding` top and bottom. |
| `alignment` | `Alignment` | `.topLeading` | Cross-axis alignment: its horizontal part for a column, vertical part for a row. |

**Tokens used:** `SpacingScale` via `SpacingToken`.

**Gaps:** no one-sided padding; use `.padding(.leading, SpacingScale.<token>)` for that.
