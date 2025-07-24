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
        """Copy the built firmware to target directory."""
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
