# Requirements (StrictDoc)

Requirements and architecture of the KM271-WiFi main board, written in
[StrictDoc](https://strictdoc.readthedocs.io/) format. The extension boards
have their own `req` folder (e.g. [`EXTENSIONS/ETH_W5500/req`](../../EXTENSIONS/ETH_W5500/req/)).
The rendered documents are published to GitHub Pages with every hardware release.

| File | Content | UID prefix |
|------|---------|------------|
| `01_system_requirements.sdoc` | System requirements (product level) | `KM271-SYS-` |
| `02_system_architecture.sdoc` | Subsystems, interfaces, architecture decisions | `KM271-SYA-` |
| `03_hardware_requirements.sdoc` | Hardware requirements of the main board | `KM271-HW-` |
| `04_hardware_architecture.sdoc` | Circuit blocks, GPIO allocation | `KM271-HWA-` |
| `05_software_requirements.sdoc` | High-level software requirements, independent of the firmware implementation | `KM271-SW-` |
| `requirements.sgra` | Grammar for requirement documents | |
| `architecture.sgra` | Grammar for architecture documents | |

## Traceability

```
KM271-SYS  <──  KM271-SYA  <──  KM271-HW  <──  KM271-HWA
     ^              ^
     └──────────────┴──────  KM271-SW
ETH-SYS / ETH-HW / ETH-SW  ──>  KM271-SYS / KM271-SYA / KM271-SW
```

Each element points to its parents with `RELATIONS: - TYPE: Parent`.
StrictDoc refuses to export when a parent UID does not exist.

## Fields

Requirements (`requirements.sgra`):

- `STATUS`: review state (Draft, Proposed, Approved, Rejected, Obsolete)
- `TYPE`, `PRIORITY` (Must/Should/Could = shall/should/may)
- `VERIFICATION`: Inspection, Review, Analysis, Simulation, Test, Demonstration
- `COMPLIANCE`: how the current design meets the requirement (Met, Partially met,
  Not met, Not verified, Not applicable). Software requirements leave it empty,
  because compliance depends on the firmware.
- `RATIONALE`, `SOURCE`, `COMMENT`

Architecture (`architecture.sgra`): `BLOCK` (with `REALIZATION` = schematic
designators and `VARIANTS` = assembly options), `INTERFACE` (with pin
assignment in `SIGNALS`) and `DECISION` (context, decision, consequences).

The grammar files exist in every `req` folder, because StrictDoc only imports
grammars from the same folder. Keep the copies identical.

## Build locally

```bash
pip install strictdoc==0.32.1
strictdoc server .                 # live view with editor, from the repository root
strictdoc export . --formats html  # static export to ./output
```

The project configuration is `strictdoc_config.py` in the repository root.
