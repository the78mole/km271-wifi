#!/bin/bash
set -e

# Script: export-gerber.sh
# Purpose: Export Gerber and drill files from KiCad PCB files
# Usage: export-gerber.sh --name PROJECT_NAME --path PROJECT_PATH --description PROJECT_DESCRIPTION

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Export Gerber and drill files from KiCad PCB files for manufacturing.
Includes copper layers, solder mask, silkscreen, paste layers, and edge cuts.

OPTIONS:
    -n, --name PROJ_NAME        Project name (e.g. "KM217-WiFi")
    -p, --path PROJ_PATH        Project path (e.g. "KM217-WiFi")
    -d, --description DESC      Project description (e.g. "Main KM217-WiFi Board")
    -h, --help                  Show this help message

EXAMPLES:
    $0 --name "KM217-WiFi" --path "KM217-WiFi" --description "Main Board"
    $0 -n "ETH_W5500" -p "EXTENSIONS/ETH_W5500" -d "Ethernet Extension"

OUTPUT:
    Creates Export/Gerbers/ and Export/Drill/ directories with manufacturing files.

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

echo "🔧 Exporting Gerber files for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Export Gerber files
kicad-cli pcb export gerbers \
  --output Export/Gerbers/ \
  --layers "F.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts" \
  --precision 6 \
  --no-x2 \
  --use-drill-file-origin \
  ${PROJECT_NAME}.kicad_pcb
  
# Export drill files separately for better control
kicad-cli pcb export drill \
  --output Export/Drill/ \
  --format gerber \
  --drill-origin plot \
  --gerber-precision 6 \
  ${PROJECT_NAME}.kicad_pcb
  
# List generated files
echo "📋 Generated Gerber files:"
ls -la Export/Gerbers/
echo "📋 Generated Drill files:"
ls -la Export/Drill/
