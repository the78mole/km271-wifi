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

# Check if schematic, PCB, and XML have matching revisions
if [ -f "${PROJECT_NAME}.kicad_sch" ] && [ -f "${PROJECT_NAME}.kicad_pcb" ]; then
  echo "🔄 Checking revision compatibility between schematic, PCB, and XML..."
  
  # Extract revision from schematic (support both JSON and S-expression formats)
  SCH_REV=$(grep -o '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_sch" | head -1 | sed 's/.*"rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  if [ -z "$SCH_REV" ]; then
    SCH_REV=$(grep -o '(rev "[^"]*")' "${PROJECT_NAME}.kicad_sch" | head -1 | sed 's/(rev "\([^"]*\)")/\1/')
  fi
  
  # Extract revision from PCB (support both JSON and S-expression formats)
  PCB_REV=$(grep -o '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_pcb" | head -1 | sed 's/.*"rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  if [ -z "$PCB_REV" ]; then
    PCB_REV=$(grep -o '(rev "[^"]*")' "${PROJECT_NAME}.kicad_pcb" | head -1 | sed 's/(rev "\([^"]*\)")/\1/')
  fi
  
  # Extract revision from XML (if it exists)
  XML_REV=""
  if [ -f "${PROJECT_NAME}.xml" ]; then
    XML_REV=$(grep -o '<rev>[^<]*</rev>' "${PROJECT_NAME}.xml" | head -1 | sed 's/<rev>\([^<]*\)<\/rev>/\1/')
  fi
  
  echo "📋 Schematic revision: '${SCH_REV:-<not set>}'"
  echo "📋 PCB revision: '${PCB_REV:-<not set>}'"
  echo "📋 XML revision: '${XML_REV:-<not set or no XML file>}'"
  
  # Save revision info for PR summary (use absolute path from workspace root)
  WORKSPACE_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
  while [ ! -f "${WORKSPACE_ROOT}/.github/workflows/pr-check.yml" ] && [ "${WORKSPACE_ROOT}" != "/" ]; do
    WORKSPACE_ROOT="$(dirname "${WORKSPACE_ROOT}")"
  done
  mkdir -p "${WORKSPACE_ROOT}/revision-status"
  echo "PROJECT=${PROJECT_NAME}" > "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "SCH_REV=${SCH_REV:-<not set>}" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "PCB_REV=${PCB_REV:-<not set>}" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "XML_REV=${XML_REV:-<not set>}" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  
  # Compare revisions - all should match if they exist
  ALL_MATCH=true
  MAIN_REV=""
  
  # Determine the main revision (prefer non-empty values)
  if [ -n "$SCH_REV" ]; then
    MAIN_REV="$SCH_REV"
  elif [ -n "$PCB_REV" ]; then
    MAIN_REV="$PCB_REV"
  elif [ -n "$XML_REV" ]; then
    MAIN_REV="$XML_REV"
  fi
  
  # Check if all non-empty revisions match
  if [ -n "$SCH_REV" ] && [ "$SCH_REV" != "$MAIN_REV" ]; then ALL_MATCH=false; fi
  if [ -n "$PCB_REV" ] && [ "$PCB_REV" != "$MAIN_REV" ]; then ALL_MATCH=false; fi
  if [ -n "$XML_REV" ] && [ "$XML_REV" != "$MAIN_REV" ]; then ALL_MATCH=false; fi
  
  # Compare revisions
  if [ -n "$MAIN_REV" ] && [ "$ALL_MATCH" = true ]; then
    echo "✅ All revisions match: $MAIN_REV"
    echo "STATUS=✅ Match" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
    echo "REVISION=$MAIN_REV" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  elif [ -n "$MAIN_REV" ] && [ "$ALL_MATCH" = false ]; then
    echo "❌ Error: Revision mismatch!"
    echo "   Schematic: ${SCH_REV:-<not set>}"
    echo "   PCB: ${PCB_REV:-<not set>}"
    echo "   XML: ${XML_REV:-<not set>}"
    echo "⚠️  Please ensure schematic, PCB, and XML are synchronized before building."
    echo "STATUS=❌ Mismatch" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
    echo "DETAILS=SCH: ${SCH_REV:-<not set>}, PCB: ${PCB_REV:-<not set>}, XML: ${XML_REV:-<not set>}" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
    exit 1
  elif [ -z "$SCH_REV" ] && [ -z "$PCB_REV" ] && [ -z "$XML_REV" ]; then
    echo "⚠️  No revision information found in any file (this is okay for new projects)"
    echo "STATUS=⚠️ No revision info" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
    echo "DETAILS=No revision information in any file" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  else
    echo "⚠️  Warning: Some files have revision information, others don't"
    echo "   Consider adding matching revision information to all files"
    echo "STATUS=⚠️ Partial revision info" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
    echo "DETAILS=SCH: ${SCH_REV:-<not set>}, PCB: ${PCB_REV:-<not set>}, XML: ${XML_REV:-<not set>}" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  fi
else
  echo "ℹ️  Skipping revision check - not all required files present"
  WORKSPACE_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
  while [ ! -f "${WORKSPACE_ROOT}/.github/workflows/pr-check.yml" ] && [ "${WORKSPACE_ROOT}" != "/" ]; do
    WORKSPACE_ROOT="$(dirname "${WORKSPACE_ROOT}")"
  done
  mkdir -p "${WORKSPACE_ROOT}/revision-status"
  echo "PROJECT=${PROJECT_NAME}" > "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "STATUS=ℹ️ Files missing" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "DETAILS=Required files not present for revision check" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
fi
