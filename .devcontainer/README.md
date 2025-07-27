# KM217 Hardware Development Environment

This DevContainer provides a complete hardware development environment for the KM217 project using a pre-built Docker image for optimal performance and fast startup.

## 🚀 Quick Start

1. Open this folder in VS Code
2. Click "Reopen in Container" when prompted
3. Container starts in ~30 seconds using `ghcr.io/the78mole/kicaddev-docker:latest`

## ✨ Features Included

- **KiCad 9.0.3**: Latest PCB design tools with full library support
- **Python 3.12.3**: Complete development environment with hardware packages
- **PCB Tools**: PCBDraw for visualization, KiKit for panelization
- **Development**: Git, VS Code extensions, debugging tools
- **GUI Support**: X11 forwarding for native KiCad GUI experience

## 🏗️ DevContainer Structure

```
.devcontainer/
├── devcontainer.json        # Main configuration
├── README.md               # This documentation
├── STATUS.md               # Current status and notes
└── test-devcontainer.sh    # Validation script
```

## � Available Tools

### KiCad 9.0.3 Suite
- **Schematic Editor**: Complete circuit design
- **PCB Editor**: Layout with advanced routing
- **3D Viewer**: Realistic board visualization
- **Symbol/Footprint Libraries**: Comprehensive component database

### Python Development
- **Python 3.12.3**: Latest stable Python
- **PCBDraw**: PCB visualization and documentation
- **KiKit**: PCB panelization and production automation
- **Hardware Libraries**: GPIO, I2C, SPI development tools

### Development Environment
- **Git**: Version control with full history
- **VS Code Extensions**: Python, Markdown, Linting pre-configured
- **X11 GUI**: Native Linux GUI application support

## 🚀 Usage Examples

### KiCad Development
```bash
# Open KiCad schematic editor
kicad myproject.kicad_pro

# Generate production files
kicad-cli pcb export gerbers --output production/ myproject.kicad_pcb

# Export schematic PDF
kicad-cli sch export pdf --output schematic.pdf myproject.kicad_sch
```

### PCB Visualization
```bash
# Create assembly diagram
pcbdraw myproject.kicad_pcb assembly.svg --side front

# Generate production visualization
pcbdraw myproject.kicad_pcb production.png --style builtin:set-blue-hasl
```

### PCB Panelization
```bash
# Create 2x2 panel with 2mm spacing
kikit panelize grid --space 2mm --gridsize 2x2 single.kicad_pcb panel.kicad_pcb
```
- **ImageMagick**: Image processing

## 📁 Directory Structure

The container sets up the following directories:
- `~/Documents/Hardware/` - Hardware projects
- `~/Documents/PCB/` - PCB designs  
- `~/Documents/Datasheets/` - Component datasheets
- `~/Documents/3D-Models/` - 3D model files
- `~/Templates/` - Document templates

## 🔧 VS Code Extensions

Pre-installed extensions for optimal workflow:
- Python development tools
- Markdown editing and preview
- Markdown PDF export
- YAML/JSON editing
- Jupyter notebook support

## 🚀 Getting Started

### Option 1: VS Code DevContainer (Recommended)
1. Open this project in VS Code
2. Install the "Dev Containers" extension
3. When prompted, click "Reopen in Container"
4. Wait for the container to build (first time only)
5. Start developing!

### Option 2: Local Docker Build
```bash
# Build the container locally
.devcontainer/build.sh

# Run manually
docker run -it --rm -v $(pwd):/workspaces hw-dev-container
```

### Quick Test
```bash
# Test Markdown to PDF conversion
cd ~/Templates
~/markdown2pdf.sh sample_hardware_doc.md

## 📋 Requirements

- Docker installed and running
- VS Code with Dev Containers extension
- X11 forwarding for GUI applications (automatically configured)

## ⚡ Performance

- **Startup Time**: ~30 seconds
- **Image Size**: 9.12GB (optimized)
- **Base System**: Ubuntu 24.04 LTS
- **Last Updated**: Regularly maintained

## 🔍 Troubleshooting

### GUI Applications Not Starting
If KiCad GUI doesn't open:
```bash
# Verify X11 forwarding
echo $DISPLAY

# Check if display is available
xdpyinfo | head
```

### Permission Issues
```bash
# Fix workspace permissions if needed
sudo chown -R vscode:vscode /workspaces
```

### Container Issues
```bash
# Test container functionality
./.devcontainer/test-devcontainer.sh

# Rebuild if needed
Docker: Rebuild Container (Ctrl+Shift+P)
```

## 📚 Additional Resources

- [KiCad Documentation](https://docs.kicad.org/)
- [PCBDraw Documentation](https://github.com/yaqwsx/pcbdraw)
- [KiKit Documentation](https://github.com/yaqwsx/kikit)

---

*Happy hardware development! 🛠️*
