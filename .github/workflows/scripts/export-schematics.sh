#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"

echo "📐 Exporting schematic to PDF for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

kicad-cli sch export pdf \
  --output "Export/PDF/${PROJECT_NAME}-Schematics.pdf" \
  ${PROJECT_NAME}.kicad_sch
  
# Verify export
if [ -f "Export/PDF/${PROJECT_NAME}-Schematics.pdf" ]; then
  echo "✅ Schematic PDF exported successfully"
  ls -lh Export/PDF/${PROJECT_NAME}-Schematics.pdf
else
  echo "❌ Error: Schematic PDF export failed!"
  exit 1
fi
