#!/bin/bash
set -e

# Script: export-schematics.sh
# Purpose: Export KiCad schematic files to PDF format
# Usage: export-schematics.sh --name PROJECT_NAME --path PROJECT_PATH --description PROJECT_DESCRIPTION

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Export KiCad schematic files to PDF format for documentation and review.

OPTIONS:
    -n, --name PROJ_NAME        Project name (e.g. "KM217-WiFi")
    -p, --path PROJ_PATH        Project path (e.g. "KM217-WiFi")
    -d, --description DESC      Project description (e.g. "Main KM217-WiFi Board")
    -h, --help                  Show this help message

EXAMPLES:
    $0 --name "KM217-WiFi" --path "KM217-WiFi" --description "Main Board"
    $0 -n "ETH_W5500" -p "EXTENSIONS/ETH_W5500" -d "Ethernet Extension"

OUTPUT:
    Creates Export/PDF/PROJECT_NAME-Schematics.pdf file.

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -p|--path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -d|--description)
            PROJECT_DESCRIPTION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Fallback to positional arguments for backward compatibility
if [[ -z "$PROJECT_NAME" && -n "$1" ]]; then
    PROJECT_NAME="$1"
    PROJECT_PATH="$2"
    PROJECT_DESCRIPTION="$3"
fi

# Validate required parameters
if [[ -z "$PROJECT_NAME" || -z "$PROJECT_PATH" || -z "$PROJECT_DESCRIPTION" ]]; then
    echo "❌ Error: Missing required parameters"
    show_help
    exit 1
fi

echo "📐 Exporting schematic to PDF for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

kicad-cli sch export pdf \
  --output "Export/PDF/${PROJECT_NAME}-Schematics.pdf" \
  ${PROJECT_NAME}.kicad_sch
  
# Verify export
if [ -f "Export/PDF/${PROJECT_NAME}-Schematics.pdf" ]; then
  echo "✅ Schematic PDF exported successfully"
  ls -lh Export/PDF/${PROJECT_NAME}-Schematics.pdf
else
  echo "❌ Error: Schematic PDF export failed!"
  exit 1
fi
