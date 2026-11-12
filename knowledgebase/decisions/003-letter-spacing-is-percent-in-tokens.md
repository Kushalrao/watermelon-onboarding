# ADR 003 — Letter spacing tokens are percent of font size

> Inherited from the React Native port (horse-design-system). The decision holds here unchanged; for the Swift names and the SwiftUI-specific choices see ADR 005.

**Status:** Accepted
**Date:** 2026-11-11

## Context

The numerical styles N1–N6 are designed with 9% tracking at six different sizes. Figma applies
a number variable bound to letter spacing as **pixels**, so one `font/kerning/num = 9` variable
rendered 9px on every size after binding, not 9%. React Native, like Figma's px mode, takes
absolute points.

## Decision

`font/kerning/*` variables are defined as **percent of font size** (`none = 0`, `num = 9`) and
documented as such in Figma. Code converts per style: `letterSpacing = round(fontSize × pct / 100, 2)`
via `trackingToPoints()`. The generator reads the bound variable and ignores the style's own px value.

In Figma the N1–N6 styles keep 9% set directly (unbound) so they render correctly; the zero
binding on all other styles is harmless because 0px = 0%.

## Consequences

- One variable expresses the design rule; points are derived at every size.
- Figma cannot express percent through a variable, so the N styles' letterSpacing stays unbound there. If Figma adds percent-unit variables, bind them and the generator needs no change.
- Any new tracked style must bind (or document) a `font/kerning/*` value in percent.
