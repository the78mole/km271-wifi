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

# Combine all PDFs into one using pdftk
echo "📄 Combining all layers into single PDF using pdftk..."
COMBINED_PDF="Export/PDF/${PROJECT_NAME}-PCB-Complete.pdf"

pdftk "${TEMP_DIR}"/01-user-drawings.pdf \
      "${TEMP_DIR}"/02-front-copper.pdf \
      "${TEMP_DIR}"/03-back-copper.pdf \
      "${TEMP_DIR}"/04-front-assembly.pdf \
      "${TEMP_DIR}"/05-back-assembly.pdf \
      cat output "${COMBINED_PDF}"

# Clean up temporary files
rm -rf "${TEMP_DIR}"

# Verify export
if [ -f "${COMBINED_PDF}" ]; then
  echo "✅ ${PROJECT_NAME}-PCB-Complete.pdf exported successfully (5 pages)"
  ls -lh "${COMBINED_PDF}"
  
  # Show page count using pdftk
  PAGE_COUNT=$(pdftk "${COMBINED_PDF}" dump_data 2>/dev/null | grep NumberOfPages | awk '{print $2}' || echo "5")
  echo "📄 PDF contains ${PAGE_COUNT} pages"
else
  echo "❌ Error: Combined PCB PDF export failed!"
  exit 1
fi
