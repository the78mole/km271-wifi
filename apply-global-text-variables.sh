#!/bin/bash
set -e

# Script: apply-global-text-variables.sh
# Purpose: Apply global text variables from kicad-projects.yml to all enabled KiCad projects
# Usage: apply-global-text-variables.sh [options]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${CYAN}🔧 $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Default values
DRY_RUN=false
VERBOSE=false
REVISION=""
TYPE_FILTER="all"

# Show help
show_help() {
    cat << EOF
Usage: $0 [options]

Apply global text variables from kicad-projects.yml to all enabled KiCad projects.

Options:
  --revision REVISION  Set a specific revision for all projects (overrides YAML config)
  --type TYPE          Apply to specific project types only (main|extension|all, default: all)
  --dry-run           Show what would be done without making changes
  --verbose, -v       Show detailed information
  --help, -h          Show this help message

Examples:
  $0                              # Apply global text variables from YAML to all projects
  $0 --revision v2.0.0            # Set revision v2.0.0 for all projects 
  $0 --type main --dry-run        # Show what would be applied to main projects only
  $0 --verbose                    # Apply with detailed logging

The script reads global text variables from .github/kicad-projects.yml and applies
them to all enabled KiCad projects using the update-kicad-text-variables.sh tool.
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --revision)
            REVISION="$2"
            shift 2
            ;;
        --type)
            TYPE_FILTER="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
        *)
            print_error "Unexpected argument: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Check if update script exists
UPDATE_SCRIPT="$SCRIPT_DIR/update-kicad-text-variables.sh"
if [ ! -f "$UPDATE_SCRIPT" ]; then
    print_error "Update script not found: $UPDATE_SCRIPT"
    exit 1
fi

print_header "Applying Global Text Variables"

# Load projects and text variables from YAML
LOAD_SCRIPT="$SCRIPT_DIR/.github/workflows/scripts/load-kicad-projects.sh"
if [ ! -f "$LOAD_SCRIPT" ]; then
    print_error "Load script not found: $LOAD_SCRIPT"
    exit 1
fi

print_info "Loading project configuration..."
PROJECT_DATA=$("$LOAD_SCRIPT" --type "$TYPE_FILTER")

# Parse projects and text variables using jq
if ! command -v jq >/dev/null 2>&1; then
    print_error "jq is required but not installed. Please install jq to use this script."
    exit 1
fi

# Extract projects and text variables
PROJECTS=$(echo "$PROJECT_DATA" | jq -r '.project[] | @base64')
TEXT_VARS=$(echo "$PROJECT_DATA" | jq -r '.text_variables')

if [ "$VERBOSE" = true ]; then
    print_info "Global text variables from YAML:"
    echo "$TEXT_VARS" | jq -r 'to_entries[] | "  \(.key) = \(.value)"'
    echo ""
fi

# Process each project
for project_data in $PROJECTS; do
    # Decode project data
    project=$(echo "$project_data" | base64 --decode)
    
    name=$(echo "$project" | jq -r '.name')
    path=$(echo "$project" | jq -r '.path')
    description=$(echo "$project" | jq -r '.description')
    type=$(echo "$project" | jq -r '.type')
    
    print_info "Processing project: $name ($type)"
    
    # Find the .kicad_pro file
    kicad_pro_file=""
    if [ -f "$path/$name.kicad_pro" ]; then
        kicad_pro_file="$path/$name.kicad_pro"
    elif [ -f "$path.kicad_pro" ]; then
        kicad_pro_file="$path.kicad_pro"
    else
        # Find any .kicad_pro file in the directory
        kicad_pro_file=$(find "$path" -maxdepth 1 -name "*.kicad_pro" | head -1)
    fi
    
    if [ -z "$kicad_pro_file" ]; then
        print_warning "No .kicad_pro file found for project $name in $path"
        continue
    fi
    
    # Build update command arguments
    update_args=("--project" "$kicad_pro_file")
    
    if [ "$DRY_RUN" = true ]; then
        update_args+=("--dry-run")
    fi
    
    if [ "$VERBOSE" = true ]; then
        update_args+=("--verbose")
    fi
    
    # Add revision if specified
    if [ -n "$REVISION" ]; then
        update_args+=("--revision" "$REVISION")
    fi
    
    # Add global text variables
    title=$(echo "$TEXT_VARS" | jq -r '.TITLE // empty')
    company=$(echo "$TEXT_VARS" | jq -r '.COMPANY // empty')
    author=$(echo "$TEXT_VARS" | jq -r '.AUTHOR // empty')
    creation_date=$(echo "$TEXT_VARS" | jq -r '.CREATION_DATE // empty')
    
    if [ -n "$title" ]; then
        update_args+=("--title" "$title")
    fi
    
    if [ -n "$company" ]; then
        update_args+=("--company" "$company")
    fi
    
    if [ -n "$author" ]; then
        update_args+=("--author" "$author")
    fi
    
    if [ -n "$creation_date" ]; then
        update_args+=("--creation-date" "$creation_date")
    fi
    
    # Run the update script
    if [ "$VERBOSE" = true ]; then
        print_info "Running: $UPDATE_SCRIPT ${update_args[*]}"
    fi
    
    if "$UPDATE_SCRIPT" "${update_args[@]}"; then
        print_success "Updated $name"
    else
        print_error "Failed to update $name"
    fi
    
    echo ""
done

if [ "$DRY_RUN" = true ]; then
    print_info "Dry run completed. No changes were made."
else
    print_success "Global text variables applied successfully!"
fi
