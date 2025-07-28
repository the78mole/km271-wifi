#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"

echo "🧪 Validating exported files for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}/Export"

# Check if critical files exist and have reasonable sizes
critical_files="PDF/${PROJECT_NAME}-Schematics.pdf PDF/${PROJECT_NAME}-PCB-Top.pdf PDF/${PROJECT_NAME}-PCB-Bottom.pdf 3D/${PROJECT_NAME}.step"

for file in $critical_files; do
  if [ -f "$file" ]; then
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    if [ "$size" -gt 1000 ]; then
      echo "✅ $file ($size bytes)"
    else
      echo "⚠️ $file seems too small ($size bytes)"
    fi
  else
    echo "❌ Missing: $file"
    exit 1
  fi
done

# Check Gerber files
gerber_count=$(ls -1 Gerbers/*.g* 2>/dev/null | wc -l || echo "0")
if [ "$gerber_count" -lt 5 ]; then
  echo "⚠️ Only $gerber_count Gerber files found, expected at least 5"
else
  echo "✅ $gerber_count Gerber files generated"
fi

echo "🎉 File validation completed"
