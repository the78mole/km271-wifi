#!/bin/bash
set -e

# Script: export-3d-models.sh
# Purpose: Export 3D models from KiCad PCB files to STEP format
# Usage: export-3d-models.sh --name PROJECT_NAME --path PROJECT_PATH --description PROJECT_DESCRIPTION

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Export 3D models from KiCad PCB files to STEP format for CAD integration.
Handles missing 3D model warnings gracefully.

OPTIONS:
    -n, --name PROJ_NAME        Project name (e.g. "KM217-WiFi")
    -p, --path PROJ_PATH        Project path (e.g. "KM217-WiFi")
    -d, --description DESC      Project description (e.g. "Main KM217-WiFi Board")
    -h, --help                  Show this help message

EXAMPLES:
    $0 --name "KM217-WiFi" --path "KM217-WiFi" --description "Main Board"
    $0 -n "ETH_W5500" -p "EXTENSIONS/ETH_W5500" -d "Ethernet Extension"

OUTPUT:
    Creates Export/3D/PROJECT_NAME.step file for 3D CAD import.

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

echo "🎯 Exporting 3D models for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}"

# Export STEP file for 3D CAD (ignore warnings about missing 3D models)
kicad-cli pcb export step \
  --output "Export/3D/${PROJECT_NAME}.step" \
  --drill-origin \
  --grid-origin \
  ${PROJECT_NAME}.kicad_pcb || {
    echo "⚠️ STEP export completed with warnings (missing 3D models)"
    # Check if file was actually created despite warnings
    if [ -f "Export/3D/${PROJECT_NAME}.step" ]; then
      echo "✅ STEP file created successfully despite warnings"
    else
      echo "❌ STEP export failed completely"
      exit 1
    fi
  }
  
echo "✅ STEP model exported"
ls -la Export/3D/
