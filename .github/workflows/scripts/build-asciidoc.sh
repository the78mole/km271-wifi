#!/bin/bash

echo "📖 Building AsciiDoc documentation..."
cd DOC

# Build AsciiDoc documentation
for file in *.adoc; do
  if [ -f "$file" ]; then
    filename=$(basename "$file" .adoc)
    echo "Building $file..."
    
    if command -v asciidoctor >/dev/null 2>&1; then
      # Generate HTML
      asciidoctor -b html5 -o "${filename}_Generated.html" "$file"
      echo "✅ HTML generated: ${filename}_Generated.html"
      
      # Generate PDF if possible
      if command -v asciidoctor-pdf >/dev/null 2>&1; then
        asciidoctor-pdf -o "${filename}_Generated.pdf" "$file"
        echo "✅ PDF generated: ${filename}_Generated.pdf"
      else
        echo "ℹ️ asciidoctor-pdf not available, skipping PDF generation"
      fi
    else
      echo "ℹ️ asciidoctor not available, skipping AsciiDoc build"
    fi
  fi
done

# List generated files
echo "📋 Generated AsciiDoc files:"
ls -la *_Generated.* 2>/dev/null || echo "No generated files found"
