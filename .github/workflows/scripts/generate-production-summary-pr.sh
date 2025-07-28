#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"
GITHUB_SHA="$4"

echo "📊 Generating production summary for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Create production summary
cat > Export/PRODUCTION_SUMMARY.md << EOF
# ${PROJECT_NAME} Production Files

Generated on: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Git Commit: $(echo "${GITHUB_SHA:-local}" | cut -c1-8)
Project: ${PROJECT_DESCRIPTION}

## 📐 Schematic Files
- \`${PROJECT_NAME}-Schematics.pdf\` - Complete schematic documentation

## 🔧 Manufacturing Files

### Gerber Files (Export/Gerbers/)
$(ls -1 Export/Gerbers/ | sed 's/^/- /')

### Drill Files (Export/Drill/)
$(ls -1 Export/Drill/ | sed 's/^/- /')

## 📄 Documentation
- \`${PROJECT_NAME}-PCB-Top.pdf\` - Top layer layout
- \`${PROJECT_NAME}-PCB-Bottom.pdf\` - Bottom layer layout

## 🖼️ Assembly Images
$(ls -1 Export/Images/ | sed 's/^/- /')

## 🎯 3D Models
$(ls -1 Export/3D/ | sed 's/^/- /')

## 📋 File Sizes
\`\`\`
$(find Export/ -type f -exec ls -lh {} \; | awk '{print $5, $9}' | sort -k2)
\`\`\`

## ⚠️ Notes
- Gerber files are generated with 6-digit precision
- Drill files use Gerber format for better compatibility
- All files are ready for production use
- STEP file included for 3D visualization and mechanical design

EOF

echo "✅ Production summary generated"
cat Export/PRODUCTION_SUMMARY.md
