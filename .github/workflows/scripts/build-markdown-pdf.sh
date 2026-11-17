#!/bin/bash
# Convert the Markdown documentation in DOC/ to PDF (pandoc + WeasyPrint, no LaTeX).
#
#   DOC/<name>.md          -> <out>/<name>.pdf      (spaces replaced by "_")
#   DOC/<dir>/README.md    -> <out>/<dir>.pdf
#   DOC/sources/ is skipped (third-party PDFs only).
#
# Usage: build-markdown-pdf.sh [--version X.Y.Z] [--out DIR]
# Needs: pandoc, weasyprint (apt: pandoc weasyprint fonts-dejavu)
set -euo pipefail

VERSION=""
OUT="build/docs-pdf"
while [[ $# -gt 0 ]]; do
  case $1 in
    --version) VERSION="$2"; shift 2 ;;
    --out)     OUT="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

ROOT="$(pwd)"
CSS="$ROOT/DOC/pdf.css"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

for tool in pandoc weasyprint; do
  command -v "$tool" >/dev/null || { echo "❌ $tool not found" >&2; exit 1; }
done

echo "📝 Markdown -> PDF (pandoc $(pandoc --version | head -1 | cut -d' ' -f2), WeasyPrint)"
[ -n "$VERSION" ] && echo "📋 Version: $VERSION"

FAILED=0
COUNT=0
while IFS= read -r -d '' md; do
  rel="${md#DOC/}"
  dir="$(dirname "$md")"
  base="$(basename "$md" .md)"
  if [ "$base" = "README" ] && [ "$dir" != "DOC" ]; then
    name="$(basename "$dir")"
  else
    name="$base"
  fi
  pdf="$OUT/${name// /_}.pdf"

  meta=(-M "pagetitle=$name")
  # documents without a YAML title use their first heading as title (footer via CSS)
  [ -n "$VERSION" ] && meta+=(-M "date=Version $VERSION")

  echo "📄 $rel -> $(basename "$pdf")"
  # run inside the document's folder so relative image paths (../IMG/...) resolve
  if (cd "$dir" && pandoc "$(basename "$md")" \
        --from gfm+yaml_metadata_block+implicit_figures \
        --standalone --css "$CSS" "${meta[@]}" \
        --pdf-engine=weasyprint -o "$pdf"); then
    COUNT=$((COUNT + 1))
  else
    echo "❌ failed: $rel" >&2
    FAILED=$((FAILED + 1))
  fi
done < <(find DOC -name '*.md' -not -path 'DOC/sources/*' -print0 | sort -z)

echo "✅ $COUNT PDF(s) in $OUT"
ls -la "$OUT"
[ "$FAILED" -eq 0 ] || { echo "❌ $FAILED document(s) failed" >&2; exit 1; }
