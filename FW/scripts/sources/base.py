"""
Abstract base class and implementations for firmware sources.
"""

from abc import ABC, abstractmethod
from typing import Any


class FirmwareSource(ABC):
    """Abstract base class for firmware sources."""

    def __init__(self, config: dict[str, Any]):
        self.name = config["name"]
        self.config = config

    @abstractmethod
    def download(
        self, target_dir: str, show_progress: bool = True, quiet: bool = False
    ) -> bool:
        """Download firmware from this source.

        Args:
            target_dir: Directory to save the firmware to
            show_progress: Whether to show download progress
            quiet: Whether to suppress output

        Returns:
            True if download was successful, False otherwise
        """
        pass

    @abstractmethod
    def get_info(self) -> dict[str, str]:
        """Get information about this source.

        Returns:
            Dictionary with source information (version, url, etc.)
        """
        pass
