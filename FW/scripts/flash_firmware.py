#!/usr/bin/env python3
"""
Firmware Flash Tool

This script flashes firmware to ESP32 devices using esptool.
It reads firmware information from sources.yaml and automatically
flashes the corresponding .bin file.

Usage:
    flash_firmware.py [<name>] [--port=<port>] [--sources=<file>]
                      [--baudrate=<rate>] [--loop]
    flash_firmware.py --list [--sources=<file>]
    flash_firmware.py --help

Arguments:
    <name>              Name of the firmware to flash (from sources.yaml)

Options:
    -p --port=<port>       Serial port (optional, esptool will auto-detect)
    -s --sources=<file>    Path to sources.yaml file [default: sources.yaml]
    -b --baudrate=<rate>   Baud rate for flashing [default: 921600]
    -l --loop              Continue flashing after each device (for batch production)
    --list                 List available firmware names
    -h --help              Show this help message

Examples:
    uv run scripts/flash_firmware.py
    uv run scripts/flash_firmware.py dewenni-km271
    uv run scripts/flash_firmware.py km271-esphome -p /dev/ttyUSB0
    uv run scripts/flash_firmware.py blinkenlights --loop
    uv run scripts/flash_firmware.py --list
"""

import subprocess
import sys
from pathlib import Path

import yaml
from docopt import docopt


def wait_for_user_input() -> bool:
    """Wait for user input and return True to continue, False to stop."""
    print("\n" + "━" * 60)
    print("🔄 Batch Production Mode")
    print("━" * 60)
    print("📱 Connect next device and press any key to continue...")
    print("🛑 Press 'ESC' or 'n' to stop")
    print("━" * 60)

    try:
        # Try to use termios for better key detection (Unix/Linux)
        import termios
        import tty

        # Check if stdin is a real terminal (not a pipe or redirect)
        if not sys.stdin.isatty():
            raise ImportError("Not a TTY")

        old_settings = termios.tcgetattr(sys.stdin)
        try:
            # Try modern method first, then fall back to older method
            if hasattr(tty, "setcbreak"):
                tty.setcbreak(sys.stdin.fileno())
            else:
                tty.cbreak(sys.stdin.fileno())
            key = sys.stdin.read(1)

            # Check for ESC key (ASCII 27) or 'n'/'N' to stop
            if ord(key) == 27 or key.lower() == "n":
                print("🛑 Stopping batch production...")
                return False
            else:
                print(f"🚀 Continuing with next device... (pressed: {repr(key)})")
                return True

        finally:
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)

    except (ImportError, OSError, termios.error):
        # Fallback for systems without termios or when not in a TTY
        try:
            user_input = (
                input("Press ENTER to continue or 'n' to stop: ").strip().lower()
            )
            if user_input == "n":
                print("🛑 Stopping batch production...")
                return False
            else:
                print("🚀 Continuing with next device...")
                return True
        except (EOFError, KeyboardInterrupt):
            print("\n🛑 Stopping batch production...")
            return False


def load_sources_config(sources_file: str) -> dict:
    """Load and parse the sources configuration file."""
    try:
        with open(sources_file, encoding="utf-8") as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"❌ Sources file not found: {sources_file}")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"❌ Error parsing sources file: {e}")
        sys.exit(1)


def list_available_firmware(config: dict) -> None:
    """List all available firmware names from the configuration."""
    print("📋 Available firmware:")
    print("━" * 50)

    fetchdir = config.get("fetchdir", "./tmpfw")

    for source in config.get("sources", []):
        name = source.get("name", "unknown")
        source_type = source.get("type", "unknown")
        platform = source.get("platform", "unknown")

        # Check if firmware file exists
        firmware_path = Path(fetchdir) / f"{name}.bin"
        status = "✅" if firmware_path.exists() else "❌"

        print(f"{status} {name} ({source_type}, {platform})")
        if source_type == "github":
            repo = source.get("repo", "unknown")
            version = source.get("current_version", "latest")
            print(f"    📦 {repo} - {version}")
        elif source_type == "local":
            path = source.get("path", "unknown")
            print(f"    📁 {path}")

    print("\n💡 Use 'uv run scripts/update_firmwares.py' to download missing firmware")


def find_firmware_config(config: dict, name: str) -> dict | None:
    """Find firmware configuration by name."""
    for source in config.get("sources", []):
        if source.get("name") == name:
            return source
    return None


def get_firmware_path(config: dict, name: str) -> Path:
    """Get the path to the firmware binary file."""
    fetchdir = config.get("fetchdir", "./tmpfw")
    return Path(fetchdir) / f"{name}.bin"


