#!/usr/bin/env python3
"""Token pipeline: Figma snapshot -> Tier 1 Swift primitives + the generated Tier 2 scales.

    python3 tools/tokens/generate.py           regenerate Sources/DesignSystem/Tokens/Generated/*
    python3 tools/tokens/generate.py --check   exit 1 if the generated files differ from the snapshot (drift-guard;
                                               also runs as a pre-build phase, so a stale file fails the build)

Input: tools/tokens/figma-variables.json, a copy of the Horse Design System snapshot
(/Users/kushal/horse-design-system/tools/tokens/figma-variables.json). It is the same file the React Native
generator reads, so both ports stay in lockstep; refresh it by copying the new export over it (README.md).

Tier structure mirrors Figma and the RN port (ADR 001):
    Typography collection        -> FoundationTokens   (families, weights, sizes, line heights, kerning %)
    Container styles collection  -> SpacingPrimitives, RadiusToken, BorderTokens
    Colors primitives collection -> ColorPrimitives
    Shadow/* effect styles       -> ShadowPrimitives
    Text styles (bound vars)     -> TypographyScale    (each style references FoundationTokens constants)
    Color Semantics collection   -> ColorScale         (each token references a ColorPrimitives constant)
Nothing here types a value: every number, string and colour comes from the snapshot.
"""

import hashlib
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SNAPSHOT = os.path.join(ROOT, "tools", "tokens", "figma-variables.json")
OUT_DIR = os.path.join(ROOT, "Sources", "DesignSystem", "Tokens", "Generated")
CHECK = "--check" in sys.argv


def header(source, digest):
    return (
        f"// GENERATED — do not edit. Source: Figma › {source}.\n"
        f"// Regenerate with `python3 tools/tokens/generate.py`. Snapshot sha256: {digest}\n"
    )


# ─── Naming (same rules as the RN generator, so names match across ports) ────────────────────────

def camel(parts):
    segs = [s for p in parts for s in re.split(r"[-_\s]+", str(p)) if s]
    return "".join(s.lower() if i == 0 else s[0].upper() + s[1:].lower() for i, s in enumerate(segs))


def const_name(variable_path):
    """font/lineheight/79 -> fontLineheight79, Spacing/21 -> spacing21, brand/500 -> brand500"""
    return camel(variable_path.split("/"))


def style_key(name):
    """D1 -> d1, Lb2 -> lb2"""
    return name[0].lower() + name[1:]


def swift_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def num(v):
    """A snapshot number as a Swift CGFloat literal, unchanged (12 -> 12, 0.7 -> 0.7)"""
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise SystemExit(f"expected a number, got {v!r}")
    return str(int(v)) if float(v).is_integer() else repr(round(v, 4))


def doc(text, indent="    "):
    return f"{indent}/// {text}\n" if text else ""


def hex_of(var):
    h = var.get("hex")
    if not h:
        v = var["value"]
        h = "#" + "".join(f"{round(v[c] * 255):02X}" for c in "rgb")
    if not re.fullmatch(r"#[0-9A-Fa-f]{6}", h):
        raise SystemExit(f"{var['name']}: colour {h!r} is not #RRGGBB")
    return h[1:].upper()


def alpha_of(var):
    v = var["value"]
    return v.get("a", 1) if isinstance(v, dict) else 1


# ─── Generators ───────────────────────────────────────────────────────────────────────────────────

