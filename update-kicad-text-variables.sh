#!/bin/bash
set -e

# Script: update-kicad-text-variables.sh
# Purpose: Update KiCad project text variables and title blocks
# Usage: update-kicad-text-variables.sh --project <path> [options]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
print_header() { echo -e "${BLUE}🔧 $1${NC}"; }

# Default values
PROJECT_PATH=""
REVISION=""
TITLE=""
COMPANY=""
AUTHOR=""
CREATION_DATE=""
VERBOSE=false
DRY_RUN=false

# Help function
show_help() {
    echo "Usage: $0 --project <path> [options]"
    echo ""
    echo "Update KiCad project text variables and title blocks"
    echo ""
    echo "Required:"
    echo "  --project PATH        Path to KiCad project directory or .kicad_pro file"
    echo ""
    echo "Text Variables:"
    echo "  --revision REV        Set revision text variable"
    echo "  --title TITLE         Set title text variable"
    echo "  --company COMPANY     Set company text variable"
    echo "  --author AUTHOR       Set author text variable"
    echo "  --creation-date DATE  Set creation date text variable"
    echo ""
    echo "Options:"
    echo "  --verbose, -v         Show detailed information"
    echo "  --dry-run            Show what would be done without making changes"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --project KM217-WiFi --revision v1.2.0"
    echo "  $0 --project KM217-WiFi --revision v1.2.0 --title \"KM217-WiFi Board\" --company \"MyCompany\""
    echo "  $0 --project KM217-WiFi --revision v1.2.0 --author \"John Doe\" --creation-date \"2025-07-28\""
    echo "  $0 --project KM217-WiFi --revision v1.2.0 --dry-run"
    echo ""
    echo "Title Block Mapping:"
    echo "  AUTHOR -> comment 1 (with 'Author: ' prefix)"
    echo "  COMPANY -> company"
    echo "  CREATION_DATE -> date"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --revision)
            REVISION="$2"
            shift 2
            ;;
        --title)
            TITLE="$2"
            shift 2
            ;;
        --company)
            COMPANY="$2"
            shift 2
            ;;
        --author)
            AUTHOR="$2"
            shift 2
            ;;
        --creation-date)
            CREATION_DATE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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

# Validate required arguments
if [ -z "$PROJECT_PATH" ]; then
    print_error "Project path is required!"
    echo ""
    show_help
    exit 1
fi

# Check if at least one text variable is provided
if [ -z "$REVISION" ] && [ -z "$TITLE" ] && [ -z "$COMPANY" ] && [ -z "$AUTHOR" ] && [ -z "$CREATION_DATE" ]; then
    print_error "At least one text variable must be specified!"
    echo ""
    show_help
    exit 1
fi

# Check if project path is a file or directory
if [ -f "$PROJECT_PATH" ] && [[ "$PROJECT_PATH" == *.kicad_pro ]]; then
    # Direct path to .kicad_pro file
    KICAD_PRO_FILE="$PROJECT_PATH"
elif [ -d "$PROJECT_PATH" ]; then
    # Directory path - find .kicad_pro file
    KICAD_PRO_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.kicad_pro" | head -1)
    if [ -z "$KICAD_PRO_FILE" ]; then
        print_error "No .kicad_pro file found in directory $PROJECT_PATH"
        exit 1
    fi
else
    print_error "Project path does not exist or is not a valid .kicad_pro file: $PROJECT_PATH"
    exit 1
fi

PROJECT_NAME=$(basename "$KICAD_PRO_FILE" .kicad_pro)
print_header "Updating KiCad Text Variables for: $PROJECT_NAME"

# Check if jq is available (more important than kicad-cli for this task)
if ! command -v jq >/dev/null 2>&1; then
    print_warning "jq not found. Will use sed fallback (less reliable)."
    USE_JQ=false
else
    USE_JQ=true
fi

