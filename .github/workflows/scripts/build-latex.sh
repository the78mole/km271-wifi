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

echo "📝 Generating LaTeX documentation..."
if [ -n "$VERSION" ]; then
    echo "📋 Using version: $VERSION"
fi

# Check if DOC directory exists
if [ ! -d "DOC" ]; then
    echo "⚠️ DOC directory not found, creating it..."
    mkdir -p DOC
fi

cd DOC

# Check if pdflatex is available
if ! command -v pdflatex >/dev/null 2>&1; then
    echo "ℹ️ pdflatex not available, skipping LaTeX build"
    exit 0
fi

FOUND_TEX=false

if [ -f "Erste_Schritte.tex" ]; then
  FOUND_TEX=true
  echo "📄 Building Erste_Schritte.tex..."
  
  # Build PDF (might need multiple passes)
  if pdflatex -interaction=nonstopmode Erste_Schritte.tex >/dev/null 2>&1; then
    pdflatex -interaction=nonstopmode Erste_Schritte.tex >/dev/null 2>&1  # Second pass for references
    
    # Check if PDF was generated
    if [ -f "Erste_Schritte.pdf" ]; then
      echo "✅ LaTeX PDF generated successfully"
    else
      echo "⚠️ LaTeX PDF generation failed"
    fi
    
    # Clean up auxiliary files
    rm -f Erste_Schritte.aux Erste_Schritte.log Erste_Schritte.out || true
  else
    echo "⚠️ LaTeX build encountered issues"
  fi
fi

# Check for other .tex files
for file in *.tex; do
  if [ -f "$file" ] && [ "$file" != "Erste_Schritte.tex" ]; then
    FOUND_TEX=true
    filename=$(basename "$file" .tex)
    echo "📄 Building $file..."
    
    if pdflatex -interaction=nonstopmode "$file" >/dev/null 2>&1; then
      pdflatex -interaction=nonstopmode "$file" >/dev/null 2>&1  # Second pass
      echo "✅ PDF generated: ${filename}.pdf"
      
      # Clean up auxiliary files
      rm -f "${filename}.aux" "${filename}.log" "${filename}.out" || true
    else
      echo "⚠️ Failed to generate PDF for $file"
    fi
  fi
done

if [ "$FOUND_TEX" = false ]; then
    echo "ℹ️ No .tex files found in DOC directory"
fi

echo "✅ LaTeX build completed"
