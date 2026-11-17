#!/bin/bash
set -e

GITHUB_SHA="$1"
GITHUB_REF_NAME="$2"
VERSION="$3"
PDF_DIR="${4:-build/docs-pdf}"

echo "📦 Packaging documentation for release..."
if [ -n "$VERSION" ]; then
    echo "📋 Using version: $VERSION"
fi

STAGE=release-staging/Documentation
mkdir -p "$STAGE/pdf"

# Markdown sources, images, scripts and third-party documents (DOC/sources)
cp -r DOC/. "$STAGE/" 2>/dev/null || true

# PDFs generated from Markdown by build-markdown-pdf.sh
if compgen -G "$PDF_DIR/*.pdf" >/dev/null; then
  cp "$PDF_DIR"/*.pdf "$STAGE/pdf/"
else
  echo "⚠️ No generated PDFs found in $PDF_DIR"
fi

PDF_LIST=$(cd "$STAGE/pdf" && ls -1 *.pdf 2>/dev/null | sed 's/^/- pdf\//' || true)

cat > "$STAGE/README.md" << EOT
# KM271-WiFi Documentation Release

**Version**: ${VERSION:-"Unknown"}
**Generated**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
**Git Commit**: $(echo "${GITHUB_SHA}" | cut -c1-8)
**Release**: ${GITHUB_REF_NAME}

## 📚 PDF documentation (generated from Markdown)

${PDF_LIST}

## 📝 Sources

- \`*.md\`, \`*/README.md\`: Markdown sources of the PDFs above
- \`sources/\`: third-party documents (Buderus manuals, 3964R protocol), see \`sources/README.md\`

---

**Note**: This documentation package is generated automatically by the release workflow.
EOT

echo "✅ Documentation package created"
ls -la "$STAGE" "$STAGE/pdf"
