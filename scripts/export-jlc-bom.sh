#!/usr/bin/env bash
# Export the BOMs for JLCPCB assembly from the KiCad schematic.
#
# Grouping includes the DNP flag and the JLC (LCSC) field, so a single
# DNP part can never turn its whole value group into "do not populate"
# (this happened with the first hand-made KM217-WiFi_BOM_JLC.csv, where
# e.g. R33, R78, R20-R22 and R80 ended up as DNP).
#
#   <project>_BOM_JLC.csv   upload file for JLCPCB, populated parts only
#   <project>_BOM_full.csv  all parts incl. DNP, for review
#
# Usage: scripts/export-jlc-bom.sh [project-dir]   (default: KM217-WiFi)
# Needs kicad-cli >= 10 (the schematic is in KiCad 10 format).
set -euo pipefail

PROJ_DIR="${1:-KM217-WiFi}"
NAME="$(basename "$PROJ_DIR")"
SCH="$PROJ_DIR/$NAME.kicad_sch"

[ -f "$SCH" ] || { echo "Schematic not found: $SCH" >&2; exit 1; }

FIELDS='Reference,Value,Footprint,JLC,${QUANTITY},${DNP}'
GROUP='Value,Footprint,JLC,${DNP}'

kicad-cli sch export bom "$SCH" \
  --fields "${FIELDS%,\$\{DNP\}}" \
  --labels 'Designator,Value,Footprint,LCSC Part #,Qty' \
  --group-by "$GROUP" --exclude-dnp \
  -o "$PROJ_DIR/${NAME}_BOM_JLC.csv"

kicad-cli sch export bom "$SCH" \
  --fields "$FIELDS" \
  --labels 'Designator,Value,Footprint,LCSC Part #,Qty,DNP' \
  --group-by "$GROUP" \
  -o "$PROJ_DIR/${NAME}_BOM_full.csv"

echo "Written: $PROJ_DIR/${NAME}_BOM_JLC.csv, $PROJ_DIR/${NAME}_BOM_full.csv"
