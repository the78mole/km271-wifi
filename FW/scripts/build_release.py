#!/usr/bin/env python3
"""
Release Builder for KM271 Firmware Images

This script downloads all firmware images and collects version information
for GitHub release creation.

Usage:
  build_release.py [--sources=<yaml>] [--fetchdir=<dir>] [--quiet]
  build_release.py (-h | --help)
  build_release.py --version

Options:
  --sources=<yaml>   YAML file with sources [default: sources.yaml]
  --fetchdir=<dir>   Target directory for downloads [default: ./tmpfw]
  --quiet            Show only error messages and summary
  -h --help          Show this help
  --version          Show version

Output:
  - Downloads all firmware images
  - Creates versions.json with version information
  - Returns exit code 0 on success, 1 on failure
"""

import json
import os
from datetime import datetime

import yaml
from docopt import docopt
from sources import create_source


def main():
    """Main function of the release builder."""
    args = docopt(__doc__, version="Release Builder 1.0.0")

    sources_file = args["--sources"]
    fetch_dir = args["--fetchdir"]
    quiet = args["--quiet"]

    if not quiet:
        print("🎯 KM271 Release Builder started")
        print(f"📁 Sources file: {sources_file}")
        print(f"📂 Target directory: {fetch_dir}")

    # Create target directory
    os.makedirs(fetch_dir, exist_ok=True)

    # Load sources configuration
    try:
        with open(sources_file, "r") as f:
            config = yaml.safe_load(f)
            sources_list = config.get("sources", [])
            # Override fetchdir if specified in config
            if "fetchdir" in config:
                fetch_dir = config["fetchdir"]
    except FileNotFoundError:
        print(f"❌ Sources file not found: {sources_file}")
        return 1
    except yaml.YAMLError as e:
        print(f"❌ Error parsing YAML file: {e}")
        return 1

    if not sources_list:
        print("❌ No sources found in configuration")
        return 1

    # Process each source and collect version information
    successful_downloads = 0
    failed_downloads = 0
    version_info = {
        "build_timestamp": datetime.utcnow().isoformat() + "Z",
        "sources": {},
    }

    for source_config in sources_list:
        try:
            source = create_source(source_config)

            # Skip local sources in release builds
            if source_config.get("type") == "local":
                if not quiet:
                    print(f"⏭️  Skipping local source: {source.name}")
                continue

            if source.download(fetch_dir, show_progress=not quiet, quiet=quiet):
                successful_downloads += 1

                # Collect version information for GitHub sources
                if hasattr(source, "get_version_info"):
                    info = source.get_version_info()
                    version_info["sources"][source.name] = info
                    if not quiet:
                        print(
                            f"📋 {source.name}: {info.get('target_version', 'unknown')}"
                        )
            else:
                failed_downloads += 1
        except ValueError as e:
            print(f"❌ Configuration error: {e}")
            failed_downloads += 1
        except Exception as e:
            print(
                f"❌ Unexpected error with source {source_config.get('name', 'unknown')}: {e}"
            )
            failed_downloads += 1

    # Save version information
    versions_file = os.path.join(fetch_dir, "versions.json")
    try:
        with open(versions_file, "w") as f:
            json.dump(version_info, f, indent=2)
        if not quiet:
            print(f"📄 Version info saved to: {versions_file}")
    except Exception as e:
        print(f"❌ Failed to save version info: {e}")
        return 1

    # Summary
    total = successful_downloads + failed_downloads
    if not quiet:
        print(f"\n🎉 Release build complete!")
        print(f"   ✅ Successful: {successful_downloads}/{total}")
        if failed_downloads > 0:
            print(f"   ❌ Failed: {failed_downloads}/{total}")
        print(f"   📂 Firmware saved to: {os.path.abspath(fetch_dir)}")

    return 0 if failed_downloads == 0 else 1


if __name__ == "__main__":
    exit(main())
