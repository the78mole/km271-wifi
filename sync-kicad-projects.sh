#!/bin/bash
set -e

# Script: sync-kicad-projects.sh
# Purpose: Synchronize text variables from kicad-projects.yml to all KiCad project files
# Usage: sync-kicad-projects.sh [options]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/kicad-projects.yml"

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
TYPE_FILTER="all"

# Show help
show_help() {
    cat << EOF
Usage: $0 [options]

Synchronize text variables from kicad-projects.yml to all KiCad project files.
The script will:
1. Read global text variables and project configuration from kicad-projects.yml
2. Get current Git tag as REVISION
3. Update text_variables section in all .kicad_pro files
4. Update title blocks in .kicad_sch and .kicad_pcb files to use variable references

Options:
  --type TYPE          Process specific project types only (main|extension|all, default: all)
  --dry-run           Show what would be done without making changes
  --verbose, -v       Show detailed information
  --help, -h          Show this help message

Examples:
  $0                              # Sync all enabled projects
  $0 --type main --dry-run        # Show what would be done for main projects only
  $0 --verbose                    # Sync with detailed logging

The script uses kicad-projects.yml as single source of truth for project configuration
and the current Git tag for the REVISION variable.
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
    print_error "jq is required but not installed. Please install jq to use this script."
    exit 1
fi

print_header "Synchronizing KiCad Project Text Variables"

# Get current Git tag for REVISION
GIT_TAG=$(git describe --tags --exact-match HEAD 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$GIT_TAG" ]; then
    print_warning "No Git tag found. Using 'development' as REVISION."
    GIT_TAG="development"
fi

# Generate current date for CREATION_DATE
CREATION_DATE=$(date +%Y-%m-%d)

if [ "$VERBOSE" = true ]; then
    print_info "Using Git tag as REVISION: $GIT_TAG"
    print_info "Using current date as CREATION_DATE: $CREATION_DATE"
fi

# Load projects and text variables from YAML
LOAD_SCRIPT="$SCRIPT_DIR/.github/workflows/scripts/load-kicad-projects.sh"
if [ ! -f "$LOAD_SCRIPT" ]; then
    print_error "Load script not found: $LOAD_SCRIPT"
    exit 1
fi

print_info "Loading project configuration..."
PROJECT_DATA=$("$LOAD_SCRIPT" --type "$TYPE_FILTER")

# Parse projects and text variables using jq
PROJECTS=$(echo "$PROJECT_DATA" | jq -r '.project[] | @base64')
TEXT_VARS=$(echo "$PROJECT_DATA" | jq -r '.text_variables')

if [ "$VERBOSE" = true ]; then
    print_info "Global text variables from kicad-projects.yml:"
    echo "$TEXT_VARS" | jq -r 'to_entries[] | "  \(.key) = \(.value)"'
    echo ""
fi

# Function to update text variables in .kicad_pro file
update_kicad_pro_text_variables() {
    local kicad_pro_file="$1"
    local revision="$2"
    local company="$3"
    local author="$4"
    local creation_date="$5"
    
    if [ ! -f "$kicad_pro_file" ]; then
        print_warning "Project file not found: $kicad_pro_file"
        return 1
    fi
    
    # Check if updates are needed (excluding CREATION_DATE which always gets updated)
    local needs_update=false
    if ! jq -e --arg revision "$revision" --arg company "$company" --arg author "$author" \
        '.text_variables.REVISION == $revision and .text_variables.COMPANY == $company and .text_variables.AUTHOR == $author' \
        "$kicad_pro_file" >/dev/null 2>&1; then
        needs_update=true
    fi
    
    if [ "$DRY_RUN" = true ]; then
        if [ "$needs_update" = true ]; then
            print_info "Would update text variables in $(basename "$kicad_pro_file")"
        elif [ "$VERBOSE" = true ]; then
            print_info "$(basename "$kicad_pro_file") text variables are up-to-date (except CREATION_DATE)"
        fi
        return 0
    fi
    
    # Always update, but only report if significant changes were made
    # Create backup
    cp "$kicad_pro_file" "$kicad_pro_file.backup"
    
    # Build the text_variables object
    local text_vars_json
    text_vars_json=$(jq -n \
        --arg revision "$revision" \
        --arg company "$company" \
        --arg author "$author" \
        --arg creation_date "$creation_date" \
        '{
            REVISION: $revision,
            COMPANY: $company,
            AUTHOR: $author,
            CREATION_DATE: $creation_date
        }')
    
    # Update the .kicad_pro file
    if jq --argjson text_vars "$text_vars_json" '.text_variables = $text_vars' "$kicad_pro_file" > "$kicad_pro_file.tmp"; then
        mv "$kicad_pro_file.tmp" "$kicad_pro_file"
        
        if [ "$needs_update" = true ]; then
            print_success "Updated text variables in $(basename "$kicad_pro_file")"
            if [ "$VERBOSE" = true ]; then
                print_info "  REVISION = $revision"
                print_info "  COMPANY = $company"
                print_info "  AUTHOR = $author"  
                print_info "  CREATION_DATE = $creation_date (always updated)"
            fi
        elif [ "$VERBOSE" = true ]; then
            print_info "Refreshed CREATION_DATE in $(basename "$kicad_pro_file")"
        fi
    else
        print_error "Failed to update $(basename "$kicad_pro_file")"
        # Restore backup
        mv "$kicad_pro_file.backup" "$kicad_pro_file"
        return 1
    fi
    
    # Remove backup if successful
    rm -f "$kicad_pro_file.backup"
    return 0
}

# Function to update title blocks in .kicad_sch and .kicad_pcb files to use text variable references
update_title_block_to_use_variables() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        if [ "$VERBOSE" = true ]; then
            print_warning "File not found: $(basename "$file")"
        fi
        return 0
    fi
    
    # Check if updates are needed
    local needs_update=false
    if ! grep -q '\${CREATION_DATE}' "$file" || \
       ! grep -q '\${COMPANY}' "$file" || \
       ! grep -q '\${AUTHOR}' "$file" || \
       ! grep -q '\${REVISION}' "$file"; then
        needs_update=true
    fi
    
    if [ "$DRY_RUN" = true ]; then
        if [ "$needs_update" = true ]; then
            print_info "Would update $(basename "$file") title block to use text variable references"
        elif [ "$VERBOSE" = true ]; then
            print_info "$(basename "$file") title block already uses text variable references"
        fi
        return 0
    fi
    
    if [ "$needs_update" = false ]; then
        if [ "$VERBOSE" = true ]; then
            print_info "$(basename "$file") title block already uses text variable references"
        fi
        return 0
    fi
    
    # Create backup
    cp "$file" "$file.backup"
    
    local changes_made=false
    
    # Update date field to use ${CREATION_DATE}
    if grep -q "^[[:space:]]*(date " "$file"; then
        if ! grep -q "^[[:space:]]*\t\t(date \"\${CREATION_DATE}\")" "$file"; then
            sed -i 's/^[[:space:]]*(date .*/\t\t(date "${CREATION_DATE}")/' "$file"
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "  Updated date field to use \${CREATION_DATE}"
            fi
        fi
    fi
    
    # Update company field to use ${COMPANY}
    if grep -q "^[[:space:]]*(company " "$file"; then
        if ! grep -q "^[[:space:]]*\t\t(company \"\${COMPANY}\")" "$file"; then
            sed -i 's/^[[:space:]]*(company .*/\t\t(company "${COMPANY}")/' "$file"
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "  Updated company field to use \${COMPANY}"
            fi
        fi
    fi
    
    # Update comment 1 field to use ${AUTHOR}
    if grep -q "^[[:space:]]*(comment 1 " "$file"; then
        if ! grep -q "^[[:space:]]*\t\t(comment 1 \"Author: \${AUTHOR}\")" "$file"; then
            sed -i 's/^[[:space:]]*(comment 1 .*/\t\t(comment 1 "Author: ${AUTHOR}")/' "$file"  
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "  Updated comment 1 field to use \${AUTHOR}"
            fi
        fi
    fi
    
    # Ensure rev field uses ${REVISION}
    if grep -q "^[[:space:]]*(rev " "$file"; then
        if ! grep -q "^[[:space:]]*\t\t(rev \"\${REVISION}\")" "$file"; then
            sed -i 's/^[[:space:]]*(rev .*/\t\t(rev "${REVISION}")/' "$file"
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "  Updated rev field to use \${REVISION}"
            fi
        fi
    fi
    
    if [ "$changes_made" = true ]; then
        print_success "Updated $(basename "$file") to use text variable references"
    fi
    
    # Remove backup if successful
    rm -f "$file.backup"
}

# Process each project
project_count=0
while IFS= read -r project_data; do
    # Skip empty lines
    [ -z "$project_data" ] && continue
    
    # Decode project data
    project=$(echo "$project_data" | base64 --decode)
    
    name=$(echo "$project" | jq -r '.name')
    path=$(echo "$project" | jq -r '.path')
    description=$(echo "$project" | jq -r '.description')
    type=$(echo "$project" | jq -r '.type')
    
    project_count=$((project_count + 1))
    
    echo ""
    print_header "Processing Project $project_count: $name"
    if [ "$VERBOSE" = true ]; then
        print_info "Type: $type"
        print_info "Path: $path"
        print_info "Description: $description"
    fi
    
    # Find the .kicad_pro file
    kicad_pro_file=""
    if [ -f "$path/$name.kicad_pro" ]; then
        kicad_pro_file="$path/$name.kicad_pro"
    elif [ -f "$path.kicad_pro" ]; then
        kicad_pro_file="$path.kicad_pro"
    else
        # Find any .kicad_pro file in the directory
        kicad_pro_file=$(find "$path" -maxdepth 1 -name "*.kicad_pro" 2>/dev/null | head -1)
    fi
    
    if [ -z "$kicad_pro_file" ]; then
        print_warning "No .kicad_pro file found for project $name in $path"
        continue
    fi
    
    # Extract text variables from YAML
    company=$(echo "$TEXT_VARS" | jq -r '.COMPANY // "Unknown"')
    author=$(echo "$TEXT_VARS" | jq -r '.AUTHOR // "Unknown"')  
    
    # Use dynamically generated creation date
    creation_date="$CREATION_DATE"
    
    # Update .kicad_pro file with text variables
    if update_kicad_pro_text_variables "$kicad_pro_file" "$GIT_TAG" "$company" "$author" "$creation_date"; then
        
        # Find and update related schematic and PCB files
        project_dir=$(dirname "$kicad_pro_file")
        kicad_sch_file=$(find "$project_dir" -maxdepth 1 -name "*.kicad_sch" 2>/dev/null | head -1)
        kicad_pcb_file=$(find "$project_dir" -maxdepth 1 -name "*.kicad_pcb" 2>/dev/null | head -1)
        
        # Update schematic file
        if [ -n "$kicad_sch_file" ]; then
            update_title_block_to_use_variables "$kicad_sch_file"
        elif [ "$VERBOSE" = true ]; then
            print_info "No schematic file found"
        fi
        
        # Update PCB file  
        if [ -n "$kicad_pcb_file" ]; then
            update_title_block_to_use_variables "$kicad_pcb_file"
        elif [ "$VERBOSE" = true ]; then
            print_info "No PCB file found"
        fi
        
    else
        print_error "Failed to update project $name"
    fi
done << EOF
$(echo "$PROJECTS")
EOF

echo ""
if [ "$DRY_RUN" = true ]; then
    print_info "Dry run completed. No changes were made."
    print_info "Processed $project_count projects"
else
    print_success "Successfully synchronized $project_count KiCad projects!"
    print_info "All projects now use:"
    print_info "- REVISION from Git tag: $GIT_TAG"
    print_info "- CREATION_DATE: $CREATION_DATE (generated at sync time)"
    print_info "- Global text variables from kicad-projects.yml"
    print_info "- Text variable references in title blocks"
fi
