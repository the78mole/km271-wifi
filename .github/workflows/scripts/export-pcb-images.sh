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

echo "🖼️ Exporting PCB images for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Export assembly diagram (top)
kicad-cli pcb export svg \
  --output "Export/Images/${PROJECT_NAME}-Assembly-Top.svg" \
  --layers "F.Cu,F.Silkscreen,F.Mask,Edge.Cuts" \
  --exclude-drawing-sheet \
  ${PROJECT_NAME}.kicad_pcb
  
# Export assembly diagram (bottom)
kicad-cli pcb export svg \
  --output "Export/Images/${PROJECT_NAME}-Assembly-Bottom.svg" \
  --layers "B.Cu,B.Silkscreen,B.Mask,Edge.Cuts" \
  --exclude-drawing-sheet \
  ${PROJECT_NAME}.kicad_pcb
  
# Convert SVGs to PNG for better compatibility
if command -v convert >/dev/null 2>&1; then
  convert "Export/Images/${PROJECT_NAME}-Assembly-Top.svg" "Export/Images/${PROJECT_NAME}-Assembly-Top.png"
  convert "Export/Images/${PROJECT_NAME}-Assembly-Bottom.svg" "Export/Images/${PROJECT_NAME}-Assembly-Bottom.png"
  echo "✅ PNG images generated"
else
  echo "⚠️ ImageMagick not available, skipping PNG conversion"
fi

ls -la Export/Images/
