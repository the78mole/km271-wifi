"""
GitHub-based firmware source implementation.
"""

import os
import re
from typing import Any

import requests
from github import Github, GithubException

from .base import FirmwareSource


class GitHubSource(FirmwareSource):
    """Firmware source that downloads from GitHub releases."""

    def __init__(self, config: dict[str, Any]):
        super().__init__(config)
        self.repo_name = config["repo"]
        self.asset_pattern = config["asset_pattern"]
        self.current_version = config.get("current_version", "")
        self.github_client = Github()

    def download(
        self, target_dir: str, show_progress: bool = True, quiet: bool = False
    ) -> bool:
        """Download firmware from GitHub release."""
        try:
            if not quiet:
                self._print_header()

            repo = self.github_client.get_repo(self.repo_name)

            # Get the release to use (specific version or latest)
            release, is_latest = self._get_target_release(repo, quiet)
            if not release:
                return False

            if not quiet:
                print(f"🔖 Release: {release.tag_name}")
                if not is_latest:
                    print("📌 Using pinned version")
                print(f"🔍 Asset pattern: {self._get_resolved_pattern()}")

            matching_asset = self._find_matching_asset(release)
            if not matching_asset:
                print("❌ No matching asset found.")
                return False

            return self._download_asset(
                matching_asset, target_dir, show_progress, quiet
            )

        except GithubException as e:
            print(f"❌ GitHub API error: {e}")
            return False
        except Exception as e:
            print(f"❌ Error: {e}")
            return False

    def get_info(self) -> dict[str, str]:
        """Get information about this GitHub source."""
        try:
            repo = self.github_client.get_repo(self.repo_name)
            latest_release = repo.get_latest_release()
            target_release, _ = self._get_target_release(repo, quiet=True)

            return {
                "type": "github",
                "repo": self.repo_name,
                "latest_version": latest_release.tag_name,
                "target_version": target_release.tag_name,
                "pattern": self.asset_pattern,
                "current_version": self.current_version,
            }
        except Exception:
            return {
                "type": "github",
                "repo": self.repo_name,
                "latest_version": "unknown",
                "target_version": self.current_version or "latest",
                "pattern": self.asset_pattern,
                "current_version": self.current_version,
            }

    def _print_header(self):
        """Print a header for this source."""
        print("\n" + "━" * 60)
        print(f"📦 {self.name} ({self.repo_name})")
        print("━" * 60)

    def _get_resolved_pattern(self) -> str:
        """Get the asset pattern with version placeholders resolved."""
        return self.asset_pattern.replace("${revision}", self.current_version)

    def _get_target_release(self, repo, quiet: bool = False):
        """Get the target release (specific version or latest) and check for updates."""
        latest_release = repo.get_latest_release()

        # If no specific version is configured, use latest
        if not self.current_version:
            return latest_release, True

        # Try to find the specific version
        try:
            target_release = repo.get_release(self.current_version)

            # Check if there's a newer version available
            if not quiet and target_release.tag_name != latest_release.tag_name:
                print(
                    f"⚠️  Newer version available: {latest_release.tag_name} "
                    f"(using {target_release.tag_name})"
                )

            return target_release, False

        except GithubException:
            # Version not found, fall back to latest
            if not quiet:
                print(
                    f"⚠️  Version {self.current_version} not found, "
                    f"using latest: {latest_release.tag_name}"
                )
            return latest_release, True

    def _find_matching_asset(self, release):
        """Find the asset that matches our pattern."""
        pattern_resolved = self._get_resolved_pattern()
        regex = re.compile(pattern_resolved)

        for asset in release.get_assets():
            if regex.match(asset.name):
                return asset
        return None

    def _download_asset(
        self, asset, target_dir: str, show_progress: bool, quiet: bool
    ) -> bool:
        """Download a specific asset."""
        url = asset.browser_download_url
        dest_path = os.path.join(target_dir, f"{self.name}.bin")

        if not quiet:
            print(f"⬇️  Downloading asset: {asset.name}")

        return self._download_with_progress(url, dest_path, show_progress, quiet)

    def _download_with_progress(
        self, url: str, dest_path: str, show_progress: bool, quiet: bool
    ) -> bool:
        """Download file with optional progress bar."""
        try:
            with requests.get(url, stream=True) as r:
                r.raise_for_status()
                total = int(r.headers.get("Content-Length", 0))
                downloaded = 0
                chunk_size = 8192

                with open(dest_path, "wb") as f:
                    for chunk in r.iter_content(chunk_size=chunk_size):
                        if chunk:
                            f.write(chunk)
                            downloaded += len(chunk)
                            if show_progress and not quiet and total:
                                done = int(50 * downloaded / total)
                                print(
                                    f"\r    ▶ Downloading: "
                                    f"[{'#' * done:<50}] "
                                    f"{downloaded / 1024:.1f} KB",
                                    end="",
                                )

            if not quiet:
                print(f"\n✅ Downloaded to {dest_path} ({downloaded / 1024:.1f} KB)")
            return True

        except Exception as e:
            print(f"❌ Download failed: {e}")
            return False

    def __del__(self):
        """Close the GitHub client when the object is destroyed."""
        if hasattr(self, "github_client"):
            self.github_client.close()
