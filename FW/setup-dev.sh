#!/bin/bash
set -e

echo "🚀 Setting up local development environment..."

# Check if we're in the right directory
if [ ! -f "pyproject.toml" ]; then
    echo "❌ Error: pyproject.toml not found. Please run this script from the FW directory."
    exit 1
fi

# Install uv if not already installed
if ! command -v uv &> /dev/null; then
    echo "📥 Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
    echo "✅ uv installed: $(uv --version)"
else
    echo "✅ uv already installed: $(uv --version)"
fi

# Install Python dependencies with uv
echo "📦 Installing Python dependencies..."
uv sync

# Verify the virtual environment was created
if [ -f ".venv/bin/python" ]; then
    echo "✅ Virtual environment created at $(pwd)/.venv"
    echo "🐍 Python version: $(.venv/bin/python --version)"
else
    echo "❌ Virtual environment creation failed"
    exit 1
fi

# Check if PlatformIO is already installed system-wide
if command -v pio &> /dev/null; then
    echo "✅ PlatformIO already installed system-wide: $(pio --version)"
else
    echo "🔌 Installing PlatformIO in virtual environment..."
    .venv/bin/pip install platformio
    echo "✅ PlatformIO installed in venv"
fi

# Show PlatformIO system info
echo "ℹ️ PlatformIO system information:"
if command -v pio &> /dev/null; then
    pio system info
else
    .venv/bin/pio system info
fi

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "Virtual Environment Info:"
echo "  📍 Location: $(pwd)/.venv"
echo "  🐍 Python: $(.venv/bin/python --version)"
echo "  📦 Packages: $(.venv/bin/pip list | wc -l) installed"
echo ""
echo "To activate the virtual environment:"
echo "  source .venv/bin/activate"
echo ""
echo "Available commands:"
echo "  • uv run scripts/update_firmwares.py --sources=sources.yaml    # Download firmware"
echo "  • cd KM271-WIFI-Test && pio run                               # Build PlatformIO project" 
echo "  • cd KM271-WIFI-Test && pio run --target upload               # Upload firmware"
echo "  • cd KM271-WIFI-Test && pio device monitor                    # Monitor serial output"
echo ""
