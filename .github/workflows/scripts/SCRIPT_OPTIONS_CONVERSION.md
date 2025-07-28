# Script Options Conversion Progress

This document tracks the conversion of workflow scripts from positional arguments to option-based arguments for improved readability and maintainability.

## ✅ Converted Scripts (8/25)

### Core KiCad Processing Scripts
- [x] `check-kicad-files.sh` - Verify presence of required KiCad project files
  - Options: `--name`, `--path`, `--description`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

- [x] `update-kicad-revision.sh` - Update revision fields in KiCad files
  - Options: `--name`, `--path`, `--description`, `--version`, `--pr`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

- [x] `check-kicad-files-with-revision.sh` - Check KiCad files and verify revision consistency
  - Options: `--name`, `--path`, `--description`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

### Export Scripts
- [x] `export-gerber.sh` - Export Gerber and drill files for manufacturing
  - Options: `--name`, `--path`, `--description`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

- [x] `export-schematics.sh` - Export KiCad schematic files to PDF
  - Options: `--name`, `--path`, `--description`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

- [x] `export-3d-models.sh` - Export 3D models from KiCad PCB files to STEP
  - Options: `--name`, `--path`, `--description`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

### Validation Scripts
- [x] `validate-export-files.sh` - Validate exported files for completeness
  - Options: `--name`, `--path`, `--description`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

### Utility Scripts
- [x] `clean-export-dirs.sh` - Clean and prepare export directories
  - Options: `--name`, `--path`, `--description`
  - Help: `-h, --help`
  - Backward compatible with positional arguments

## ⏳ Scripts Pending Conversion (17/25)

### Export Scripts
- [ ] `export-pcb-images.sh` - Generate PCB visualization images
- [ ] `export-pcb-pdf.sh` - Export PCB layouts to PDF

### Documentation Scripts  
- [ ] `build-asciidoc.sh` - Build AsciiDoc documentation
- [ ] `build-latex.sh` - Build LaTeX documentation
- [ ] `check-documentation.sh` - Validate documentation files
- [ ] `check-documentation-links.sh` - Check documentation links
- [ ] `package-documentation.sh` - Package documentation files

### Analysis Scripts
- [ ] `check-kicad-changes-since-release.sh` - Check KiCad changes since last release
- [ ] `generate-documentation-statistics.sh` - Generate documentation statistics

### Release Scripts
- [ ] `create-release-package.sh` - Create release packages
- [ ] `prepare-release-assets.sh` - Prepare assets for release
- [ ] `generate-release-notes.sh` - Generate release notes

### Summary Scripts
- [ ] `generate-production-summary.sh` - Generate production summary
- [ ] `generate-production-summary-pr.sh` - Generate PR production summary
- [ ] `local-test-summary.sh` - Generate local test summary
- [ ] `local-pr-test-summary.sh` - Generate local PR test summary

### Scripts Without Parameters (No conversion needed)
- [ ] `generate-pr-summary.sh` - Generate PR summary (no parameters)

## 🎯 Conversion Standards

All converted scripts follow these standards:

### Option Format
```bash
-n, --name PROJ_NAME        Project name (e.g. "KM217-WiFi")
-p, --path PROJ_PATH        Project path (e.g. "KM217-WiFi")  
-d, --description DESC      Project description (e.g. "Main Board")
-h, --help                  Show this help message
```

### Additional Options (where applicable)
```bash
-v, --version VERSION       Version from semantic versioning
--pr PR_NUMBER              Pull Request number
```

### Help System
- Comprehensive usage information
- Examples for common use cases
- Clear parameter descriptions
- Output format explanation

### Backward Compatibility
- All scripts maintain support for positional arguments
- Existing workflow YAML files continue to work unchanged
- Gradual migration path for future updates

## 🚀 Workflow Updates

### ✅ Updated Workflows (2/2)
- [x] `pr-check.yml` - Updated to use option flags for converted scripts
- [x] `release.yml` - Updated to use option flags for converted scripts

### Conversion Examples

**Before (Positional Arguments):**
```yaml
- name: 🔧 Export Gerber Files
  run: |
    ./.github/workflows/scripts/export-gerber.sh \
      "${{ matrix.project.name }}" \
      "${{ matrix.project.path }}" \
      "${{ matrix.project.description }}"
```

**After (Option Flags):**
```yaml
- name: 🔧 Export Gerber Files
  run: |
    ./.github/workflows/scripts/export-gerber.sh \
      --name "${{ matrix.project.name }}" \
      --path "${{ matrix.project.path }}" \
      --description "${{ matrix.project.description }}"
```

## 🚀 Benefits Achieved

1. **Improved Readability**: Self-documenting command lines with named parameters
2. **Better Maintainability**: Clear parameter purpose and validation
3. **Enhanced Debugging**: Built-in help system for troubleshooting
4. **Future-Proof**: Easy to add new options without breaking changes
5. **User Experience**: Consistent interface across all scripts
6. **Workflow Clarity**: YAML workflows are now self-documenting with option names

## 📝 Next Steps

1. Continue converting remaining 19 scripts
2. Consider updating workflow YAML files to use option syntax (optional)
3. Add parameter validation improvements where needed
4. Document best practices for future script development

---
*Last Updated: Scripts 1-8 converted with option parsing and help systems. All workflows updated to use option flags.*
