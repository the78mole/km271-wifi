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

echo "📄 Exporting PCB layout to PDF for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Export PCB top layer
kicad-cli pcb export pdf \
  --output "Export/PDF/${PROJECT_NAME}-PCB-Top.pdf" \
  --layers "F.Cu,F.Silkscreen,F.Mask,Edge.Cuts" \
  ${PROJECT_NAME}.kicad_pcb
  
# Export PCB bottom layer  
kicad-cli pcb export pdf \
  --output "Export/PDF/${PROJECT_NAME}-PCB-Bottom.pdf" \
  --layers "B.Cu,B.Silkscreen,B.Mask,Edge.Cuts" \
  ${PROJECT_NAME}.kicad_pcb
  
# Verify exports
for pdf in "Export/PDF/${PROJECT_NAME}-PCB-Top.pdf" "Export/PDF/${PROJECT_NAME}-PCB-Bottom.pdf"; do
  if [ -f "$pdf" ]; then
    echo "✅ $(basename $pdf) exported successfully"
    ls -lh "$pdf"
  else
    echo "❌ Error: $(basename $pdf) export failed!"
    exit 1
  fi
done
