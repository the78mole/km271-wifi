#!/bin/bash
set -e

# Script: check-project-revisions.sh
# Purpose: Check if all KiCad projects contain a specific revision number
# Usage: check-project-revisions.sh <revision>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.github/kicad-projects.yml"

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
print_header() { echo -e "${BLUE}🔍 $1${NC}"; }

# Help function
show_help() {
    echo "Usage: $0 <revision> [options]"
    echo ""
    echo "Check if all KiCad projects contain a specific revision number"
    echo ""
    echo "Arguments:"
    echo "  <revision>        The revision number to check for (e.g., 1.5.2, v2.0.0)"
    echo ""
    echo "Options:"
    echo "  --type TYPE       Filter projects by type (main|extension|all, default: all)"
    echo "  --verbose, -v     Show detailed information about each file checked"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 1.5.2                    # Check all projects for revision 1.5.2"
    echo "  $0 v2.0.0 --type main       # Check only main projects for revision v2.0.0"
    echo "  $0 1.0.1 --verbose          # Check with detailed output"
    echo ""
}

# Parse command line arguments
REVISION=""
TYPE_FILTER="all"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE_FILTER="$2"
            shift 2
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
            if [ -z "$REVISION" ]; then
                REVISION="$1"
            else
                print_error "Multiple revision arguments provided. Only one is allowed."
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if revision was provided
if [ -z "$REVISION" ]; then
    print_error "Revision argument is required!"
    echo ""
    show_help
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

print_header "Checking KiCad Project Revisions for: $REVISION"
echo ""

