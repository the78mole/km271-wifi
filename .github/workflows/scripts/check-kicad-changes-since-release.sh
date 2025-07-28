#!/bin/bash
set -e

# Parse command line options
PROJECT_NAME=""
PROJECT_PATH=""
PROJECT_DESCRIPTION=""

show_help() {
    echo "Usage: $0 --name <project_name> --path <project_path> --description <description>"
    echo "  --name         Project name (e.g., KM217-WiFi)"
    echo "  --path         Path to project directory"
    echo "  --description  Project description"
    echo "  --help         Show this help message"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --description)
            PROJECT_DESCRIPTION="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check required parameters
if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_PATH" ] || [ -z "$PROJECT_DESCRIPTION" ]; then
    echo "Error: Missing required parameters"
    show_help
    exit 1
fi

echo "🔍 Checking if KiCad files changed since last release for ${PROJECT_DESCRIPTION}..."

# Get the latest release tag
LATEST_RELEASE=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LATEST_RELEASE" ]; then
  echo "ℹ️  No previous releases found - all files considered changed"
  echo "CHANGED=true" >> "${GITHUB_OUTPUT:-/dev/stdout}"
  
  # Save change info even when no release is found
  WORKSPACE_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
  while [ ! -f "${WORKSPACE_ROOT}/.github/workflows/pr-check.yml" ] && [ "${WORKSPACE_ROOT}" != "/" ]; do
    WORKSPACE_ROOT="$(dirname "${WORKSPACE_ROOT}")"
  done
  mkdir -p "${WORKSPACE_ROOT}/change-status"
  echo "PROJECT=${PROJECT_NAME}" > "${WORKSPACE_ROOT}/change-status/${PROJECT_NAME}-changes.txt"
  echo "LATEST_RELEASE=<none>" >> "${WORKSPACE_ROOT}/change-status/${PROJECT_NAME}-changes.txt"
  echo "CHANGED=true" >> "${WORKSPACE_ROOT}/change-status/${PROJECT_NAME}-changes.txt"
  
  # Also create a revision status file
  mkdir -p "${WORKSPACE_ROOT}/revision-status"
  echo "PROJECT=${PROJECT_NAME}" > "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "STATUS=ℹ️ No previous releases" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "DETAILS=No previous releases found - all files considered changed" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  
  exit 0
fi

echo "📋 Latest release: $LATEST_RELEASE"

# Change to project directory
cd "${PROJECT_PATH}"

# Check if any KiCad files changed since the last release
KICAD_FILES=(
  "${PROJECT_NAME}.kicad_pro"
  "${PROJECT_NAME}.kicad_sch"
  "${PROJECT_NAME}.kicad_pcb"
)

CHANGES_FOUND=false

echo "🔄 Checking for changes in KiCad files since $LATEST_RELEASE..."

for file in "${KICAD_FILES[@]}"; do
  if [ -f "$file" ]; then
    # Check if file exists in the release and has changes
    if git show "${LATEST_RELEASE}:${PROJECT_PATH#$(git rev-parse --show-toplevel)/}/$file" >/dev/null 2>&1; then
      # File exists in release, check for differences
      if ! git diff --quiet "${LATEST_RELEASE}" -- "$file"; then
        echo "✅ Changed: $file"
        CHANGES_FOUND=true
      else
        echo "➖ Unchanged: $file"
      fi
    else
      # File is new since release
      echo "🆕 New file: $file"
      CHANGES_FOUND=true
    fi
  else
    echo "⚠️  Missing: $file"
  fi
done

if [ "$CHANGES_FOUND" = true ]; then
  echo "🔄 KiCad files have changed since release $LATEST_RELEASE"
  echo "CHANGED=true" >> "${GITHUB_OUTPUT:-/dev/stdout}"
else
  echo "✅ No KiCad files changed since release $LATEST_RELEASE"
  echo "CHANGED=false" >> "${GITHUB_OUTPUT:-/dev/stdout}"
fi

# Save change info for workflow decisions
WORKSPACE_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
while [ ! -f "${WORKSPACE_ROOT}/.github/workflows/pr-check.yml" ] && [ "${WORKSPACE_ROOT}" != "/" ]; do
  WORKSPACE_ROOT="$(dirname "${WORKSPACE_ROOT}")"
done
mkdir -p "${WORKSPACE_ROOT}/change-status"
echo "PROJECT=${PROJECT_NAME}" > "${WORKSPACE_ROOT}/change-status/${PROJECT_NAME}-changes.txt"
echo "LATEST_RELEASE=${LATEST_RELEASE}" >> "${WORKSPACE_ROOT}/change-status/${PROJECT_NAME}-changes.txt"
echo "CHANGED=${CHANGES_FOUND}" >> "${WORKSPACE_ROOT}/change-status/${PROJECT_NAME}-changes.txt"

# Also create a revision status file for projects without changes
if [ "$CHANGES_FOUND" = false ]; then
  mkdir -p "${WORKSPACE_ROOT}/revision-status"
  echo "PROJECT=${PROJECT_NAME}" > "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "STATUS=⏭️ No changes since release" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "DETAILS=No KiCad files changed since release ${LATEST_RELEASE}" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
  echo "LATEST_RELEASE=${LATEST_RELEASE}" >> "${WORKSPACE_ROOT}/revision-status/${PROJECT_NAME}-revision.txt"
fi