def gen_foundation(typo, digest):
    groups = {"family": [], "weight": [], "size": [], "lineheight": [], "kerning": []}
    for v in typo["variables"]:
        group = v["name"].split("/")[1]
        if group not in groups:
            raise SystemExit(f"Typography variable {v['name']} is in an unknown group '{group}'")
        groups[group].append(v)
    out = []
    sections = [
        ("Font families (Figma family names; DSPlatform maps them to the PostScript names the app ships)", "family", False),
        ("Font weights (the Figma style names each family exposes; DSPlatform maps them to Font.Weight)", "weight", False),
        ("Font sizes, pt", "size", True),
        ("Line heights, pt", "lineheight", True),
        ("Letter spacing, PERCENT of font size (ADR 003); DSPlatform converts to points", "kerning", True),
    ]
    strings, numbers = [], []
    for title, key, numeric in sections:
        vs = sorted(groups[key], key=lambda v: v["value"]) if numeric else groups[key]
        out.append(f"    // ── {title} ──")
        for v in vs:
            n = const_name(v["name"])
            out.append(doc(v.get("description")) .rstrip("\n")) if v.get("description") else None
            if numeric:
                out.append(f"    static let {n}: CGFloat = {num(v['value'])}")
                numbers.append(f"        {swift_str(v['name'])}: {n},")
            else:
                out.append(f"    static let {n} = {swift_str(v['value'])}")
                strings.append(f"        {swift_str(v['name'])}: {n},")
        out.append("")
    return f"""{header('Typography collection', digest)}
import CoreGraphics

/// Tier 1: raw typography primitives. Never reference this in a component or screen; use `TypographyScale`
/// through `DsText`. (Named FoundationTokens, not Foundation, so it can't shadow Apple's Foundation module; ADR 005.)
enum FoundationTokens {{
{chr(10).join(out)}
    /// Every string constant by its Figma variable name, for the contract tests
    static let stringsByFigmaName: [String: String] = [
{chr(10).join(strings)}
    ]

    /// Every numeric constant by its Figma variable name, for the contract tests
    static let numbersByFigmaName: [String: CGFloat] = [
{chr(10).join(numbers)}
    ]
}}
"""


def gen_spacing(containers, digest):
    spacing = sorted((v for v in containers["variables"] if v["name"].startswith("Spacing/")), key=lambda v: v["value"])
    lines = [f"    static let {const_name(v['name'])}: CGFloat = {num(v['value'])}" for v in spacing]
    table = [f"        {swift_str(v['name'])}: {const_name(v['name'])}," for v in spacing]
    return f"""{header('Container styles collection', digest)}
import CoreGraphics

/// Tier 1: raw spacing steps in points. Never reference this in a component or screen; use `SpacingScale`
/// (Tier 2) or `Stack`'s gap and padding.
enum SpacingPrimitives {{
{chr(10).join(lines)}

    /// Every constant by its Figma variable name, for the contract tests
    static let byFigmaName: [String: CGFloat] = [
{chr(10).join(table)}
    ]
}}
"""


def gen_containers(containers, digest):
    def group(prefix):
        return sorted((v for v in containers["variables"] if v["name"].startswith(prefix)), key=lambda v: v["value"])

    # Figma stores 0.7 as a float32; two places, as the RN generator does
    def r2(v):
        return num(round(v * 100) / 100)

    radius = group("Radius/")
    border = group("Border/")
    cases = "\n".join(f"    case {const_name(v['name'])}" for v in radius)
    values = "\n".join(f"        case .{const_name(v['name'])}: {r2(v['value'])}" for v in radius)
    names = "\n".join(f"        case .{const_name(v['name'])}: {swift_str(v['name'])}" for v in radius)
    b_lines, b_table = [], []
    for v in border:
        n = const_name(v["name"])[len("border"):]
        n = n[0].lower() + n[1:]
        if v.get("description"):
            b_lines.append(doc(v["description"]).rstrip("\n"))
        b_lines.append(f"    static let {n}: CGFloat = {r2(v['value'])}")
        b_table.append(f"        {swift_str(v['name'])}: {n},")
    return f"""{header('Container styles collection', digest)}
import CoreGraphics

/// Corner radii in points: the Figma Radius/<n> variables. No semantic layer yet, so components use these
/// directly, through `Surface(radius:)`.
enum RadiusToken: CaseIterable {{
{cases}

    var value: CGFloat {{
        switch self {{
{values}
        }}
    }}

    /// The Figma variable it comes from
    var figmaName: String {{
        switch self {{
{names}
        }}
    }}
}}

/// Stroke widths in points: the Figma Border/<name> variables. Used through `Surface(border:)`.
enum BorderTokens {{
{chr(10).join(b_lines)}

    /// Every constant by its Figma variable name, for the contract tests
    static let byFigmaName: [String: CGFloat] = [
{chr(10).join(b_table)}
    ]
}}
"""


