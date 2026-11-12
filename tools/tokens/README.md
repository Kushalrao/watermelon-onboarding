# Token pipeline

`figma-variables.json` is a copy of the Horse Design System snapshot (Figma file `TWgGkus0FyMoym2H7LNnwD`):
every variable collection, the 21 text styles with their variable bindings, and the 3 Shadow effect styles.
`generate.py` turns it into Swift under `Sources/DesignSystem/Tokens/Generated/`. Nothing there is edited by hand.

```bash
python3 tools/tokens/generate.py           # regenerate
python3 tools/tokens/generate.py --check   # fail if generated files differ (also runs on every build)
python3 tools/lint/check_ds_rules.py       # token-tier lint on components and adopted screens
```

## Refreshing the snapshot

The export script lives in the RN repo (`horse-design-system/tools/tokens/README.md`). After a re-export there:

```bash
cp /Users/kushal/horse-design-system/tools/tokens/figma-variables.json tools/tokens/figma-variables.json
python3 tools/tokens/generate.py
```

Review both diffs together. The generator stops, naming the token, if a text style has an unbound property,
a semantic colour is not an alias to a primitive, an effect style is not exactly one drop shadow, or a
collection gains a second mode.
