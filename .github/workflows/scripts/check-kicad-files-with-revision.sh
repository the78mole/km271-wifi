#!/bin/bash
set -e

# Script: check-kicad-files-with-revision.sh
# Purpose: Check KiCad project files and verify revision consistency across formats
# Usage: check-kicad-files-with-revision.sh --name PROJECT_NAME --path PROJECT_PATH --description PROJECT_DESCRIPTION

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Check KiCad project files and verify revision consistency between schematic, 
PCB, and XML files. Supports JSON, S-expression, and XML formats.

OPTIONS:
    -n, --name PROJ_NAME        Project name (e.g. "KM217-WiFi")
    -p, --path PROJ_PATH        Project path (e.g. "KM217-WiFi")
    -d, --description DESC      Project description (e.g. "Main KM217-WiFi Board")
    -h, --help                  Show this help message

EXAMPLES:
    $0 --name "KM217-WiFi" --path "KM217-WiFi" --description "Main Board"
    $0 -n "ETH_W5500" -p "EXTENSIONS/ETH_W5500" -d "Ethernet Extension"

VALIDATION:
    - Required files: .kicad_pro, .kicad_sch, .kicad_pcb
    - Revision consistency across all file formats
    - File permissions and accessibility

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -p|--path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -d|--description)
            PROJECT_DESCRIPTION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Fallback to positional arguments for backward compatibility
if [[ -z "$PROJECT_NAME" && -n "$1" ]]; then
    PROJECT_NAME="$1"
    PROJECT_PATH="$2"
    PROJECT_DESCRIPTION="$3"
fi

# Validate required parameters
if [[ -z "$PROJECT_NAME" || -z "$PROJECT_PATH" || -z "$PROJECT_DESCRIPTION" ]]; then
    echo "❌ Error: Missing required parameters"
    show_help
    exit 1
fi

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
