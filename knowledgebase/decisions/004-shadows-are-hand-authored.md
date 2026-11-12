# ADR 004 — Shadows: parameters generated from Figma effect styles, platform mapping hand-authored

> Inherited from the React Native port (horse-design-system). The decision holds here unchanged; for the Swift names and the SwiftUI-specific choices see ADR 005.

**Status:** Accepted
**Date:** 2026-11-11 (revised the same day once the effect styles existed)

## Context

The Foundations page defines three drop shadows. Figma variables have no effect type, so shadows
cannot join the `Container styles` collection the way radius and border width did. Figma's
reusable construct for shadows is the effect style; `Shadow/1`, `Shadow/2` and `Shadow/3` now
exist in the file and are applied to the sample cards.

React Native has no `spread`, and Android expresses depth only through `elevation`.

## Decision

- The snapshot export carries local effect styles. `generate.mjs` emits `ShadowPrimitives`
  (colour, opacity, offset, blur, spread) verbatim, one entry per style, and refuses a style that
  does not hold exactly one drop shadow.
- `ShadowScale` (hand-authored) derives the platform styles: iOS `shadowRadius = blur / 2`,
  offset and opacity verbatim; Android `elevation` 2 / 4 / 8 chosen per level. It references
  `ShadowPrimitives` only, never literals.

## Consequences

- A shadow change in Figma is a snapshot export + regenerate; only a new *level* needs a human to pick its Android elevation (the `satisfies` clause fails typecheck until it is added).
- `spread` is lost on both platforms and `elevation` is a visual approximation. Both are documented gaps, not matches.
- Components get shadows only through `Surface` or `shadowStyle()`; the DS lint rejects hand-set `shadowRadius`, `shadowOpacity` and `elevation`.
