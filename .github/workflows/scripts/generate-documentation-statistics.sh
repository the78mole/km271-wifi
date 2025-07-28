#!/bin/bash

echo "📊 Generating documentation statistics..."

# Check if DOC directory exists
if [ ! -d "DOC" ]; then
    echo "⚠️ DOC directory not found, creating it..."
    mkdir -p DOC
fi

cd DOC

cat > DOC_STATISTICS.md << EOF
# Documentation Statistics

Generated on: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

## 📄 File Count and Sizes
| File | Lines | Words | Size |
|------|-------|-------|------|
EOF

for file in *.md *.adoc *.tex; do
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" 2>/dev/null || echo "0")
    words=$(wc -w < "$file" 2>/dev/null || echo "0")
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
    printf "| %-30s | %5d | %5d | %5d |\n" "$file" "$lines" "$words" "$size" >> DOC_STATISTICS.md
  fi
done

# Add PDF and image counts
pdf_count=$(find . -name "*.pdf" -type f | wc -l)
img_count=$(find . -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -type f | wc -l)

cat >> DOC_STATISTICS.md << EOF

## 📊 Summary
- 📄 Markdown files: $(find . -name "*.md" -type f | wc -l)
- 📑 PDF files: $pdf_count
- 📝 AsciiDoc files: $(find . -name "*.adoc" -type f | wc -l)
- 📄 LaTeX files: $(find . -name "*.tex" -type f | wc -l)
- 🖼️ Image files: $img_count
- 💾 Total directory size: $(du -sh . 2>/dev/null | cut -f1 || echo "unknown")

## 📁 All Files
\`\`\`
$(ls -la . 2>/dev/null || echo "No files found")
\`\`\`
EOF

echo "✅ Documentation statistics generated in DOC_STATISTICS.md"

## 🖼️ Images
$(find ../IMG -name "*.png" -o -name "*.jpg" -o -name "*.gif" -o -name "*.svg" 2>/dev/null | wc -l) image files found

## 📋 Summary
- Total documentation files: $(ls -1 *.md *.adoc *.tex 2>/dev/null | wc -l)
- Generated files ready for distribution

EOF

echo "✅ Documentation statistics generated"
cat DOC_STATISTICS.md
