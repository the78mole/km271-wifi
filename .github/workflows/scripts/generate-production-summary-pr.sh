#!/bin/bash
set -e

# Parse command line arguments
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
        --sha)
            GITHUB_SHA="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

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
- \`${PROJECT_NAME}-PCB-Complete.pdf\` - Complete PCB layout (5 pages: User drawings, Front copper, Back copper, Front assembly, Back assembly)

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
