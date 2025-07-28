# GitHub Actions Workflow Scripts

These scripts contain the logic for GitHub Actions workflows and provide clean separation between workflow definition and script implementation.

## 📁 Hardware Build Scripts

### `check-kicad-files.sh`
**Purpose**: Verifies the presence of required KiCad project files
**Parameters**: 
- `$1`: Project name (e.g. "KM217-WiFi")
- `$2`: Project path (e.g. "KM217-WiFi")
- `$3`: Project description (e.g. "Main KM217-WiFi Board")

### `clean-export-dirs.sh`
**Purpose**: Creates and cleans export directories for output files
**Parameters**: Same as `check-kicad-files.sh`

### `check-kicad-files-with-revision.sh`
**Purpose**: Checks KiCad project files and validates revision compatibility
**Parameters**: Same as `check-kicad-files.sh`
**Special**: Supports JSON (`"rev": "..."`), S-expression (`(rev "...")`) and XML (`<rev>...</rev>`) formats. Ensures all files have matching revisions.

### `check-kicad-changes-since-release.sh`
**Purpose**: Checks if KiCad files have changed since the last release
**Parameters**: Same as `check-kicad-files.sh`
**Output**: Sets `CHANGED=true/false` in GitHub Actions output and creates status files

### `update-kicad-revision.sh`
**Purpose**: Updates revision fields in KiCad schematic, PCB, and XML files
**Parameters**: 
- `$1-$3`: Same as other hardware scripts
- `$4`: New version (from semantic versioning)
- `$5`: PR number
**Special**: Supports JSON, S-expression, and XML formats. Creates revision like "1.2.3-pr42" in all files.

### `export-schematics.sh`
**Purpose**: Exports schematics to PDF files
**Parameters**: Same as `check-kicad-files.sh`

### `export-gerber.sh`
**Purpose**: Exports Gerber files and drill files for PCB manufacturing
**Parameters**: Same as `check-kicad-files.sh`

### `export-pcb-pdf.sh`
**Purpose**: Exports PCB layout to PDF files (top/bottom layers)
**Parameters**: Same as `check-kicad-files.sh`

### `export-pcb-images.sh`
**Purpose**: Exports PCB images (SVG/PNG) for documentation
**Parameters**: Same as `check-kicad-files.sh`

### `export-3d-models.sh`
**Purpose**: Exports 3D models in STEP format
**Parameters**: Same as `check-kicad-files.sh`

### `generate-production-summary.sh`
**Purpose**: Creates a summary of all production files
**Parameters**: 
- `$1-$3`: Same as other hardware scripts
- `$4`: GitHub SHA (commit hash)
- `$5`: GitHub Ref Name (branch/tag)

### `validate-export-files.sh`
**Purpose**: Validates exported files for completeness and size
**Parameters**: Same as `check-kicad-files.sh`

### `create-release-package.sh`
**Purpose**: Creates the final release package with all files
**Parameters**: Same as `generate-production-summary.sh`

## 📚 Documentation Build Scripts

### `check-documentation.sh`
**Purpose**: Verifies the presence of documentation files
**Parameters**: None

### `build-asciidoc.sh`
**Purpose**: Builds HTML/PDF from AsciiDoc files
**Parameters**: None

### `build-latex.sh`
**Purpose**: Builds PDF from LaTeX files
**Parameters**: None

### `package-documentation.sh`
**Purpose**: Packages all documentation for release
**Parameters**:
- `$1`: GitHub SHA (commit hash)
- `$2`: GitHub Ref Name (branch/tag)

### `check-documentation-links.sh`
**Purpose**: Checks for broken links in Markdown documentation
**Parameters**: None

### `generate-documentation-statistics.sh`
**Purpose**: Generates statistics about documentation files
**Parameters**: None

## 🔄 PR-Specific Scripts

### `check-kicad-files-with-revision.sh`
**Purpose**: Enhanced KiCad file check with revision validation for PRs
**Parameters**: Same as `check-kicad-files.sh`

### `generate-production-summary-pr.sh`
**Purpose**: Generates production summary for PR validation
**Parameters**: 
- `$1-$3`: Same as other hardware scripts
- `$4`: GitHub SHA (commit hash)

### `generate-pr-summary.sh`
**Purpose**: Creates a comprehensive PR summary with build results
**Parameters**: None (reads from artifacts directory)

### `local-pr-test-summary.sh`
**Purpose**: Shows local test summary for PR workflows using act
**Parameters**: None

## 🚀 Release Creation Scripts

### `prepare-release-assets.sh`
**Purpose**: Prepares all release assets and creates ZIP archives
**Parameters**:
- `$1`: Version (e.g. "1.2.3")

### `generate-release-notes.sh`
**Purpose**: Creates automatic release notes with changelog
**Parameters**:
- `$1`: Version (e.g. "1.2.3")
- `$2`: Version Tag (e.g. "v1.2.3")
- `$3`: GitHub SHA (commit hash)
- `$4`: GitHub Ref Name (branch/tag)
- `$5`: GitHub Repository (e.g. "the78mole/km271-wifi")

### `local-test-summary.sh`
**Purpose**: Shows a summary for local tests with act
**Parameters**:
- `$1`: Version (e.g. "1.2.3")
- `$2`: GitHub Repository (e.g. "the78mole/km271-wifi")

## 🔧 Usage

All scripts are executable (`chmod +x`) and are called from the main workflow with appropriate parameters:

```yaml
- name: 🔍 Check KiCad Project Files
  run: |
    ./.github/workflows/scripts/check-kicad-files.sh \
      "${{ matrix.project.name }}" \
      "${{ matrix.project.path }}" \
      "${{ matrix.project.description }}"
```

## 📋 Benefits of Script Externalization

1. **Cleanliness**: The workflow file is much more readable
2. **Reusability**: Scripts can be used in other workflows
3. **Testability**: Scripts can be tested locally
4. **Maintainability**: Changes are easier to implement
5. **Version Control**: Scripts are versioned with Git
6. **Debugging**: Easier debugging through separate script files

## 🧪 Local Testing

Scripts can be tested locally:

```bash
# Test hardware script
cd /path/to/project
./.github/workflows/scripts/check-kicad-files.sh "KM217-WiFi" "KM217-WiFi" "Main Board"

# Test documentation script
./.github/workflows/scripts/check-documentation.sh
```

## ⚠️ Important Notes

- All scripts use `set -e` for immediate exit on errors
- Scripts are optimized for Ubuntu/Linux (GitHub Actions Runner)
- Paths are relative to workspace root
- Environment variables are provided by GitHub Actions