def gen_color_primitives(colors, digest):
    groups = {}
    for v in colors["variables"]:
        if v["type"] != "COLOR":
            raise SystemExit(f"Colors primitives {v['name']} is not a COLOR")
        if isinstance(v["value"], dict) and v["value"].get("type") == "VARIABLE_ALIAS":
            raise SystemExit(f"Colors primitives {v['name']} is an alias; primitives must be raw values")
        groups.setdefault(v["name"].split("/")[0], []).append(v)
    out, table = [], []
    for family, vs in groups.items():
        out.append(f"    // ── {family} ──")
        for v in vs:
            n = const_name(v["name"])
            a = alpha_of(v)
            opacity = "" if a == 1 else f", opacity: {num(a)}"
            out.append(f"    static let {n} = Color(hex: 0x{hex_of(v)}{opacity})")
            table.append(f"        {swift_str(v['name'])}: {n},")
    return f"""{header('Colors primitives collection (' + colors['modes'][0] + ' mode)', digest)}
import SwiftUI

/// Tier 1: the raw palette, 900 (darkest) to 50 (lightest) per ramp. Never reference this in a component or
/// screen; use `ColorScale` (Tier 2), which aliases into it.
enum ColorPrimitives {{
{chr(10).join(out)}

    /// Every colour by its Figma variable name, for the contract tests
    static let byFigmaName: [String: Color] = [
{chr(10).join(table)}
    ]
}}
"""


# Which semantic tokens may go where: the same name rules as the RN port's DsText / Surface types.
ROLE_RULES = {
    # border/subtle ends in "Subtle" but is a stroke, so border* is kept out of the fills (the RN type lets it through)
    "SurfaceFill": ("Fills a `Surface` may use: surface*, *Solid, *SolidHover, *Subtle (never border*)",
                    lambda n: not n.startswith("border") and (n.startswith("surface") or n.endswith(("Solid", "SolidHover", "Subtle")))),
    "BorderColor": ("Strokes a `Surface` may draw: border*, *Border",
                    lambda n: n.startswith("border") or n.endswith("Border")),
    "TextColor": ("Colours for text and icons, as `DsText(color:)` takes them: content*, *Text",
                  lambda n: n.startswith("content") or n.endswith("Text")),
}


def gen_color_scale(semantics, primitives, digest):
    prim_names = {v["name"] for v in primitives["variables"]}
    groups, all_tokens = {}, []
    for v in semantics["variables"]:
        val = v.get("value")
        if not isinstance(val, dict) or val.get("type") != "VARIABLE_ALIAS" or val.get("collection") != "Colors primitives":
            raise SystemExit(f'Color Semantics "{v["name"]}" is not an alias to a Colors primitives variable: '
                             "fix it in Figma, do not patch the code")
        if val["name"] not in prim_names:
            raise SystemExit(f'Color Semantics "{v["name"]}" aliases {val["name"]}, which is not in Colors primitives')
        groups.setdefault(v["name"].split("/")[0], []).append(v)
        all_tokens.append(v)
    out, table, aliases = [], [], []
    for group, vs in groups.items():
        out.append(f"    // ── {group} ──")
        for v in vs:
            n = const_name(v["name"])
            if v.get("description"):
                out.append(doc(v["description"]).rstrip("\n"))
            out.append(f"    static let {n} = ColorPrimitives.{const_name(v['value']['name'])}")
            table.append(f"        {swift_str(v['name'])}: {n},")
            aliases.append(f"        {swift_str(v['name'])}: {swift_str(v['value']['name'])},")
    role_enums = []
    for enum_name, (summary, rule) in ROLE_RULES.items():
        members = [v for v in all_tokens if rule(const_name(v["name"]))]
        cases = "\n".join(
            (doc(v.get("description"), "    ") if v.get("description") else "") + f"    case {const_name(v['name'])}"
            for v in members)
        colors = "\n".join(f"        case .{const_name(v['name'])}: ColorScale.{const_name(v['name'])}" for v in members)
        role_enums.append(f"""/// {summary}
enum {enum_name}: CaseIterable {{
{cases}

    var color: Color {{
        switch self {{
{colors}
        }}
    }}
}}
""")
    return f"""{header('Color Semantics collection (' + semantics['modes'][0] + ' mode)', digest)}
import SwiftUI

/// Tier 2: semantic colours, what components and screens use. Every value is a reference to a `ColorPrimitives`
/// constant, mirroring the alias in Figma. A Dark mode arrives as a second Figma mode and a second table here.
enum ColorScale {{
{chr(10).join(out)}

    /// Every token by its Figma variable name, for the contract tests
    static let byFigmaName: [String: Color] = [
{chr(10).join(table)}
    ]

    /// The Colors primitives variable each token aliases, by Figma name, for the contract tests
    static let aliasByFigmaName: [String: String] = [
{chr(10).join(aliases)}
    ]
}}

{chr(10).join(role_enums)}"""


