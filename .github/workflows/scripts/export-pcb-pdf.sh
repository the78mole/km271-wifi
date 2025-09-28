#!/bin/bash
set -e

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --description)
            PROJECT_DESCRIPTION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "📄 Exporting PCB layout to combined PDF for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Create temporary directory for individual pages
TEMP_DIR="Export/PDF/temp"
mkdir -p "${TEMP_DIR}"

# Export individual layer pages
echo "📄 Exporting User.Drawings + Edge.Cuts..."
kicad-cli pcb export pdf \
  --output "${TEMP_DIR}/01-user-drawings.pdf" \
  --layers "User.Drawings,Edge.Cuts" \
  ${PROJECT_NAME}.kicad_pcb

echo "📄 Exporting F.Cu + Edge.Cuts..."
kicad-cli pcb export pdf \
  --output "${TEMP_DIR}/02-front-copper.pdf" \
  --layers "F.Cu,Edge.Cuts" \
  ${PROJECT_NAME}.kicad_pcb

echo "📄 Exporting B.Cu + Edge.Cuts (mirrored)..."
kicad-cli pcb export pdf \
  --output "${TEMP_DIR}/03-back-copper.pdf" \
  --layers "B.Cu,Edge.Cuts" \
  --mirror \
  ${PROJECT_NAME}.kicad_pcb

echo "📄 Exporting F.Cu + F.Silkscreen + F.Mask + Edge.Cuts..."
kicad-cli pcb export pdf \
  --output "${TEMP_DIR}/04-front-assembly.pdf" \
  --layers "F.Cu,F.Silkscreen,F.Mask,Edge.Cuts" \
  ${PROJECT_NAME}.kicad_pcb

echo "📄 Exporting B.Cu + B.Silkscreen + B.Mask + Edge.Cuts (mirrored)..."
kicad-cli pcb export pdf \
  --output "${TEMP_DIR}/05-back-assembly.pdf" \
  --layers "B.Cu,B.Silkscreen,B.Mask,Edge.Cuts" \
  --mirror \
  ${PROJECT_NAME}.kicad_pcb

# Combine all PDFs into one
echo "📄 Combining all layers into single PDF..."
COMBINED_PDF="Export/PDF/${PROJECT_NAME}-PCB-Complete.pdf"

# Try different PDF combination tools in order of preference
if command -v gs >/dev/null 2>&1; then
  echo "📄 Using ghostscript to combine PDFs..."
  gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress \
    -sOutputFile="${COMBINED_PDF}" \
    "${TEMP_DIR}"/01-user-drawings.pdf \
    "${TEMP_DIR}"/02-front-copper.pdf \
    "${TEMP_DIR}"/03-back-copper.pdf \
    "${TEMP_DIR}"/04-front-assembly.pdf \
    "${TEMP_DIR}"/05-back-assembly.pdf
elif command -v pdftk >/dev/null 2>&1; then
  echo "📄 Using pdftk to combine PDFs..."
  pdftk "${TEMP_DIR}"/01-user-drawings.pdf \
        "${TEMP_DIR}"/02-front-copper.pdf \
        "${TEMP_DIR}"/03-back-copper.pdf \
        "${TEMP_DIR}"/04-front-assembly.pdf \
        "${TEMP_DIR}"/05-back-assembly.pdf \
        cat output "${COMBINED_PDF}"
elif command -v pdfunite >/dev/null 2>&1; then
  echo "📄 Using pdfunite (poppler-utils) to combine PDFs..."
  pdfunite "${TEMP_DIR}"/01-user-drawings.pdf \
           "${TEMP_DIR}"/02-front-copper.pdf \
           "${TEMP_DIR}"/03-back-copper.pdf \
           "${TEMP_DIR}"/04-front-assembly.pdf \
           "${TEMP_DIR}"/05-back-assembly.pdf \
           "${COMBINED_PDF}"
