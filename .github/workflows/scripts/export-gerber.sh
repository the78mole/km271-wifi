#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"

echo "🔧 Exporting Gerber files for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Export Gerber files
kicad-cli pcb export gerbers \
  --output Export/Gerbers/ \
  --layers "F.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts" \
  --precision 6 \
  --no-x2 \
  --use-drill-file-origin \
  ${PROJECT_NAME}.kicad_pcb
  
# Export drill files separately for better control
kicad-cli pcb export drill \
  --output Export/Drill/ \
  --format gerber \
  --drill-origin plot \
  --gerber-precision 6 \
  ${PROJECT_NAME}.kicad_pcb
  
# List generated files
echo "📋 Generated Gerber files:"
ls -la Export/Gerbers/
echo "📋 Generated Drill files:"
ls -la Export/Drill/
