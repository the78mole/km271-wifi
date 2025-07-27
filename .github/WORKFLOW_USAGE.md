# GitHub Actions Workflow Usage

## 📋 Overview

This repository contains a GitHub Actions workflow for automated KiCad hardware builds and documentation generation.

## 🔧 Workflow: `pr-check.yml`

### What it does:
- **Hardware Build & Export**: Exports KiCad files to production-ready formats
- **Documentation Build**: Validates and processes documentation files
- **PR Summary**: Generates automated PR comments with build results

### Jobs:

#### 1. 🔧 Hardware Build & Export
- Validates KiCad project files
- Exports Gerber files for PCB manufacturing
- Generates drill files
- Creates PDF documentation (schematics and PCB layouts)
- Exports SVG assembly diagrams
- Generates 3D STEP models
- Creates production summary
- Uploads all artifacts

#### 2. 📚 Documentation Build
- Validates Markdown documentation
- Builds AsciiDoc files (if present)
- Generates LaTeX PDFs (if present)
- Checks for broken links
- Creates documentation statistics
- Uploads documentation artifacts

#### 3. 📋 PR Summary (PR only)
- Downloads artifacts from previous jobs
- Generates comprehensive PR summary
- Comments results on Pull Request

## 🚀 Usage

### GitHub Actions (Automatic)
The workflow runs automatically on:
- Pull Requests to `main` or `develop` branches
- Pushes to `main` branch
- Changes to:
  - `KM217-WiFi/**` (hardware files)
  - `DOC/**` (documentation)
  - `.github/workflows/pr-check.yml` (workflow itself)

### Local Testing with `act`

#### Prerequisites
```bash
# Install act (GitHub Actions runner)
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Or download from: https://github.com/nektos/act/releases
```

#### Run Local Tests
```bash
# Test hardware build only
act -j hardware-build --artifact-server-path /tmp/artifacts

# Test documentation build only
act -j documentation-build --artifact-server-path /tmp/artifacts

# Test complete workflow (excluding PR comments)
act --artifact-server-path /tmp/artifacts

# Use specific Docker platform (if needed)
act -j hardware-build --artifact-server-path /tmp/artifacts --container-architecture linux/amd64
```

#### Local Artifacts
When using `act`, artifacts are stored locally:
- **Location**: `/tmp/artifacts/[run-id]/[artifact-name]/`
- **Hardware exports**: `/tmp/artifacts/*/km217-wifi-hardware-exports/`
- **Documentation**: `/tmp/artifacts/*/km217-wifi-documentation/`

#### Extract Artifacts from Container
```bash
# Copy artifacts from act container to host
docker cp $(docker ps -lq):/tmp/artifacts/ ./local-artifacts/
```

## 📦 Generated Artifacts

### Hardware Exports (`km217-wifi-hardware-exports`)
- **Gerber Files**: `Export/Gerbers/` - PCB manufacturing files
- **Drill Files**: `Export/Drill/` - Drill hole information
- **PDFs**: `Export/PDF/` - Schematics and PCB layout documentation
- **Images**: `Export/Images/` - SVG assembly diagrams
- **3D Models**: `Export/3D/` - STEP files for 3D visualization
- **Summary**: `Export/PRODUCTION_SUMMARY.md` - Complete file overview

### Documentation (`km217-wifi-documentation`)
- All files from `DOC/` directory
- Generated HTML/PDF files (if applicable)
- Documentation statistics

## 🔧 Customization

### Modify KiCad Export Settings
Edit the workflow file `.github/workflows/pr-check.yml`:

```yaml
# Example: Add more PCB layers
--layers "F.Cu,B.Cu,In1.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts"

# Example: Change precision
--precision 5  # or 6
```

### Add Custom Validation
Add custom steps in the workflow:

```yaml
- name: 🔍 Custom Validation
  run: |
    echo "Running custom validation..."
    # Your custom validation logic here
```

## 🐛 Troubleshooting

### Common Issues

1. **Missing 3D Models**: The STEP export shows warnings about missing 3D models. This is normal and doesn't affect the PCB manufacturing files.

2. **ImageMagick not available**: PNG conversion is skipped. SVG files are still generated.

3. **act fails with permissions**: Make sure Docker is running and you have permissions:
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

4. **Workflow fails on syntax**: Check bash syntax in workflow scripts, especially:
   - Array definitions
   - String substitutions
   - EOF delimiters

### Debug Tips

1. **Enable act debug mode**:
   ```bash
   act -j hardware-build --artifact-server-path /tmp/artifacts --verbose
   ```

2. **Check generated files locally**:
   ```bash
   ls -la /tmp/artifacts/*/km217-wifi-hardware-exports/
   unzip -l /tmp/artifacts/*/km217-wifi-hardware-exports/*.zip
   ```

3. **Validate KiCad CLI commands manually**:
   ```bash
   # In KiCad project directory
   kicad-cli sch export pdf --help
   kicad-cli pcb export gerbers --help
   ```

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [act - Local GitHub Actions](https://github.com/nektos/act)
- [KiCad CLI Documentation](https://docs.kicad.org/master/en/cli/cli.html)
- [KiCad Docker Image](https://github.com/the78mole/kicaddev-docker)
