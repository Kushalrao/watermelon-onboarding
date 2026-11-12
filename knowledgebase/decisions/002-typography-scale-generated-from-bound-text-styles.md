# ADR 002 — TypographyScale is generated from Figma text styles, not hand-authored

> Inherited from the React Native port (horse-design-system). The decision holds here unchanged; for the Swift names and the SwiftUI-specific choices see ADR 005.

**Status:** Accepted
**Date:** 2026-11-11

## Context

The Flutter predecessor hand-authored its typography scale because its text styles were not
bound to variables and needed Flutter-specific fields (`leadingDistribution`, `decoration`).
Here, every Figma text style (D1–N6) has fontFamily, fontStyle, fontSize, lineHeight and
letterSpacing bound to `Typography` variables, and the exported snapshot carries the bound
variable *names*.

## Decision

Generate `TypographyScale` from the text styles: one entry per style, named in lower-camel
(`D1 → d1`, `Lb2 → lb2`), each property a reference to the Foundation constant the Figma
binding points at. The React-Native-specific conversion (weight name → numeric weight,
family → platform font name, percent → points) lives in the hand-authored `fontResolution.ts`,
which the generated file calls through `textStyle()`.

## Consequences

- Renaming or re-binding a style in Figma is the only way to change the scale. The generator aborts on any unbound property, naming the style.
- The generated file is still a pure alias chain and readable; the contract test asserts each entry's size and line height equal the snapshot's.
- Figma styles named outside the `D/H/P/Lb/N` families would still generate; naming discipline lives in Figma.