if [ "$VERBOSE" = true ]; then
    print_info "Using project file: $KICAD_PRO_FILE"
    
    if command -v kicad-cli >/dev/null 2>&1; then
        KICAD_VERSION=$(kicad-cli version 2>/dev/null || echo "unknown")
        print_info "KiCad CLI version: $KICAD_VERSION"
    else
        print_info "KiCad CLI not available (not required for this operation)"
    fi
    
    if [ "$USE_JQ" = true ]; then
        print_info "Using jq for safe JSON manipulation"
    else
        print_info "Using sed fallback for JSON manipulation"
    fi
fi

# Function to safely update JSON using jq
update_text_variable() {
    local file="$1"
    local var_name="$2"
    local var_value="$3"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would set text variable '$var_name' = '$var_value' in $(basename "$file")"
        return 0
    fi
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Update text variable using jq
    if [ "$USE_JQ" = true ]; then
        # Use jq for safe JSON manipulation
        jq --arg name "$var_name" --arg value "$var_value" \
           '.text_variables[$name] = $value' \
           "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        
        if [ $? -eq 0 ]; then
            print_success "Updated text variable '$var_name' = '$var_value'"
        else
            print_error "Failed to update text variable '$var_name'"
            # Restore backup
            mv "$file.backup" "$file"
            return 1
        fi
    else
        print_warning "Using sed fallback for JSON manipulation (less safe)"
        
        # Check if text_variables section exists
        if ! grep -q '"text_variables"' "$file"; then
            # Add text_variables section before the closing brace
            sed -i '$ s/}/  "text_variables": {}\n}/' "$file"
        fi
        
        # Check if the specific variable already exists
        if grep -q "\"$var_name\"" "$file"; then
            # Update existing variable
            sed -i "s/\"$var_name\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"$var_name\": \"$var_value\"/" "$file"
        else
            # Add new variable to text_variables section
            if grep -q '"text_variables": {}' "$file"; then
                # Replace empty text_variables with our variable
                sed -i "s/\"text_variables\": {}/\"text_variables\": {\n    \"$var_name\": \"$var_value\"\n  }/" "$file"
            else
                # Add to existing text_variables section
                sed -i "/\"text_variables\"[[:space:]]*:[[:space:]]*{/a\\    \"$var_name\": \"$var_value\"," "$file"
            fi
        fi
        
        print_success "Updated text variable '$var_name' = '$var_value' (using sed)"
    fi
    
    # Remove backup if successful
    rm -f "$file.backup"
}

# Function to update title block fields in .kicad_sch and .kicad_pcb files to use text variable references
update_title_block_to_use_variables() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        if [ "$VERBOSE" = true ]; then
            print_warning "File not found: $(basename "$file")"
        fi
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would update $(basename "$file") title block to use text variable references"
        return 0
    fi
    
    # Create backup
    cp "$file" "$file.backup"
    
    local changes_made=false
    
    # Update date field to use ${CREATION_DATE}
    if grep -q "^[[:space:]]*(date " "$file"; then
        if ! grep -q "^[[:space:]]*(date \"\${CREATION_DATE}\")" "$file"; then
            sed -i 's/^[[:space:]]*(date .*/(date "${CREATION_DATE}")/' "$file"
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "Updated date field to use \${CREATION_DATE}"
            fi
        fi
    fi
    
    # Update company field to use ${COMPANY}
    if grep -q "^[[:space:]]*(company " "$file"; then
        if ! grep -q "^[[:space:]]*(company \"\${COMPANY}\")" "$file"; then
            sed -i 's/^[[:space:]]*(company .*/(company "${COMPANY}")/' "$file"
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "Updated company field to use \${COMPANY}"
            fi
        fi
    fi
    
    # Update comment 1 field to use ${AUTHOR}
    if grep -q "^[[:space:]]*(comment 1 " "$file"; then
        if ! grep -q "^[[:space:]]*(comment 1 \"Author: \${AUTHOR}\")" "$file"; then
            sed -i 's/^[[:space:]]*(comment 1 .*/(comment 1 "Author: ${AUTHOR}")/' "$file"
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "Updated comment 1 field to use \${AUTHOR}"
            fi
        fi
    fi
    
    # Note: rev field should already use ${REVISION}, but let's ensure it
    if grep -q "^[[:space:]]*(rev " "$file"; then
        if ! grep -q "^[[:space:]]*(rev \"\${REVISION}\")" "$file"; then
            sed -i 's/^[[:space:]]*(rev .*/(rev "${REVISION}")/' "$file"
            changes_made=true
            if [ "$VERBOSE" = true ]; then
                print_info "Updated rev field to use \${REVISION}"
            fi
        fi
    fi
    
    if [ "$changes_made" = true ]; then
        print_success "Updated $(basename "$file") to use text variable references"
    else
        if [ "$VERBOSE" = true ]; then
            print_info "$(basename "$file") already uses text variable references"
        fi
    fi
    
    # Remove backup if successful
    rm -f "$file.backup"
}

