#!/usr/bin/env python3
"""DS lint: token-tier contract for SwiftUI code.

    python3 tools/lint/check_ds_rules.py

Scans Sources/DesignSystem/Components and the screens that have adopted the design system (ADOPTED below).
Exits 1 on any violation. Ignore one line with:  // ds-lint-ignore: <rule>   A `// Gap:` comment on the line
exempts the literal rules (an off-scale value that has been raised and documented).
"""

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
COMPONENTS = os.path.join(ROOT, "Sources", "DesignSystem", "Components")
# Screens built only from the design system. Add a file here when it has been moved over.
ADOPTED = ["Sources/FixedDeposits.swift", "Sources/FixedDepositBank.swift", "Sources/FixedDepositBankV2.swift", "Sources/FixedDepositPlan.swift", "Sources/FixedDepositsHome.swift"]

RULES = [
    ("no_tier1", r"\b(FoundationTokens|SpacingPrimitives|ColorPrimitives|ShadowPrimitives)\.",
     "Use the Tier 2 scales (TypographyScale via DsText, SpacingScale, ColorScale, ShadowScale).", False),
    ("no_colour_literal", r"Color\(\s*(hex|red|white|hue|\.sRGB)|\bColor\.(black|white|gray|red|green|blue)\b|#[0-9A-Fa-f]{6}\b",
     "Colours come from ColorScale tokens. A colour with no token is a gap: stop and ask.", True),
    ("no_hand_set_type", r"\.(font|tracking|kerning|lineSpacing|fontWeight|bold)\(|FigmaFont\.",
     "Render text with DsText(variant:color:).", False),
    ("no_raw_text", r"(?<![A-Za-z_.])Text\(",
     "Render text with DsText(variant:color:).", False),
    ("no_raw_shadow", r"\.shadow\(",
     "Use Surface(shadow:) or dsShadow(_:).", False),
    ("no_raw_radius", r"cornerRadius:\s*[\d.]|\.cornerRadius\(",
     "Use Surface(radius:) or RadiusToken.<n>.value.", True),
    ("no_raw_line_width", r"lineWidth:\s*[\d.]",
     "The one stroke weight is BorderTokens.hairline, through Surface(border:) or Hairline.", True),
    ("no_raw_spacing", r"\.padding\((\.[a-zA-Z]+,\s*)?[\d.]+\)|\bspacing:\s*[1-9][\d.]*|Spacer\(minLength:\s*[1-9]",
     "Use Stack(gap:padding:) or SpacingScale.<token>. Off-scale values need a // Gap: comment.", True),
]
# Files that implement the rules rather than follow them
EXEMPT = {"DsText.swift": {"no_raw_text"}, "Stack.swift": {"no_raw_spacing"}}


def files():
    for name in sorted(os.listdir(COMPONENTS)):
        if name.endswith(".swift"):
            yield os.path.join(COMPONENTS, name)
    for rel in ADOPTED:
        yield os.path.join(ROOT, rel)


violations = 0
for path in files():
    exempt = EXEMPT.get(os.path.basename(path), set())
    for n, line in enumerate(open(path), 1):
        code = line.split("//")[0]
        for name, pattern, fix, gap_exempt in RULES:
            if name in exempt or f"ds-lint-ignore: {name}" in line or (gap_exempt and "// Gap:" in line):
                continue
            if re.search(pattern, code):
                print(f"{os.path.relpath(path, ROOT)}:{n}: {name}: {fix}\n    {line.strip()}")
                violations += 1

if violations:
    print(f"\n{violations} violation(s).")
    sys.exit(1)
print("DS lint: clean")
