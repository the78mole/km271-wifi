"""
Local PlatformIO project source implementation.
"""

import os
import shutil
import subprocess
from typing import Any

from .base import FirmwareSource


class LocalPIOSource(FirmwareSource):
    """Source for local PlatformIO projects."""

    def __init__(self, config: dict[str, Any]):
        super().__init__(config)
        self.project_path = config["path"]
        self.platform = config.get("platform", "pio")

    def download(
        self, target_dir: str, show_progress: bool = True, quiet: bool = False
    ) -> bool:
        """Build local PlatformIO project and copy firmware."""
        try:
            if not quiet:
                self._print_header()

            if not self._project_exists():
                print(f"❌ Project not found: {self.project_path}")
                return False

            if not self._build_project(quiet):
                return False

            return self._copy_firmware(target_dir, quiet)

        except Exception as e:
            print(f"❌ Error: {e}")
            return False

    def get_info(self) -> dict[str, str]:
        """Get information about this local source."""
        return {
            "type": "local",
            "platform": self.platform,
            "path": self.project_path,
            "exists": str(self._project_exists()),
        }

    def _print_header(self):
        """Print a header for this source."""
        print("\n" + "━" * 60)
        print(f"🔨 {self.name} (local build)")
        print("━" * 60)

    def _project_exists(self) -> bool:
        """Check if the project directory exists."""
        return os.path.exists(self.project_path) and os.path.exists(
            os.path.join(self.project_path, "platformio.ini")
        )

    def _build_project(self, quiet: bool) -> bool:
        """Build the PlatformIO project."""
        if not quiet:
            print("🔨 Building project...")

        try:
            cmd = ["pio", "run"]
            subprocess.run(
                cmd, cwd=self.project_path, capture_output=quiet, text=True, check=True
            )

            if not quiet:
                print("✅ Build successful")
            return True

        except subprocess.CalledProcessError as e:
            print(f"❌ Build failed: {e}")
            if not quiet and e.stdout:
                print("Build output:", e.stdout)
            if not quiet and e.stderr:
                print("Build errors:", e.stderr)
            return False
        except FileNotFoundError:
            print("❌ PlatformIO not found. Please install PlatformIO.")
            return False

    def _copy_firmware(self, target_dir: str, quiet: bool) -> bool:
        """Create factory image and copy to target directory."""

        # Try to create factory image first
        factory_image = self._create_factory_image(quiet)
        if factory_image and os.path.exists(factory_image):
            dest_path = os.path.join(target_dir, f"{self.name}.bin")
            try:
                shutil.copy2(factory_image, dest_path)
                if not quiet:
                    size = os.path.getsize(dest_path)
                    print(
                        f"✅ Factory image copied to {dest_path} ({size / 1024:.1f} KB)"
                    )
                return True
            except Exception as e:
                print(f"❌ Factory image copy failed: {e}")

        # Fallback to normal firmware.bin if factory image failed
        if not quiet:
            print("⚠️  Factory image creation failed, using normal firmware.bin")

        return self._copy_normal_firmware(target_dir, quiet)

    def _create_factory_image(self, quiet: bool) -> str | None:
        """Create a factory image using esptool merge-bin."""
        if not quiet:
            print("🔧 Creating factory image...")

        # Find build directory
        build_dir = os.path.join(self.project_path, ".pio", "build")
        if not os.path.exists(build_dir):
            if not quiet:
                print("❌ Build directory not found")
            return None

        # Find environment directory
        env_dirs = [
            d
            for d in os.listdir(build_dir)
            if os.path.isdir(os.path.join(build_dir, d))
        ]
        if not env_dirs:
            if not quiet:
                print("❌ No build environment found")
            return None

        env_dir = os.path.join(build_dir, env_dirs[0])
        if not quiet:
            print(f"📂 Using build environment: {env_dirs[0]}")

        # Check for required files
        bootloader_bin = os.path.join(env_dir, "bootloader.bin")
        partitions_bin = os.path.join(env_dir, "partitions.bin")
        firmware_bin = os.path.join(env_dir, "firmware.bin")

        if not all(
            os.path.exists(f) for f in [bootloader_bin, partitions_bin, firmware_bin]
        ):
            if not quiet:
                print("❌ Required binary files not found")
            return None

        # Create factory image
        factory_image = os.path.join(self.project_path, f"{self.name}-factory.bin")

        try:
            # Use relative paths for cleaner command
            rel_bootloader = os.path.join(
                ".pio", "build", env_dirs[0], "bootloader.bin"
            )
            rel_partitions = os.path.join(
                ".pio", "build", env_dirs[0], "partitions.bin"
            )
            rel_firmware = os.path.join(".pio", "build", env_dirs[0], "firmware.bin")
            rel_factory = f"{self.name}-factory.bin"

            cmd = [
                "python",
                "-m",
                "esptool",
                "--chip",
                "esp32",
                "merge-bin",
                "-o",
                rel_factory,
                "--flash-mode",
                "dio",
                "--flash-freq",
                "40m",
                "--flash-size",
                "4MB",
                "0x1000",
                rel_bootloader,
                "0x8000",
                rel_partitions,
                "0x10000",
                rel_firmware,
            ]

            # Check for optional boot_app0.bin
            boot_app0_path = os.path.join(env_dir, "boot_app0.bin")
            if os.path.exists(boot_app0_path):
                rel_boot_app0 = os.path.join(
                    ".pio", "build", env_dirs[0], "boot_app0.bin"
                )
                # Insert boot_app0 before firmware
                cmd.insert(-2, "0xe000")
                cmd.insert(-2, rel_boot_app0)

            if not quiet:
                print(f"🔧 Command: {' '.join(cmd)}")

            subprocess.run(
                cmd, cwd=self.project_path, check=True, capture_output=True, text=True
            )

            if os.path.exists(factory_image):
                if not quiet:
                    size = os.path.getsize(factory_image)
                    print(f"✅ Factory image created: {size / 1024:.1f} KB")
                return factory_image
            else:
                if not quiet:
                    print("❌ Factory image creation failed - file not created")
                return None

        except subprocess.CalledProcessError as e:
            if not quiet:
                print(f"❌ Factory image creation failed: {e}")
            return None
        except Exception as e:
            if not quiet:
                print(f"❌ Unexpected error: {e}")
            return None

    def _copy_normal_firmware(self, target_dir: str, quiet: bool) -> bool:
        """Copy the normal firmware.bin to target directory (fallback)."""
        # Common PlatformIO build output locations
        possible_paths = [
            ".pio/build/esp32dev/firmware.bin",
            ".pio/build/esp32/firmware.bin",
            ".pio/build/default/firmware.bin",
        ]

        source_path = None
        for path in possible_paths:
            full_path = os.path.join(self.project_path, path)
            if os.path.exists(full_path):
                source_path = full_path
                break

        if not source_path:
            print("❌ Built firmware not found in expected locations")
            return False

        dest_path = os.path.join(target_dir, f"{self.name}.bin")

        try:
            shutil.copy2(source_path, dest_path)
            if not quiet:
                size = os.path.getsize(dest_path)
                print(f"✅ Copied to {dest_path} ({size / 1024:.1f} KB)")
            return True

        except Exception as e:
            print(f"❌ Copy failed: {e}")
            return False
