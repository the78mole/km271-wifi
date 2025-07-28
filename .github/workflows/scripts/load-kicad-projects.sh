#!/bin/bash
set -e

# Script: load-kicad-projects.sh
# Purpose: Load KiCad projects from YAML configuration file and output as GitHub Actions matrix JSON
# Usage: load-kicad-projects.sh [--filter enabled|all] [--type main|extension|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../../../kicad-projects.yml"

# Default values
FILTER="enabled"
TYPE_FILTER="all"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --type)
            TYPE_FILTER="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--filter enabled|all] [--type main|extension|all]"
            echo ""
            echo "Options:"
            echo "  --filter  Filter projects by enabled status (default: enabled)"
            echo "  --type    Filter projects by type (default: all)"
            echo ""
            echo "Output: JSON matrix for GitHub Actions"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Check if the correct yq (mikefarah/yq) is available
YQ_CMD=""
if command -v /usr/local/bin/yq >/dev/null 2>&1; then
    YQ_CMD="/usr/local/bin/yq"
elif command -v yq >/dev/null 2>&1; then
    # Check if it's the correct yq version (mikefarah/yq)
    if yq --help 2>&1 | grep -q "mikefarah\|github.com/mikefarah"; then
        YQ_CMD="yq"
    fi
fi

# If correct yq is not available, use fallback
if [ -z "$YQ_CMD" ]; then
    echo "⚠️ yq (mikefarah/yq) not available, falling back to basic parsing..." >&2
    
    # Use awk to parse YAML more reliably
    projects_json=$(awk '
    BEGIN {
        in_projects = 0
        project_count = 0
        first = 1
        printf "["
    }
    
    /^projects:/ {
        in_projects = 1
        next
    }
    
    /^[a-zA-Z][^:]*:/ && in_projects {
        in_projects = 0
    }
    
    in_projects && /^[[:space:]]*-[[:space:]]*name:/ {
        # Extract name
        gsub(/^[[:space:]]*-[[:space:]]*name:[[:space:]]*"/, "")
        gsub(/"[[:space:]]*$/, "")
        name = $0
        
        # Read next lines for other properties
        getline; gsub(/^[[:space:]]*path:[[:space:]]*"/, ""); gsub(/"[[:space:]]*$/, ""); path = $0
        getline; gsub(/^[[:space:]]*description:[[:space:]]*"/, ""); gsub(/"[[:space:]]*$/, ""); description = $0
        getline; gsub(/^[[:space:]]*type:[[:space:]]*"/, ""); gsub(/"[[:space:]]*$/, ""); type = $0
        getline; gsub(/^[[:space:]]*enabled:[[:space:]]*/, ""); enabled = $0
        
        # Apply filters
        if("'$FILTER'" == "enabled" && enabled != "true") next
        if("'$TYPE_FILTER'" != "all" && type != "'$TYPE_FILTER'") next
        
        if(first == 0) printf ","
        printf "{\"name\":\"%s\",\"path\":\"%s\",\"description\":\"%s\",\"type\":\"%s\"}", name, path, description, type
        first = 0
        project_count++
    }
    
    END {
        printf "]"
    }
    ' "$CONFIG_FILE")
    
    # Extract global text variables using simple parsing (fallback method)
    text_vars=$(awk '
    BEGIN {
        in_text_vars = 0
        first = 1
        printf "{"
    }
    
    /^[[:space:]]*text_variables:/ {
        in_text_vars = 1
        next
    }
    
    /^[[:space:]]*[a-zA-Z][^:]*:/ && in_text_vars && !/^[[:space:]]*[A-Z_]+:/ {
        in_text_vars = 0
    }
    
    in_text_vars && /^[[:space:]]*[A-Z_]+:/ {
        gsub(/^[[:space:]]*/, "")
        split($0, parts, ":")
        key = parts[1]
        value = parts[2]
        gsub(/^[[:space:]]*"/, "", value)
        gsub(/"[[:space:]]*$/, "", value)
        gsub(/^[[:space:]]*/, "", value)
        
        if(first == 0) printf ","
        printf "\"%s\":\"%s\"", key, value
        first = 0
    }
    
    END {
        printf "}"
    }
    ' "$CONFIG_FILE")
    
    echo "{\"project\": $projects_json, \"text_variables\": $text_vars}"
    exit 0
fi

# Use yq to process YAML and create JSON matrix
echo "🔍 Loading KiCad projects configuration..." >&2

# Use a simpler approach - convert entire projects section to JSON first
ALL_PROJECTS=$($YQ_CMD eval '.projects' "$CONFIG_FILE" -o json)

# Load global text variables if they exist
GLOBAL_TEXT_VARS=$($YQ_CMD eval '.config.text_variables // {}' "$CONFIG_FILE" -o json 2>/dev/null || echo '{}')

# Then use jq for filtering and formatting
PROJECTS=$(echo "$ALL_PROJECTS" | jq --arg filter "$FILTER" --arg type_filter "$TYPE_FILTER" '
    map(select(
        ($filter == "all" or ($filter == "enabled" and .enabled == true)) and
        ($type_filter == "all" or .type == $type_filter)
    ) | {name, path, description, type})')

# Create final matrix JSON (compact format for GitHub Actions)
MATRIX_JSON="{\"project\": $(echo "$PROJECTS" | jq -c .), \"text_variables\": $(echo "$GLOBAL_TEXT_VARS" | jq -c .)}"
echo "$MATRIX_JSON"

echo "✅ Successfully loaded $(echo "$PROJECTS" | jq length) projects" >&2
