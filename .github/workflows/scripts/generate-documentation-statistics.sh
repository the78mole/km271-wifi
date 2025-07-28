#!/bin/bash

echo "📊 Generating documentation statistics..."
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
    lines=$(wc -l < "$file")
    words=$(wc -w < "$file")
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    printf "| %-30s | %5d | %5d | %5d |\n" "$file" "$lines" "$words" "$size" >> DOC_STATISTICS.md
  fi
done

cat >> DOC_STATISTICS.md << EOF

## 🖼️ Images
$(find ../IMG -name "*.png" -o -name "*.jpg" -o -name "*.gif" -o -name "*.svg" 2>/dev/null | wc -l) image files found

## 📋 Summary
- Total documentation files: $(ls -1 *.md *.adoc *.tex 2>/dev/null | wc -l)
- Generated files ready for distribution

EOF

echo "✅ Documentation statistics generated"
cat DOC_STATISTICS.md
