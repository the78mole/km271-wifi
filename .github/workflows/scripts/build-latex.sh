#!/bin/bash

echo "📝 Generating LaTeX documentation..."
cd DOC

if [ -f "Erste_Schritte.tex" ]; then
  echo "Building Erste_Schritte.tex..."
  
  # Build PDF (might need multiple passes)
  if command -v pdflatex >/dev/null 2>&1; then
    # Try to continue on errors to avoid workflow failure
    pdflatex -interaction=nonstopmode Erste_Schritte.tex || echo "⚠️ LaTeX build encountered issues, continuing..."
    pdflatex -interaction=nonstopmode Erste_Schritte.tex || echo "⚠️ LaTeX second pass encountered issues, continuing..."  # Second pass for references
    
    # Check if PDF was generated
    if [ -f "Erste_Schritte.pdf" ]; then
      echo "✅ LaTeX PDF generated successfully"
    else
      echo "⚠️ LaTeX PDF generation failed, but continuing workflow"
    fi
  else
    echo "ℹ️ pdflatex not available, skipping LaTeX build"
  fi
else
  echo "ℹ️ No LaTeX files found"
fi