def gen_shadow_primitives(effect_styles, digest):
    entries, cases = [], []
    for s in effect_styles:
        drops = [e for e in s["effects"] if e["type"] == "DROP_SHADOW"]
        if len(drops) != 1 or len(s["effects"]) != 1:
            raise SystemExit(f'Effect style "{s["name"]}" must hold exactly one DROP_SHADOW (has {len(drops)})')
        e = drops[0]
        key = style_key(s["name"].replace("/", ""))
        if not re.fullmatch(r"#[0-9A-Fa-f]{6}", e["color"]):
            raise SystemExit(f'Effect style "{s["name"]}": colour {e["color"]!r} is not #RRGGBB')
        entries.append(
            doc(f'{s["name"]}' + (f' — {s["description"]}' if s.get("description") else ""))
            + f"    static let {key} = ShadowParams(figmaName: {swift_str(s['name'])}, color: 0x{e['color'][1:].upper()}, "
              f"opacity: {num(e['opacity'])}, offsetX: {num(e['offset']['x'])}, offsetY: {num(e['offset']['y'])}, "
              f"blur: {num(e['blur'])}, spread: {num(e['spread'])})")
        cases.append(key)
    return f"""{header('local effect styles', digest)}
import CoreGraphics

/// One Figma drop shadow, verbatim. `color` is 0xRRGGBB; `opacity` 0–1; `blur` and `spread` as Figma states them.
struct ShadowParams: Equatable {{
    let figmaName: String
    let color: UInt32
    let opacity: Double
    let offsetX: CGFloat
    let offsetY: CGFloat
    let blur: CGFloat
    let spread: CGFloat
}}

/// Tier 1: drop-shadow parameters as designed in Figma. Never used directly; `ShadowScale` maps them to SwiftUI.
enum ShadowPrimitives {{
{chr(10).join(entries)}

    static let all: [ShadowParams] = [{', '.join(cases)}]
}}
"""


def gen_typography_scale(text_styles, typo, digest):
    names = {v["name"] for v in typo["variables"]}
    kernings = [v for v in typo["variables"] if v["name"].startswith("font/kerning/")]
    lets, cases, specs, figma = [], [], [], []
    for s in text_styles:
        b = dict(s["bound"])
        missing = [k for k in ("fontFamily", "fontStyle", "fontSize", "lineHeight") if not b.get(k)]
        if missing:
            raise SystemExit(f'Text style "{s["name"]}" has unbound properties: {", ".join(missing)}; '
                             "bind them to Typography variables in Figma first")
        if s["lineHeight"]["unit"] != "PIXELS":
            raise SystemExit(f'Text style "{s["name"]}": lineHeight must be in px, got {s["lineHeight"]["unit"]}')
        # ADR 003: Figma can only bind letter spacing as px, so tracked styles set N% directly (unbound); resolve it
        # to the kerning variable holding that percent. 0px == 0% == "none".
        if not b.get("letterSpacing"):
            ls = s["letterSpacing"]
            pct = ls["value"] if ls["unit"] == "PERCENT" else (0 if ls["value"] == 0 else None)
            match = next((k for k in kernings if k["value"] == pct), None) if pct is not None else None
            if not match:
                raise SystemExit(f'Text style "{s["name"]}": letterSpacing {ls} matches no font/kerning/* variable; '
                                 "add one (in percent) in Figma")
            b["letterSpacing"] = match["name"]
        for k, v in b.items():
            if v not in names:
                raise SystemExit(f'Text style "{s["name"]}": {k} is bound to {v}, which is not in the Typography collection')
        key = style_key(s["name"])
        tracking = s["letterSpacing"]["value"]
        lets.append(
            doc(f'{s["name"]} — {s["fontFamily"]} {s["fontStyle"]} {num(s["fontSize"])}/{num(s["lineHeight"]["value"])}'
                + (f", tracking {num(tracking)}%" if tracking else ""))
            + f"    static let {key} = TextStyleSpec(\n"
              f"        family: FoundationTokens.{const_name(b['fontFamily'])},\n"
              f"        weight: FoundationTokens.{const_name(b['fontStyle'])},\n"
              f"        size: FoundationTokens.{const_name(b['fontSize'])},\n"
              f"        lineHeight: FoundationTokens.{const_name(b['lineHeight'])},\n"
              f"        trackingPercent: FoundationTokens.{const_name(b['letterSpacing'])}\n"
              f"    )")
        cases.append(f"    case {key} = {swift_str(s['name'])}")
        specs.append(f"        case .{key}: TypographyScale.{key}")
    return f"""{header('local text styles (bound to the Typography collection)', digest)}
import CoreGraphics

/// Tier 2: the typography scale. One entry per Figma text style, named like the style; every value is a
/// reference to a `FoundationTokens` constant (the alias chain mirrors the variable bindings in Figma).
/// Render it with `DsText(_:variant:color:)`; colour is applied there, never here.
enum TypographyScale {{
{chr(10).join(lets)}
}}

/// The Figma text style to render, by its lower-camel name; the raw value is the Figma style name.
enum TypographyVariant: String, CaseIterable {{
{chr(10).join(cases)}

    var spec: TextStyleSpec {{
        switch self {{
{chr(10).join(specs)}
        }}
    }}
}}
"""


