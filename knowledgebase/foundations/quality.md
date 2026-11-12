# Component quality obligations

> Load before authoring or reviewing any component in `Sources/DesignSystem/Components`, or adopting the system in a screen. Every box must be checked before a component is done.

## Figma measurement (when building from a Figma node)

- [ ] Every dimension, padding and gap comes from the Figma node data (MCP response), never from a screenshot or arithmetic on other nodes.
- [ ] Every gap between siblings is traced to the `itemSpacing` of its **direct parent** frame.
- [ ] `layoutMode` decides `Stack(direction:)`; `layoutSizingHorizontal/Vertical` decides `frame(maxWidth: .infinity)` vs fixed vs hug (`fixedSize`). Never guessed from the picture.
- [ ] `primaryAxisAlignItems` / `counterAxisAlignItems` map to `Spacer`s / `Stack(alignment:)`. Never defaulted.
- [ ] Stroke weight is `BorderTokens.hairline` through `Surface(border:)` or `Hairline`, never a bare `lineWidth`.
- [ ] Text properties come from the named text style, never from raw `fontSize`/`fontWeight` fields on the node.
- [ ] Every spacing value is classified EXACT / NEAREST / NONE before a token is chosen. NEAREST and NONE are gaps, not matches.
- [ ] All designed states (pressed, disabled, loading, error, empty) are implemented or listed as out-of-scope gaps.

## Token usage

- [ ] Zero hand-set typography properties; text goes through `DsText` with a `variant`.
- [ ] Zero raw spacing numbers; layout goes through `Stack` or `SpacingScale.*`.
- [ ] Zero references to Tier 1: `FoundationTokens`, `SpacingPrimitives`, `ColorPrimitives`, `ShadowPrimitives`.
- [ ] Zero colour literals, corner-radius literals, line widths or `.shadow(…)` calls.
- [ ] No gap silently resolved: every unmatched value raised with the user before coding.
- [ ] `python3 tools/lint/check_ds_rules.py` passes.

## API contract

- [ ] Component and every prop have a `///` doc comment: what it is, when to reach for it.
- [ ] Variants and states are enums, never `Bool` flags for multi-state axes.
- [ ] Defaults declared on every optional prop.
- [ ] No generically named props (`data`, `value`, `config`).
- [ ] A component owns its properties: callers don't re-apply font, fill, radius or shadow modifiers around it.

## Tests

- [ ] Behaviour test for every callback prop: fires when set, does nothing when absent.
- [ ] Token-wiring test: what's rendered equals the scale entry (see `testRenderedLineHeightEqualsTheToken`).
- [ ] The app builds (the build runs the token drift check) and `MutualFundsPrototypeTests` pass.

## Accessibility

- [ ] Interactive elements have `accessibilityAddTraits` and `accessibilityLabel` where the visual label is missing.
- [ ] Tappable targets are at least 44×44.
- [ ] State is never conveyed by colour alone.

## Knowledgebase

- [ ] `knowledgebase/components/<name>.md` exists: API table, tokens used, gaps, examples.
- [ ] Any non-obvious constraint captured in `knowledgebase/decisions/`.
