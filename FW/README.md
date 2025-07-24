# Firmware Development Setup

This directory contains all firmware-related files and scripts for the KM271-WiFi project.

## Quick Start

1. **Run setup script:**
   ```bash
   cd FW
   ./setup-dev.sh
   ```

2. **Download firmware:**
   ```bash
   uv run scripts/update_firmwares.py --sources=sources.yaml
   ```

## Structure

```
FW/
├── setup-dev.sh              # Local development setup script
├── pyproject.toml             # Python project configuration
├── uv.lock                    # Dependency lock file
├── scripts/                   # Python scripts
│   └── update_firmwares.py    # Firmware download script
├── sources.yaml               # Firmware sources configuration
├── ESPhome/                   # ESPHome projects
├── KM271-WIFI-Test/           # PlatformIO project
└── KM271-dewenni/             # Additional firmware projects
```

## Development

### Python Environment

The project uses `uv` for fast dependency management:

```bash
# Install/update dependencies
uv sync

# Add new dependency
uv add <package-name>

# Run Python scripts
uv run <script-name>
```

### PlatformIO

For ESP32 hardware development:

```bash
# Build project
cd KM271-WIFI-Test
pio run

# Upload firmware (hardware must be connected)
pio run --target upload

# Serial monitor
pio device monitor
```

### Firmware Download

Download current firmware releases:

```bash
# Download all configured firmwares
uv run scripts/update_firmwares.py --sources=sources.yaml

# Show only error messages
uv run scripts/update_firmwares.py --sources=sources.yaml --quiet

# Show help
uv run scripts/update_firmwares.py --help
```

## Hardware Access

Unlike container-based solutions, you have direct access to:

- USB ports for ESP32 programming
- Serial interfaces
- Hardware debuggers
- OTA updates over network

## Tools

The following tools are automatically installed:

- **uv**: Fast Python package manager
- **PyGithub**: GitHub API client
- **PlatformIO**: Hardware development platform
- **Development Tools**: black, ruff, pylint, pytest

## Scripts

### `scripts/update_firmwares.py`
Downloads and builds all firmware images defined in sources.yaml.

```bash
# Download all firmware
uv run scripts/update_firmwares.py

# Quiet mode (no progress bars)
uv run scripts/update_firmwares.py --quiet

# Generate version info for releases
uv run scripts/update_firmwares.py --save-versions

# Custom sources file
uv run scripts/update_firmwares.py --sources=custom.yaml
```

### `scripts/generate_release_description.py`
Generates GitHub release descriptions from version information.

```bash
# Generate release description from versions.json
uv run scripts/generate_release_description.py

# Custom input/output files
uv run scripts/generate_release_description.py --versions=custom_versions.json --output=release.md
```

### `scripts/flash_firmware.py`
Flash firmware to ESP32 devices with support for batch production.

```bash
# List available firmware
uv run scripts/flash_firmware.py

# Flash single device
uv run scripts/flash_firmware.py blinkenlights
uv run scripts/flash_firmware.py dewenni-km271 -p /dev/ttyUSB0

# Batch production mode (for multiple devices)
uv run scripts/flash_firmware.py blinkenlights --loop

# Short options
uv run scripts/flash_firmware.py km271-esphome -l -p /dev/ttyUSB1 -b 115200
```

**Batch Production:**
- Flash device → Success message
- Press any key to continue with next device
- Press 'n' or ESC to stop and show statistics

## Troubleshooting

**uv not found:**
```bash
# Install uv if not available
curl -LsSf https://astral.sh/uv/install.sh | sh
# Or via pip
pip install uv
```

**PlatformIO USB access:**
```bash
# Add user to dialout group (Linux)
sudo usermod -a -G dialout $USER
# Then log out and back in
```

**Virtual environment issues:**
```bash
# Recreate venv
rm -rf .venv
uv sync
```
