---
name: jlc-source
description: |
  Interactive JLCPCB/LCSC part-sourcing workflow for a KiCAD project via Konnect MCP tools.
  Generates a checklist markdown of candidate LCSC parts per BOM line for the user to pick from,
  then writes the chosen LCSC part numbers back into the schematic's JLC field. Triggers on:
  "source parts", "find JLC parts", "match BOM to JLCPCB", "assign LCSC numbers", "JLC field",
  "sourcing checklist".
argument-hint: "[project path]"
---

# JLC Part Sourcing Workflow

Three-step workflow: list every component → propose LCSC candidates as a checklist markdown →
write the user's picks back into each component's `JLC` field. All schematic writes go through
Konnect MCP tools — never edit `.kicad_sch` files directly (see the `konnect` skill's One Rule).

---

## Toolset Loading

```
get_active_toolsets()             # see what's already loaded
load_toolset('sch_components')    # list_schematic_components, edit_schematic_component
load_toolset('integration')       # search_jlcpcb_parts, get_jlcpcb_part, suggest_jlcpcb_alternatives, download_jlcpcb_database
```

## Prerequisite: Local JLCPCB Database

```
get_jlcpcb_database_stats()
```

If `exists: false`, run `download_jlcpcb_database()` once before searching (one-time SQLite cache
of the JLCPCB catalog — ask the user first, it's a sizeable download). Skip if already cached.

---

## Step 1 — List Components → Sourcing Markdown

Call `list_schematic_components(schematic)`. Group entries by identical `(value, footprint)` —
one sourcing decision covers every reference in that group (e.g. `R1,R3,R76,R77,R84,R86` all
"220Ω 0603" become a single row, not six).

Skip groups where every reference already has a non-empty `JLC` property (check via
`get_schematic_component` or the existing BOM's `JLC` column) unless the user asks to re-source.

Write the result to `<project_dir>/jlc-sourcing.md` with one section per group and one checkbox
per candidate part:

```markdown
# JLC Part Sourcing — <project name>

Check ONE box per section for the part to use, then tell Claude "apply selections".
Sections with no candidates or only one obvious choice are marked accordingly.

## R1, R3, R76, R77, R84, R86 — 220 (Resistor_SMD:R_0603_1608Metric_...)

- [ ] [C17168](https://www.lcsc.com/product-detail/_C17168.html) — 220Ω ±1% 1/10W 0603 [Basic] — $0.0016/ea, 95k in stock
- [ ] [C25087](https://www.lcsc.com/product-detail/_C25087.html) — 220Ω ±5% 1/8W 0603 [Extended] — $0.0009/ea, 40k in stock

## U1 — ESP32-WROOM-32D (the78mole:ESP32-WROOM-32D)

- [ ] [C529577](https://www.lcsc.com/product-detail/_C529577.html) — ESP32-WROOM-32D (Espressif) [Extended] — $2.10/ea, 1.2k in stock

_Already has JLC=C529577 — re-sourcing only if you uncheck and pick a different candidate._
```

Link format: `https://www.lcsc.com/product-detail/_{lcsc_id}.html` (confirmed working — resolves
directly, no search redirect needed).

### Finding candidates per group

- **Generic passives (R, C, L)**: `suggest_jlcpcb_alternatives(value, footprint, limit=5)` —
  purpose-built for exactly this: given a value + footprint, returns stocked matches ranked by
  price/availability. Prefer `basic_only` results when the tool/query supports it — Basic Library
  parts avoid JLCPCB's $3 extended-part fee.
- **Named/branded parts (ICs, connectors, modules)**: `search_jlcpcb_parts(query=value or MPN,
  in_stock=true, limit=5)`. Match on package/pin-count from the footprint field, not just name
  similarity — verify with `get_jlcpcb_part(lcsc_id)` before listing a candidate if the match is
  ambiguous.
- Order candidates cheapest-and-Basic first; put the current `JLC` value's part first (pre-vetted)
  if the group already has one.

---

## Step 2 — Wait for User Selection

The markdown is the handoff point. Do not guess or auto-check boxes. Tell the user where the file
is and that checking a box + saying "apply selections" (or similar) triggers step 3.

---

## Step 3 — Apply Selections

Re-read `jlc-sourcing.md`. For each section, find the checked `- [x]` line and extract its LCSC
id from the link. For every reference designator in that section's heading, call:

```
edit_schematic_component(schematic, reference=<ref>, fields={"JLC": "<lcsc_id>"})
```

One call per reference — the tool takes a single reference, not a list, so a 6-designator group
means 6 calls with the same `JLC` value.

After writing, verify with `get_schematic_component(schematic, reference)` on a sample of the
changed references, then re-generate the BOM (`export_bom` or the raw
`kicad-cli sch export bom --fields Reference,Value,Footprint,JLC,QUANTITY,DNP`, since Konnect's
own `export_bom`/`export_manufacturing_package` don't expose a `--fields`-equivalent yet) to
confirm the LCSC numbers now appear.

Sections left unchecked (no box ticked) are left untouched — don't clear or guess a value for
them.

---

## Rules

1. **Never edit `.kicad_sch` directly** — always `edit_schematic_component`, per the `konnect`
   skill's One Rule.
2. **One sourcing decision per (value, footprint) group**, not per reference — avoids asking the
   same question 20 times for 20 identical resistors.
3. **Don't auto-select** — the checklist exists so a human picks; Claude proposes candidates, the
   user decides.
4. **Prefer Basic Library parts** when candidates are otherwise comparable — avoids the $3/part
   extended fee at assembly.
5. **Re-verify ambiguous IC matches** with `get_jlcpcb_part` before listing them — a wrong package
   or pin-count match is worse than no candidate.
6. **Leave unchecked sections alone** in step 3 — don't invent a default.
