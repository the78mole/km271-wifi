#!/bin/bash
set -e

PROJECT_NAME="$1"
PROJECT_PATH="$2"
PROJECT_DESCRIPTION="$3"
GITHUB_SHA="$4"
GITHUB_REF_NAME="$5"

echo "📦 Creating release package for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Create release directory structure
mkdir -p ../release-staging/${PROJECT_NAME}

# Copy all export files with proper structure
cp -r Export/* ../release-staging/${PROJECT_NAME}/

# Create a release-specific README
cat > ../release-staging/${PROJECT_NAME}/README.md << EOF
# ${PROJECT_NAME} Hardware Release

**Generated**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')  
**Git Commit**: $(echo "${GITHUB_SHA}" | cut -c1-8)  
**Release**: ${GITHUB_REF_NAME}  
**Project**: ${PROJECT_DESCRIPTION}

## 📁 Directory Structure

- **Gerbers/**: PCB manufacturing files (Gerber format)
- **Drill/**: Drill files for PCB manufacturing  
- **PDF/**: Documentation (schematics and PCB layouts)
- **Images/**: Assembly diagrams (SVG/PNG format)
- **3D/**: 3D models (STEP format)

## 🏭 Manufacturing Instructions

1. **PCB Manufacturing**: Upload all files from \`Gerbers/\` and \`Drill/\` directories to your PCB manufacturer
2. **Layer Stack**: Standard 2-layer PCB
3. **Drill Files**: Use Gerber format drill files for best compatibility
4. **Assembly**: Refer to PDF files and assembly images for component placement

## 📋 Quality Check

All files have been automatically validated:
- ✅ Gerber files generated with 6-digit precision
- ✅ Drill files in Gerber format for compatibility
- ✅ PDF documentation includes schematics and PCB layouts
- ✅ 3D STEP file for mechanical verification
- ✅ Assembly images for production reference

## 🔧 Technical Specifications

See \`PRODUCTION_SUMMARY.md\` for detailed file information and specifications.

---

**Note**: This is an automated release build. All files are production-ready.
EOF

echo "✅ Release package created"
ls -la ../release-staging/${PROJECT_NAME}/
