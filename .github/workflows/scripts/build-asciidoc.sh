#!/bin/bash

# Parse command line arguments
VERSION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "📖 Building AsciiDoc documentation..."
if [ -n "$VERSION" ]; then
    echo "📋 Using version: $VERSION"
fi

# Check if DOC directory exists
if [ ! -d "DOC" ]; then
    echo "⚠️ DOC directory not found, creating it..."
    mkdir -p DOC
fi

cd DOC

# Check if asciidoctor is available
if ! command -v asciidoctor >/dev/null 2>&1; then
    echo "ℹ️ asciidoctor not available, checking for alternatives..."
    
    # Try to install asciidoctor if we're in a container
    if [ -f /.dockerenv ]; then
        echo "📦 Installing asciidoctor in container..."
        apt-get update -qq && apt-get install -y -qq asciidoctor || {
            echo "⚠️ Could not install asciidoctor, skipping AsciiDoc build"
            exit 0
        }
    else
        echo "⚠️ asciidoctor not available, skipping AsciiDoc build"
        exit 0
    fi
fi

# Build AsciiDoc documentation
FOUND_ADOC=false
for file in *.adoc; do
  if [ -f "$file" ]; then
    FOUND_ADOC=true
    filename=$(basename "$file" .adoc)
    echo "📄 Building $file..."
    
    # Prepare version attributes
    VERSION_ATTRS=""
    if [ -n "$VERSION" ]; then
      VERSION_ATTRS="-a revnumber=$VERSION -a version=$VERSION"
    fi
    
    # Generate HTML
    if asciidoctor -b html5 $VERSION_ATTRS -o "${filename}_Generated.html" "$file" 2>/dev/null; then
      echo "✅ HTML generated: ${filename}_Generated.html"
    else
      echo "⚠️ Failed to generate HTML for $file"
    fi
    
    # Generate PDF if possible
    if command -v asciidoctor-pdf >/dev/null 2>&1; then
      if asciidoctor-pdf $VERSION_ATTRS -o "${filename}_Generated.pdf" "$file" 2>/dev/null; then
        echo "✅ PDF generated: ${filename}_Generated.pdf"
      else
        echo "⚠️ Failed to generate PDF for $file"
      fi
    else
      echo "ℹ️ asciidoctor-pdf not available, skipping PDF generation"
    fi
  fi
done

if [ "$FOUND_ADOC" = false ]; then
    echo "ℹ️ No .adoc files found in DOC directory"
fi

echo "✅ AsciiDoc build completed"
echo "📋 Generated AsciiDoc files:"
ls -la *_Generated.* 2>/dev/null || echo "No generated files found"
