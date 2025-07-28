#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"

echo "🎯 Exporting 3D models for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Export STEP file for 3D CAD (ignore warnings about missing 3D models)
kicad-cli pcb export step \
  --output "Export/3D/${PROJECT_NAME}.step" \
  --drill-origin \
  --grid-origin \
  ${PROJECT_NAME}.kicad_pcb || {
    echo "⚠️ STEP export completed with warnings (missing 3D models)"
    # Check if file was actually created despite warnings
    if [ -f "Export/3D/${PROJECT_NAME}.step" ]; then
      echo "✅ STEP file created successfully despite warnings"
    else
      echo "❌ STEP export failed completely"
      exit 1
    fi
  }
  
echo "✅ STEP model exported"
ls -la Export/3D/