def flash_local_project(
    name: str, port: str | None, baudrate: int, firmware_config: dict
) -> bool:
    """Flash firmware using PlatformIO - prefer downloaded factory image over rebuild."""
    project_path = firmware_config.get("path", "")
    if not project_path:
        print("❌ No project path specified in configuration")
        return False

    project_dir = Path(project_path)
    if not project_dir.exists():
        print(f"❌ Project directory not found: {project_dir}")
        return False

    print("🚀 PlatformIO Local Project")
    print("━" * 50)
    print(f"📦 Project: {name}")
    print(f"📁 Path: {project_dir}")
    if port:
        print(f"🔗 Port: {port}")
    else:
        print("🔗 Port: Auto-detect")
    print(f"⚡ Baudrate: {baudrate}")
    print()

    # First check if we have a downloaded factory image from update_firmwares.py
    config = load_sources_config("sources.yaml")  # Get config to find fetchdir
    fetchdir = config.get("fetchdir", "./tmpfw")
    downloaded_firmware = Path(fetchdir) / f"{name}.bin"

    if downloaded_firmware.exists():
        print(f"📦 Using downloaded factory image: {downloaded_firmware}")
        size_kb = downloaded_firmware.stat().st_size / 1024
        print(f"📊 Size: {size_kb:.1f} KB")
        return flash_factory_image(downloaded_firmware, port, baudrate)

    # If no downloaded image, create one from source
    print("📥 No downloaded factory image found, creating from source...")
    factory_image_path = create_factory_image(name, project_dir)
    if factory_image_path and factory_image_path.exists():
        print(f"📦 Created factory image: {factory_image_path}")
        return flash_factory_image(factory_image_path, port, baudrate)
    else:
        print("⚠️  Factory image creation failed, using direct PlatformIO upload")
        return flash_via_platformio(name, port, project_dir)


def create_factory_image(name: str, project_dir: Path) -> Path | None:
    """Create a factory image using PlatformIO."""
    print("🔧 Building factory image...")

    # First build the project to ensure all binaries exist
    try:
        subprocess.run(
            ["pio", "run"],
            cwd=str(project_dir),
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"❌ Build failed: {e}")
        return None

    # Find the build directory and binaries
    build_dir = project_dir / ".pio" / "build"
    if not build_dir.exists():
        print("❌ Build directory not found")
        return None

    # Look for environment directories (usually esp32dev, esp32, etc.)
    env_dirs = [d for d in build_dir.iterdir() if d.is_dir()]
    if not env_dirs:
        print("❌ No build environment found")
        return None

    env_dir = env_dirs[0]  # Take the first environment
    print(f"📂 Using build environment: {env_dir.name}")

    # Check for required files
    bootloader_bin = env_dir / "bootloader.bin"
    partitions_bin = env_dir / "partitions.bin"
    firmware_bin = env_dir / "firmware.bin"

    if not all(f.exists() for f in [bootloader_bin, partitions_bin, firmware_bin]):
        print("❌ Required binary files not found")
        return None

    # Create factory image using esptool merge-bin
    factory_image = project_dir / f"{name}-factory.bin"

    try:
        boot_app0_path = env_dir / "boot_app0.bin"

        # Use relative paths within project directory for cleaner commands
        rel_bootloader = Path(".pio/build") / env_dir.name / "bootloader.bin"
        rel_partitions = Path(".pio/build") / env_dir.name / "partitions.bin"
        rel_firmware = Path(".pio/build") / env_dir.name / "firmware.bin"
        rel_factory = Path(f"{name}-factory.bin")

        cmd = [
            "python",
            "-m",
            "esptool",
            "--chip",
            "esp32",
            "merge-bin",
            "-o",
            str(rel_factory),
            "--flash-mode",
            "dio",
            "--flash-freq",
            "40m",
            "--flash-size",
            "4MB",
            "0x1000",
            str(rel_bootloader),
            "0x8000",
            str(rel_partitions),
        ]

        # Add boot_app0.bin only if it exists
        if boot_app0_path.exists():
            rel_boot_app0 = Path(".pio/build") / env_dir.name / "boot_app0.bin"
            cmd.extend(["0xe000", str(rel_boot_app0)])

        # Add firmware at the end
        cmd.extend(["0x10000", str(rel_firmware)])

        print(f"🔧 Command: {' '.join(cmd)}")
        print(f"📂 Working directory: {project_dir}")

        # Run esptool from the project directory to fix path issues
        subprocess.run(
            cmd, cwd=str(project_dir), check=True, capture_output=True, text=True
        )

        if factory_image.exists():
            size_kb = factory_image.stat().st_size / 1024
            print(f"✅ Factory image created: {size_kb:.1f} KB")
            return factory_image
        else:
            print("❌ Factory image creation failed - file not created")
            return None

    except subprocess.CalledProcessError as e:
        print(f"❌ Factory image creation failed: {e}")
        return None
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return None


def flash_factory_image(factory_image: Path, port: str | None, baudrate: int) -> bool:
    """Flash the factory image using esptool."""
    print("⬇️  Flashing factory image...")

    # Build esptool command
    cmd = ["python", "-m", "esptool", "--baud", str(baudrate)]

    # Add port if specified
    if port:
        cmd.extend(["--port", port])

    # Add flash command and parameters
    cmd.extend(
        [
            "write-flash",
            "0x0",  # Flash address for factory firmware
            str(factory_image),
        ]
    )

    print(f"🔧 Command: {' '.join(cmd)}")
    print()

    try:
        subprocess.run(cmd, check=True)
        print("\n✅ Factory image flashed successfully!")
        return True

    except subprocess.CalledProcessError as e:
        print(f"\n❌ Flashing failed with exit code {e.returncode}")
        return False
    except Exception as e:
        print(f"❌ Error during flashing: {e}")
        return False


