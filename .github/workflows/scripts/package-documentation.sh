#!/bin/bash
set -e

GITHUB_SHA="$1"
GITHUB_REF_NAME="$2"
VERSION="$3"

echo "📦 Packaging documentation for release..."
if [ -n "$VERSION" ]; then
    echo "📋 Using version: $VERSION"
fi
cd DOC

# Create release documentation structure
mkdir -p ../release-staging/Documentation

# Copy all documentation files
cp -r * ../release-staging/Documentation/ 2>/dev/null || true

# Create documentation index
cat > ../release-staging/Documentation/README.md << EOF
# KM271-WiFi Documentation Release

**Version**: ${VERSION:-"Unknown"}  
**Generated**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')  
**Git Commit**: $(echo "${GITHUB_SHA}" | cut -c1-8)  
**Release**: ${GITHUB_REF_NAME}

## 📚 Available Documentation

### Getting Started Guides
- **Getting_Started.md** - English getting started guide
- **Getting_Started_Generated.html** - HTML version (if available)
- **Getting_Started_Generated.pdf** - PDF version (if available)
- **Erste_Schritte.md** - German getting started guide
- **Erste_Schritte.pdf** - LaTeX-generated PDF (if available)

### Technical Documentation
- **Hardware Description.md** - Detailed hardware documentation
- **Hardware Description.pdf** - PDF version

### Datasheets and References
- Various component datasheets (PDF format)
- Protocol specifications
- Technical references

## 📖 Format Information

- **Markdown (.md)**: Raw documentation files
- **HTML**: Web-viewable documentation with enhanced formatting
- **PDF**: Print-ready documentation
- **AsciiDoc (.adoc)**: Source files for advanced documentation

## 🔗 Quick Links

- [Getting Started (EN)](Getting_Started.md)
- [Erste Schritte (DE)](Erste_Schritte.md)
- [Hardware Description](Hardware%20Description.md)

---

**Note**: This documentation package is automatically generated and synchronized with the hardware release.
EOF

echo "✅ Documentation package created"
ls -la ../release-staging/Documentation/