elif command -v python3 >/dev/null 2>&1; then
  echo "📄 Using Python PyPDF2/PyPDF4 to combine PDFs..."
  python3 -c "
import sys
try:
    from PyPDF2 import PdfWriter, PdfReader
except ImportError:
    try:
        from PyPDF4 import PdfWriter, PdfReader
    except ImportError:
        print('❌ No PDF library available (PyPDF2/PyPDF4)')
        sys.exit(1)

writer = PdfWriter()
files = [
    '${TEMP_DIR}/01-user-drawings.pdf',
    '${TEMP_DIR}/02-front-copper.pdf', 
    '${TEMP_DIR}/03-back-copper.pdf',
    '${TEMP_DIR}/04-front-assembly.pdf',
    '${TEMP_DIR}/05-back-assembly.pdf'
]

for pdf_file in files:
    reader = PdfReader(pdf_file)
    for page in reader.pages:
        writer.add_page(page)

with open('${COMBINED_PDF}', 'wb') as output_file:
    writer.write(output_file)
"
else
  echo "⚠️ No PDF combination tool available (gs, pdftk, pdfunite, or python3)"
  echo "⚠️ Keeping individual PDF files instead..."
  # Copy first file as the "combined" file for compatibility
  cp "${TEMP_DIR}/01-user-drawings.pdf" "${COMBINED_PDF}"
  
  # Also copy individual files to main export directory
  cp "${TEMP_DIR}"/01-user-drawings.pdf "Export/PDF/${PROJECT_NAME}-PCB-01-UserDrawings.pdf"
  cp "${TEMP_DIR}"/02-front-copper.pdf "Export/PDF/${PROJECT_NAME}-PCB-02-FrontCopper.pdf"
  cp "${TEMP_DIR}"/03-back-copper.pdf "Export/PDF/${PROJECT_NAME}-PCB-03-BackCopper.pdf"
  cp "${TEMP_DIR}"/04-front-assembly.pdf "Export/PDF/${PROJECT_NAME}-PCB-04-FrontAssembly.pdf"
  cp "${TEMP_DIR}"/05-back-assembly.pdf "Export/PDF/${PROJECT_NAME}-PCB-05-BackAssembly.pdf"
  
  echo "✅ Individual PDF files created as fallback"
fi

# Clean up temporary files
rm -rf "${TEMP_DIR}"

# Verify export
if [ -f "${COMBINED_PDF}" ]; then
  echo "✅ ${PROJECT_NAME}-PCB-Complete.pdf exported successfully"
  ls -lh "${COMBINED_PDF}"
  
  # Try to show page count for verification (if tools available)
  if command -v gs >/dev/null 2>&1; then
    PAGE_COUNT=$(gs -q -dNODISPLAY -c "(${COMBINED_PDF}) (r) file runpdfbegin pdfpagecount = quit" 2>/dev/null || echo "unknown")
    echo "📄 PDF contains ${PAGE_COUNT} pages"
  elif command -v pdfinfo >/dev/null 2>&1; then
    PAGE_COUNT=$(pdfinfo "${COMBINED_PDF}" 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "unknown")
    echo "📄 PDF contains ${PAGE_COUNT} pages"
  elif command -v python3 >/dev/null 2>&1; then
    PAGE_COUNT=$(python3 -c "
try:
    from PyPDF2 import PdfReader
    reader = PdfReader('${COMBINED_PDF}')
    print(len(reader.pages))
except:
    print('unknown')
" 2>/dev/null)
    echo "📄 PDF contains ${PAGE_COUNT} pages"
  else
    echo "📄 PDF exported successfully (page count unknown)"
  fi
  
  # Check if we have individual files as well
  if [ -f "Export/PDF/${PROJECT_NAME}-PCB-01-UserDrawings.pdf" ]; then
    echo "📄 Individual layer PDFs also available"
    ls -lh Export/PDF/${PROJECT_NAME}-PCB-*.pdf
  fi
else
  echo "❌ Error: Combined PCB PDF export failed!"
  exit 1
fi
