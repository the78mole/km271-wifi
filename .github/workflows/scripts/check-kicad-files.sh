#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"

echo "🔍 Checking KiCad project files for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Check if required files exist
for file in "${PROJECT_NAME}.kicad_pro" "${PROJECT_NAME}.kicad_sch" "${PROJECT_NAME}.kicad_pcb"; do
  if [ ! -f "$file" ]; then
    echo "❌ Error: Required file $file not found!"
    exit 1
  else
    echo "✅ Found: $file"
  fi
done

# Check file permissions
ls -la ${PROJECT_NAME}.*
