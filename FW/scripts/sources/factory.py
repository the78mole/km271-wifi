"""
Factory for creating firmware source instances.
"""

from typing import Any

from .base import FirmwareSource
from .github import GitHubSource
from .local_pio import LocalPIOSource


def create_source(config: dict[str, Any]) -> FirmwareSource:
    """Create a firmware source instance based on configuration.

    Args:
        config: Source configuration dictionary

    Returns:
        FirmwareSource instance

    Raises:
        ValueError: If source type is not supported
    """
    source_type = config.get("type")

    if source_type == "github":
        return GitHubSource(config)
    elif source_type == "local":
        return LocalPIOSource(config)
    else:
        raise ValueError(f"Unsupported source type: {source_type}")