def flash_via_platformio(name: str, port: str | None, project_dir: Path) -> bool:
    """Fallback: Flash using direct PlatformIO upload."""
    print("🔄 Using direct PlatformIO upload...")

    # Build PlatformIO command
    cmd = ["pio", "run", "--target", "upload"]

    # Add port if specified
    if port:
        cmd.extend(["--upload-port", port])

    print(f"🔧 Command: {' '.join(cmd)}")
    print(f"📂 Working directory: {project_dir}")
    print()

    try:
        subprocess.run(
            cmd,
            cwd=str(project_dir),
            check=True,
            capture_output=False,  # Show live output
        )
        print("\n✅ Upload successful!")
        return True

    except subprocess.CalledProcessError as e:
        print(f"\n❌ Upload failed with exit code {e.returncode}")
        return False
    except FileNotFoundError:
        print("❌ PlatformIO not found. Install it with:")
        print("   pip install platformio")
        return False
    except Exception as e:
        print(f"❌ Error during upload: {e}")
        return False


def flash_binary_file(
    name: str, port: str | None, baudrate: int, config: dict, firmware_config: dict
) -> bool:
    """Flash firmware from binary file using esptool."""
    # Get firmware file path
    firmware_path = get_firmware_path(config, name)
    if not firmware_path.exists():
        print(f"❌ Firmware file not found: {firmware_path}")
        print("💡 Use 'uv run scripts/update_firmwares.py' to download firmware")
        return False

    print("🚀 ESP32 Firmware Flasher")
    print("━" * 50)
    print(f"📦 Firmware: {name}")
    print(f"📁 File: {firmware_path}")
    print("🔌 Chip: Auto-detect")
    if port:
        print(f"🔗 Port: {port}")
    else:
        print("🔗 Port: Auto-detect")
    print(f"⚡ Baudrate: {baudrate}")
    print()

    # Build esptool command
    cmd = ["python", "-m", "esptool", "--baud", str(baudrate)]

    # Add port if specified
    if port:
        cmd.extend(["--port", port])

    # Add flash command and parameters
    cmd.extend(
        [
            "write-flash",  # Updated to use hyphen instead of underscore
            "0x0",  # Flash address for factory firmware
            str(firmware_path),
        ]
    )

    print(f"🔧 Command: {' '.join(cmd)}")
    print()

    try:
        # Run esptool
        subprocess.run(cmd, check=True)
        print("\n✅ Firmware flashed successfully!")
        return True

    except subprocess.CalledProcessError as e:
        print(f"\n❌ Flashing failed with exit code {e.returncode}")
        return False
    except FileNotFoundError:
        print("❌ esptool not found. Install it with:")
        print("   pip install esptool")
        return False
    except Exception as e:
        print(f"❌ Error during flashing: {e}")
        return False


def flash_firmware(name: str, port: str | None, baudrate: int, config: dict) -> bool:
    """Flash firmware to ESP32 device using esptool or PlatformIO."""

    # Find firmware configuration
    firmware_config = find_firmware_config(config, name)
    if not firmware_config:
        print(f"❌ Firmware '{name}' not found in configuration")
        print("💡 Use --list to see available firmware")
        return False

    source_type = firmware_config.get("type", "unknown")

    # Handle local PlatformIO projects differently
    if source_type == "local":
        return flash_local_project(name, port, baudrate, firmware_config)
    else:
        return flash_binary_file(name, port, baudrate, config, firmware_config)


def main():
    """Main entry point."""
    args = docopt(__doc__)

    sources_file = args["--sources"]

    # Load configuration
    config = load_sources_config(sources_file)

    # List available firmware (default if no name provided or explicit --list)
    if args["--list"] or not args["<name>"]:
        list_available_firmware(config)
        return

    # Flash firmware
    name = args["<name>"]
    port = args["--port"]
    baudrate = int(args["--baudrate"])
    loop_mode = args["--loop"]

    # Handle loop mode for batch production
    if loop_mode:
        print("🏭 Batch Production Mode Enabled")
        print("━" * 60)
        print(f"📦 Firmware: {name}")
        print(f"⚡ Baudrate: {baudrate}")
        if port:
            print(f"🔗 Port: {port}")
        else:
            print("🔗 Port: Auto-detect")
        print("━" * 60)

        device_count = 0

        while True:
            device_count += 1
            print(f"\n🔢 Device #{device_count}")

            # Flash the firmware
            success = flash_firmware(name, port, baudrate, config)

            if success:
                print(f"✅ Device #{device_count} flashed successfully!")
            else:
                print(f"❌ Device #{device_count} failed to flash!")
                print("💡 Check connection and try again")

            # Wait for user input to continue or stop
            if not wait_for_user_input():
                break

        print(f"\n📊 Batch production completed: {device_count} device(s) processed")

    else:
        # Single device mode
        success = flash_firmware(name, port, baudrate, config)
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
