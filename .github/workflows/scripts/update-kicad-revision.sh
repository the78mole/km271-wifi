#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"
NEW_VERSION="$4"
PR_NUMBER="$5"

echo "🔄 Updating KiCad revision for ${PROJECT_DESCRIPTION}..."

# Build the new revision string with PR number
NEW_REV="${NEW_VERSION}-pr${PR_NUMBER}"
echo "📋 Setting revision to: ${NEW_REV}"

# Change to project directory
cd "${PROJECT_PATH}"

# Update revision in schematic file
if [ -f "${PROJECT_NAME}.kicad_sch" ]; then
  echo "📐 Updating revision in schematic file..."
  
  # Handle both S-expression and JSON formats
  if grep -q '(rev "[^"]*")' "${PROJECT_NAME}.kicad_sch" 2>/dev/null; then
    # S-expression format: (rev "0.1.1")
    sed -i "s/(rev \"[^\"]*\")/(rev \"${NEW_REV}\")/" "${PROJECT_NAME}.kicad_sch"
    echo "✅ Updated S-expression format in schematic"
  elif grep -q '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_sch" 2>/dev/null; then
    # JSON format: "rev": "0.1.1"
    sed -i "s/\"rev\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"rev\": \"${NEW_REV}\"/" "${PROJECT_NAME}.kicad_sch"
    echo "✅ Updated JSON format in schematic"
  else
    echo "⚠️  No revision field found in schematic - consider adding one"
  fi
else
  echo "❌ Schematic file not found: ${PROJECT_NAME}.kicad_sch"
fi

# Update revision in PCB file
if [ -f "${PROJECT_NAME}.kicad_pcb" ]; then
  echo "🔧 Updating revision in PCB file..."
  
  # Handle both S-expression and JSON formats
  if grep -q '(rev "[^"]*")' "${PROJECT_NAME}.kicad_pcb" 2>/dev/null; then
    # S-expression format: (rev "0.1.1")
    sed -i "s/(rev \"[^\"]*\")/(rev \"${NEW_REV}\")/" "${PROJECT_NAME}.kicad_pcb"
    echo "✅ Updated S-expression format in PCB"
  elif grep -q '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_pcb" 2>/dev/null; then
    # JSON format: "rev": "0.1.1"
    sed -i "s/\"rev\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"rev\": \"${NEW_REV}\"/" "${PROJECT_NAME}.kicad_pcb"
    echo "✅ Updated JSON format in PCB"
  else
    echo "⚠️  No revision field found in PCB - consider adding one"
  fi
else
  echo "❌ PCB file not found: ${PROJECT_NAME}.kicad_pcb"
fi

# Verify the changes
echo "🔍 Verifying revision updates..."
if [ -f "${PROJECT_NAME}.kicad_sch" ]; then
  SCH_REV=$(grep -o '(rev "[^"]*")' "${PROJECT_NAME}.kicad_sch" 2>/dev/null | head -1 | sed 's/(rev "\([^"]*\)")/\1/' || \
            grep -o '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_sch" 2>/dev/null | head -1 | sed 's/.*"rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
  echo "📐 Schematic revision: ${SCH_REV:-<not found>}"
fi

if [ -f "${PROJECT_NAME}.kicad_pcb" ]; then
  PCB_REV=$(grep -o '(rev "[^"]*")' "${PROJECT_NAME}.kicad_pcb" 2>/dev/null | head -1 | sed 's/(rev "\([^"]*\)")/\1/' || \
            grep -o '"rev"[[:space:]]*:[[:space:]]*"[^"]*"' "${PROJECT_NAME}.kicad_pcb" 2>/dev/null | head -1 | sed 's/.*"rev"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
  echo "🔧 PCB revision: ${PCB_REV:-<not found>}"
fi

echo "✅ Revision update completed!"