echo ""

# Update text variables in project file
if [ -n "$REVISION" ]; then
    update_text_variable "$KICAD_PRO_FILE" "REVISION" "$REVISION"
fi

if [ -n "$TITLE" ]; then
    update_text_variable "$KICAD_PRO_FILE" "TITLE" "$TITLE"
fi

if [ -n "$COMPANY" ]; then
    update_text_variable "$KICAD_PRO_FILE" "COMPANY" "$COMPANY"
fi

if [ -n "$AUTHOR" ]; then
    update_text_variable "$KICAD_PRO_FILE" "AUTHOR" "$AUTHOR"
fi

if [ -n "$CREATION_DATE" ]; then
    update_text_variable "$KICAD_PRO_FILE" "CREATION_DATE" "$CREATION_DATE"
fi

# Find related schematic and PCB files
KICAD_SCH_FILE=$(find "$(dirname "$KICAD_PRO_FILE")" -maxdepth 1 -name "*.kicad_sch" | head -1)
KICAD_PCB_FILE=$(find "$(dirname "$KICAD_PRO_FILE")" -maxdepth 1 -name "*.kicad_pcb" | head -1)

# Update title blocks in schematic and PCB files to use text variable references
if [ -n "$KICAD_SCH_FILE" ] || [ -n "$KICAD_PCB_FILE" ]; then
    echo ""
    print_header "Updating Title Blocks to Use Text Variable References"
    
    # Update schematic file
    if [ -n "$KICAD_SCH_FILE" ]; then
        if [ "$VERBOSE" = true ]; then
            print_info "Updating schematic file: $(basename "$KICAD_SCH_FILE")"
        fi
        update_title_block_to_use_variables "$KICAD_SCH_FILE"
    fi
    
    # Update PCB file
    if [ -n "$KICAD_PCB_FILE" ]; then
        if [ "$VERBOSE" = true ]; then
            print_info "Updating PCB file: $(basename "$KICAD_PCB_FILE")"
        fi
        update_title_block_to_use_variables "$KICAD_PCB_FILE"
    fi
    
    if [ "$VERBOSE" = true ]; then
        if [ -z "$KICAD_SCH_FILE" ]; then
            print_warning "No schematic file found"
        fi
        if [ -z "$KICAD_PCB_FILE" ]; then
            print_warning "No PCB file found"
        fi
    fi
fi

# Show current text variables
if [ "$VERBOSE" = true ] && [ "$DRY_RUN" = false ]; then
    echo ""
    print_header "Current Text Variables:"
    if [ "$USE_JQ" = true ]; then
        jq -r '.text_variables | to_entries[] | "  \(.key) = \(.value)"' "$KICAD_PRO_FILE" 2>/dev/null || print_warning "Could not read text variables"
    else
        sed -n '/\"text_variables\"/,/}/p' "$KICAD_PRO_FILE" | grep -E '^\s*"[^"]+"\s*:\s*"[^"]*"' | sed 's/^[[:space:]]*/  /' || print_warning "Could not read text variables"
    fi
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    print_info "Dry run completed. No changes were made."
else
    print_success "Text variables and title blocks updated successfully!"
    print_info "Remember to:"
    print_info "1. Check the updated title blocks in KiCad"
    print_info "2. The revision field uses text variable reference: \${REVISION}"
    print_info "3. Save the project if everything looks correct"
fi
