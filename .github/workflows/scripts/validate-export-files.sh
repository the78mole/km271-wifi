#!/bin/bash
set -e

# Script: validate-export-files.sh
# Purpose: Validate exported KiCad files for completeness and reasonable file sizes
# Usage: validate-export-files.sh --name PROJECT_NAME --path PROJECT_PATH --description PROJECT_DESCRIPTION

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate exported KiCad files for completeness and reasonable file sizes.
Checks PDFs, STEP files, and Gerber files for manufacturing readiness.

OPTIONS:
    -n, --name PROJ_NAME        Project name (e.g. "KM217-WiFi")
    -p, --path PROJ_PATH        Project path (e.g. "KM217-WiFi")
    -d, --description DESC      Project description (e.g. "Main KM217-WiFi Board")
    -h, --help                  Show this help message

EXAMPLES:
    $0 --name "KM217-WiFi" --path "KM217-WiFi" --description "Main Board"
    $0 -n "ETH_W5500" -p "EXTENSIONS/ETH_W5500" -d "Ethernet Extension"

VALIDATION:
    - PDF files (schematics, PCB top/bottom views)
    - STEP 3D model files
    - Gerber manufacturing files
    - File size sanity checks

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

echo "🧪 Validating exported files for ${PROJECT_DESCRIPTION}..."
cd "${PROJECT_PATH}/Export"

# Check if critical files exist and have reasonable sizes
critical_files="PDF/${PROJECT_NAME}-Schematics.pdf PDF/${PROJECT_NAME}-PCB-Top.pdf PDF/${PROJECT_NAME}-PCB-Bottom.pdf 3D/${PROJECT_NAME}.step"

for file in $critical_files; do
  if [ -f "$file" ]; then
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    if [ "$size" -gt 1000 ]; then
      echo "✅ $file ($size bytes)"
    else
      echo "⚠️ $file seems too small ($size bytes)"
    fi
  else
    echo "❌ Missing: $file"
    exit 1
  fi
done

# Check Gerber files
gerber_count=$(ls -1 Gerbers/*.g* 2>/dev/null | wc -l || echo "0")
if [ "$gerber_count" -lt 5 ]; then
  echo "⚠️ Only $gerber_count Gerber files found, expected at least 5"
else
  echo "✅ $gerber_count Gerber files generated"
fi

echo "🎉 File validation completed"