# ─── Main ─────────────────────────────────────────────────────────────────────────────────────────

def main():
    if not os.path.exists(SNAPSHOT):
        raise SystemExit(f"Snapshot not found: {SNAPSHOT}. Copy it from the Horse Design System repo (README.md).")
    raw = open(SNAPSHOT, "rb").read()
    digest = hashlib.sha256(raw).hexdigest()
    snap = json.loads(raw)

    def col(name):
        c = next((c for c in snap["collections"] if c["name"] == name), None)
        if c is None:
            raise SystemExit(f'Collection "{name}" not in snapshot')
        if len(c["modes"]) != 1:
            raise SystemExit(f'Collection "{name}" has {len(c["modes"])} modes; the generator only knows one (add Dark mode support first)')
        return c

    files = {
        "FoundationTokens.swift": gen_foundation(col("Typography"), digest),
        "SpacingPrimitives.swift": gen_spacing(col("Container styles"), digest),
        "ContainerTokens.swift": gen_containers(col("Container styles"), digest),
        "ShadowPrimitives.swift": gen_shadow_primitives(snap.get("effectStyles", []), digest),
        "ColorPrimitives.swift": gen_color_primitives(col("Colors primitives"), digest),
        "ColorScale.swift": gen_color_scale(col("Color Semantics"), col("Colors primitives"), digest),
        "TypographyScale.swift": gen_typography_scale(snap["textStyles"], col("Typography"), digest),
    }

    os.makedirs(OUT_DIR, exist_ok=True)
    drift = 0
    expected = set(files)
    for name, content in files.items():
        target = os.path.join(OUT_DIR, name)
        current = open(target).read() if os.path.exists(target) else None
        rel = os.path.relpath(target, ROOT)
        if CHECK:
            if current != content:
                print(f"error: {rel} is out of date with the Figma snapshot", file=sys.stderr)
                drift += 1
            else:
                print(f"✓ {rel}")
        elif current != content:
            open(target, "w").write(content)
            print(f"✓ wrote {rel}")
        else:
            print(f"✓ {rel} (unchanged)")
    stray = set(f for f in os.listdir(OUT_DIR) if f.endswith(".swift")) - expected
    for f in sorted(stray):
        print(f"error: {f} in Generated/ is not produced by the generator", file=sys.stderr)
        drift += 1
    if CHECK and drift:
        print(f"\n{drift} generated file(s) differ from the snapshot. Run: python3 tools/tokens/generate.py",
              file=sys.stderr)
        sys.exit(1)
    print(f"\nSource: {snap['fileName']} ({snap['fileKey']}), exported {snap['exportedAt']}")


if __name__ == "__main__":
    main()