# Load projects using the existing script
PROJECTS_JSON=$("$SCRIPT_DIR/.github/workflows/scripts/load-kicad-projects.sh" --type "$TYPE_FILTER" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$PROJECTS_JSON" ]; then
    print_error "Failed to load project configuration"
    exit 1
fi

# Extract project information
PROJECTS=$(echo "$PROJECTS_JSON" | jq -r '.project[] | @base64')

if [ -z "$PROJECTS" ]; then
    print_warning "No projects found matching the criteria"
    exit 0
fi

# Statistics
TOTAL_PROJECTS=0
PROJECTS_WITH_REVISION=0
PROJECTS_WITHOUT_REVISION=0
PROJECTS_WITH_ISSUES=0

# Check each project
for project_b64 in $PROJECTS; do
    project=$(echo "$project_b64" | base64 --decode)
    PROJECT_NAME=$(echo "$project" | jq -r '.name')
    PROJECT_PATH=$(echo "$project" | jq -r '.path')
    PROJECT_DESCRIPTION=$(echo "$project" | jq -r '.description')
    PROJECT_TYPE=$(echo "$project" | jq -r '.type')
    
    TOTAL_PROJECTS=$((TOTAL_PROJECTS + 1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📋 Project: ${PROJECT_NAME}${NC}"
    echo -e "   ${BLUE}Type:${NC} ${PROJECT_TYPE}"
    echo -e "   ${BLUE}Path:${NC} ${PROJECT_PATH}"
    echo -e "   ${BLUE}Description:${NC} ${PROJECT_DESCRIPTION}"
    echo ""
    
    PROJECT_HAS_REVISION=false
    PROJECT_HAS_ISSUES=false
    
    # Check if project directory exists
    if [ ! -d "$PROJECT_PATH" ]; then
        print_error "Project directory does not exist: $PROJECT_PATH"
        PROJECT_HAS_ISSUES=true
    else
        # Find KiCad files (revision can be in .kicad_pro as text variable, or directly in .kicad_sch, .kicad_pcb, and .xml files)
        KICAD_PRO_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.kicad_pro" | head -1)
        KICAD_SCH_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.kicad_sch" | head -1)
        KICAD_PCB_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.kicad_pcb" | head -1)
        KICAD_XML_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.xml" | head -1)
        
        # Initialize revision check
        FILES_CHECKED=0
        FILES_WITH_REVISION=0
        PROJECT_HAS_TEXT_VARIABLE=false
        
        # Check for text variable in .kicad_pro file first
        if [ -n "$KICAD_PRO_FILE" ]; then
            if [ "$VERBOSE" = true ]; then
                print_info "Checking text variables in: $(basename "$KICAD_PRO_FILE")"
            fi
            
            # Check for text variable with revision (common variable names: rev, revision, REV, REVISION)
            if grep -q "\"text_variables\"" "$KICAD_PRO_FILE"; then
                # Look for revision in text variables section - extract the text_variables section and check
                TEXT_VARS_SECTION=$(sed -n '/\"text_variables\": {/,/}/p' "$KICAD_PRO_FILE")
                if echo "$TEXT_VARS_SECTION" | grep -E "\"(rev|revision|REV|REVISION)\".*\"$REVISION\"" >/dev/null; then
                    print_success "Found revision $REVISION in text variables of $(basename "$KICAD_PRO_FILE")"
                    PROJECT_HAS_TEXT_VARIABLE=true
                elif echo "$TEXT_VARS_SECTION" | grep -E "\"(rev|revision|REV|REVISION)\"" >/dev/null; then
                    # Show current revision from text variables
                    CURRENT_REV=$(echo "$TEXT_VARS_SECTION" | grep -E "\"(rev|revision|REV|REVISION)\"" | sed 's/.*: *"\([^"]*\)".*/\1/' | head -1)
                    if [ "$CURRENT_REV" = "$REVISION" ]; then
                        print_success "Found revision $REVISION in text variables of $(basename "$KICAD_PRO_FILE")"
                        PROJECT_HAS_TEXT_VARIABLE=true
                    else
                        print_warning "Text variable found in $(basename "$KICAD_PRO_FILE") but revision is: $CURRENT_REV (expected: $REVISION)"
                    fi
                else
                    print_warning "Text variables found in $(basename "$KICAD_PRO_FILE") but no revision variable found"
                fi
            else
                print_warning "No text variables section found in $(basename "$KICAD_PRO_FILE")"
            fi
        else
            print_warning "No .kicad_pro file found in $PROJECT_PATH"
            PROJECT_HAS_ISSUES=true
        fi
        
        # Check .kicad_sch file
        if [ -n "$KICAD_SCH_FILE" ]; then
            FILES_CHECKED=$((FILES_CHECKED + 1))
            if [ "$VERBOSE" = true ]; then
                print_info "Checking: $(basename "$KICAD_SCH_FILE")"
            fi
            
            # Check for direct revision or text variable reference
            if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_SCH_FILE" || grep -q "\${rev}\|\${revision}\|\${REV}\|\${REVISION}" "$KICAD_SCH_FILE"; then
                if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_SCH_FILE"; then
                    print_success "Found direct revision $REVISION in $(basename "$KICAD_SCH_FILE")"
                else
                    print_success "Found text variable reference in $(basename "$KICAD_SCH_FILE")"
                fi
                FILES_WITH_REVISION=$((FILES_WITH_REVISION + 1))
            else
                CURRENT_REV=$(grep -o "\"rev\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$KICAD_SCH_FILE" | sed 's/.*"\([^"]*\)".*/\1/' || echo "none/variable")
                print_error "Revision $REVISION not found in $(basename "$KICAD_SCH_FILE") (current: $CURRENT_REV)"
            fi
        else
            print_warning "No .kicad_sch file found in $PROJECT_PATH"
            PROJECT_HAS_ISSUES=true
        fi
        
        # Check .kicad_pcb file
        if [ -n "$KICAD_PCB_FILE" ]; then
            FILES_CHECKED=$((FILES_CHECKED + 1))
            if [ "$VERBOSE" = true ]; then
                print_info "Checking: $(basename "$KICAD_PCB_FILE")"
            fi
            
            # Check for direct revision or text variable reference
            if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_PCB_FILE" || grep -q "\${rev}\|\${revision}\|\${REV}\|\${REVISION}" "$KICAD_PCB_FILE"; then
                if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_PCB_FILE"; then
                    print_success "Found direct revision $REVISION in $(basename "$KICAD_PCB_FILE")"
                else
                    print_success "Found text variable reference in $(basename "$KICAD_PCB_FILE")"
                fi
                FILES_WITH_REVISION=$((FILES_WITH_REVISION + 1))
            else
                CURRENT_REV=$(grep -o "\"rev\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$KICAD_PCB_FILE" | sed 's/.*"\([^"]*\)".*/\1/' || echo "none/variable")
                print_error "Revision $REVISION not found in $(basename "$KICAD_PCB_FILE") (current: $CURRENT_REV)"
            fi
        else
            print_warning "No .kicad_pcb file found in $PROJECT_PATH"
            PROJECT_HAS_ISSUES=true
        fi
        
        # Check .xml file (if exists)
        if [ -n "$KICAD_XML_FILE" ]; then
            FILES_CHECKED=$((FILES_CHECKED + 1))
            if [ "$VERBOSE" = true ]; then
                print_info "Checking: $(basename "$KICAD_XML_FILE")"
            fi
            
            # Check for direct revision or text variable reference
            if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_XML_FILE" || grep -q "\${rev}\|\${revision}\|\${REV}\|\${REVISION}" "$KICAD_XML_FILE"; then
                if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_XML_FILE"; then
                    print_success "Found direct revision $REVISION in $(basename "$KICAD_XML_FILE")"
                else
                    print_success "Found text variable reference in $(basename "$KICAD_XML_FILE")"
                fi
                FILES_WITH_REVISION=$((FILES_WITH_REVISION + 1))
            else
                CURRENT_REV=$(grep -o "\"rev\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$KICAD_XML_FILE" | sed 's/.*"\([^"]*\)".*/\1/' || echo "none/variable")
                print_error "Revision $REVISION not found in $(basename "$KICAD_XML_FILE") (current: $CURRENT_REV)"
            fi
        fi
        
        # Project has revision if:
        # 1. Text variable is defined in .kicad_pro with correct revision AND all mandatory files use variables or have direct revision
        # 2. OR all relevant files contain the direct revision
        # Note: When using text variables, XML file is optional as it might not be updated
        MANDATORY_FILES_OK=false
        if [ "$PROJECT_HAS_TEXT_VARIABLE" = true ]; then
            # For text variable projects, only check .kicad_sch and .kicad_pcb files
            SCH_OK=false
            PCB_OK=false
            
            # Check if schematic has variable reference or direct revision
            if [ -n "$KICAD_SCH_FILE" ]; then
                if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_SCH_FILE" || grep -q "\${rev}\|\${revision}\|\${REV}\|\${REVISION}" "$KICAD_SCH_FILE"; then
                    SCH_OK=true
                fi
            fi
            
            # Check if PCB has variable reference or direct revision
            if [ -n "$KICAD_PCB_FILE" ]; then
                if grep -q "\"rev\".*\"$REVISION\"" "$KICAD_PCB_FILE" || grep -q "\${rev}\|\${revision}\|\${REV}\|\${REVISION}" "$KICAD_PCB_FILE"; then
                    PCB_OK=true
                fi
            fi
            
            if [ "$SCH_OK" = true ] && [ "$PCB_OK" = true ]; then
                MANDATORY_FILES_OK=true
            fi
        else
            # For direct revision projects, all files must have the revision
            if [ "$FILES_CHECKED" -gt 0 ] && [ "$FILES_WITH_REVISION" -eq "$FILES_CHECKED" ]; then
                MANDATORY_FILES_OK=true
            fi
        fi
        
        if [ "$MANDATORY_FILES_OK" = true ]; then
            PROJECT_HAS_REVISION=true
        fi
    fi
    
    # Update statistics
    if [ "$PROJECT_HAS_REVISION" = true ]; then
        PROJECTS_WITH_REVISION=$((PROJECTS_WITH_REVISION + 1))
        echo -e "${GREEN}✅ Project ${PROJECT_NAME}: Revision $REVISION found${NC}"
    else
        PROJECTS_WITHOUT_REVISION=$((PROJECTS_WITHOUT_REVISION + 1))
        echo -e "${RED}❌ Project ${PROJECT_NAME}: Revision $REVISION NOT found${NC}"
    fi
    
    if [ "$PROJECT_HAS_ISSUES" = true ]; then
        PROJECTS_WITH_ISSUES=$((PROJECTS_WITH_ISSUES + 1))
    fi
    
    echo ""
done

# Print summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_header "SUMMARY"
echo ""
echo -e "${BLUE}Total Projects Checked:${NC} $TOTAL_PROJECTS"
echo -e "${GREEN}Projects with Revision $REVISION:${NC} $PROJECTS_WITH_REVISION"
echo -e "${RED}Projects without Revision $REVISION:${NC} $PROJECTS_WITHOUT_REVISION"

if [ "$PROJECTS_WITH_ISSUES" -gt 0 ]; then
    echo -e "${YELLOW}Projects with Issues:${NC} $PROJECTS_WITH_ISSUES"
fi

echo ""

# Exit with appropriate code
if [ "$PROJECTS_WITHOUT_REVISION" -eq 0 ] && [ "$PROJECTS_WITH_ISSUES" -eq 0 ]; then
    print_success "All projects contain revision $REVISION!"
    exit 0
elif [ "$PROJECTS_WITHOUT_REVISION" -gt 0 ]; then
    print_error "Some projects are missing revision $REVISION"
    exit 1
else
    print_warning "All projects have the revision, but some had issues"
    exit 2
fi
