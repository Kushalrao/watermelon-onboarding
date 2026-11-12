# ADR 001 — Three token tiers that mirror Figma, generated where Figma is the source

> Inherited from the React Native port (horse-design-system). The decision holds here unchanged; for the Swift names and the SwiftUI-specific choices see ADR 005.

**Status:** Accepted
**Date:** 2026-11-11

## Context

The Figma file Horse Design System holds the foundations as variable collections (`Typography`,
`Container styles`) and text styles bound to those variables. Code must not restate those values
by hand: hand-typed tokens drift, and an agent cannot tell which copy is right (failure mode FM1
in the agentic-DS research).

## Decision

Three tiers, each holding references to the tier below:

| Tier | Code | Source | Generated? |
|---|---|---|---|
| 1 Primitives | `Foundation`, `SpacingPrimitives` | Figma variable collections | yes, from the committed snapshot |
| 2 Semantics | `TypographyScale` | Figma text styles (their variable bindings) | yes |
| 2 Semantics | `SpacingScale` | no Figma counterpart yet | hand-authored, references Tier 1 only |
| 3 Component | per-component token files | component collections (none yet) | hand-authored |

Components import Tier 2 only. The generator refuses a text style with an unbound property, so
the alias chain is complete by construction. `npm run tokens:check` fails CI when generated files
and snapshot disagree.

## Consequences

- A Figma change is a snapshot export + `npm run tokens` + review of the diff. Nothing is edited in `generated/`.
- `SpacingScale` moves to generated the day Figma gets a semantic spacing collection; until then it is the one hand-maintained Tier 2 file.
- `@horse/tokens` has no runtime dependency on react-native, so the pipeline and contract tests run in plain Node.
