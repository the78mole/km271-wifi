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

# Check if schematic and PCB have matching revisions
if [ -f "${PROJECT_NAME}.kicad_sch" ] && [ -f "${PROJECT_NAME}.kicad_pcb" ]; then
  echo "🔄 Checking revision compatibility between schematic and PCB..."
  
  # Extract revision from schematic
  SCH_REV=$(grep -o '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_sch" | head -1 | sed 's/.*"rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  
  # Extract revision from PCB
  PCB_REV=$(grep -o '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_pcb" | head -1 | sed 's/.*"rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  
  echo "📋 Schematic revision: '${SCH_REV:-<not set>}'"
  echo "📋 PCB revision: '${PCB_REV:-<not set>}'"
  
  # Save revision info for PR summary
  mkdir -p ../revision-status
  echo "PROJECT=${PROJECT_NAME}" > "../revision-status/${PROJECT_NAME}-revision.txt"
  echo "SCH_REV=${SCH_REV:-<not set>}" >> "../revision-status/${PROJECT_NAME}-revision.txt"
  echo "PCB_REV=${PCB_REV:-<not set>}" >> "../revision-status/${PROJECT_NAME}-revision.txt"
  
  # Compare revisions
  if [ -n "$SCH_REV" ] && [ -n "$PCB_REV" ]; then
    if [ "$SCH_REV" = "$PCB_REV" ]; then
      echo "✅ Revisions match: $SCH_REV"
      echo "STATUS=✅ Match" >> "../revision-status/${PROJECT_NAME}-revision.txt"
      echo "REVISION=$SCH_REV" >> "../revision-status/${PROJECT_NAME}-revision.txt"
    else
      echo "❌ Error: Revision mismatch!"
      echo "   Schematic: $SCH_REV"
      echo "   PCB: $PCB_REV"
      echo "⚠️  Please ensure schematic and PCB are synchronized before building."
      echo "STATUS=❌ Mismatch" >> "../revision-status/${PROJECT_NAME}-revision.txt"
      echo "DETAILS=SCH: $SCH_REV, PCB: $PCB_REV" >> "../revision-status/${PROJECT_NAME}-revision.txt"
      exit 1
    fi
  elif [ -z "$SCH_REV" ] && [ -z "$PCB_REV" ]; then
    echo "⚠️  No revision information found in either file (this is okay for new projects)"
    echo "STATUS=⚠️ No revision info" >> "../revision-status/${PROJECT_NAME}-revision.txt"
    echo "DETAILS=No revision information in either file" >> "../revision-status/${PROJECT_NAME}-revision.txt"
  else
    echo "⚠️  Warning: Only one file has revision information"
    echo "   Consider adding matching revision information to both files"
    echo "STATUS=⚠️ Partial revision info" >> "../revision-status/${PROJECT_NAME}-revision.txt"
    echo "DETAILS=SCH: ${SCH_REV:-<not set>}, PCB: ${PCB_REV:-<not set>}" >> "../revision-status/${PROJECT_NAME}-revision.txt"
  fi
else
  echo "ℹ️  Skipping revision check - not all required files present"
  mkdir -p ../revision-status
  echo "PROJECT=${PROJECT_NAME}" > "../revision-status/${PROJECT_NAME}-revision.txt"
  echo "STATUS=ℹ️ Files missing" >> "../revision-status/${PROJECT_NAME}-revision.txt"
  echo "DETAILS=Required files not present for revision check" >> "../revision-status/${PROJECT_NAME}-revision.txt"
fi
