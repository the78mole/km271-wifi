#!/usr/bin/env python3
"""
Firmware Downloader for KM271 Projects

Usage:
  update_firmwares.py [--sources=<yaml>] [--fetchdir=<dir>] [--no-progress] [--quiet] [--save-versions]
  update_firmwares.py (-h | --help)
  update_firmwares.py --version

Options:
  --sources=<yaml>   YAML file with sources [default: sources.yaml]
  --fetchdir=<dir>   Target directory for downloads [default: ./tmpfw]
  --no-progress      Don't show progress bar
  --quiet            Show only error messages and summary
  --save-versions    Save version information to versions.json
  -h --help          Show this help
  --version          Show version

Examples:
  update_firmwares.py
  update_firmwares.py --sources=sources.yaml --fetchdir=./firmware
  update_firmwares.py --quiet --save-versions
"""

import json
import os
from datetime import UTC, datetime

import yaml
from docopt import docopt
from sources import create_source


def main():
    """Main function of the firmware downloader."""
    args = docopt(__doc__, version="Firmware Downloader 1.0.0")

    sources_file = args["--sources"]
    fetch_dir = args["--fetchdir"]
    show_progress = not args["--no-progress"]
    quiet = args["--quiet"]
    save_versions = args["--save-versions"]

    if not quiet:
        print("🚀 Firmware Downloader started")
        print(f"📁 Sources file: {sources_file}")
        print(f"📂 Target directory: {fetch_dir}")
        print(f"📊 Progress bar: {'On' if show_progress else 'Off'}")
        print(f"🔇 Quiet mode: {'On' if quiet else 'Off'}")
        if save_versions:
            print("📋 Version info: Will be saved")

    # Create target directory
    os.makedirs(fetch_dir, exist_ok=True)

    # Load sources configuration
    try:
        with open(sources_file) as f:
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
    version_info = (
        {
            "build_timestamp": datetime.now(UTC).isoformat().replace("+00:00", "Z"),
            "sources": {},
        }
        if save_versions
        else None
    )

    for source_config in sources_list:
        try:
            source = create_source(source_config)
            if source.download(fetch_dir, show_progress, quiet):
                successful_downloads += 1

                # Collect version information if requested
                if save_versions and hasattr(source, "get_info"):
                    # Skip local sources for release builds
                    if source_config.get("type") != "local":
                        info = source.get_info()
                        version_info["sources"][source.name] = info
                        if not quiet:
                            version = info.get("target_version", "unknown")
                            print(f"📋 {source.name}: {version}")
            else:
                failed_downloads += 1
        except ValueError as e:
            print(f"❌ Configuration error: {e}")
            failed_downloads += 1
        except Exception as e:
            source_name = source_config.get("name", "unknown")
            print(f"❌ Unexpected error with source {source_name}: {e}")
            failed_downloads += 1

    # Save version information if requested
    if save_versions and version_info:
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
        print("\n🎉 Processing complete!")
        print(f"   ✅ Successful: {successful_downloads}/{total}")
        if failed_downloads > 0:
            print(f"   ❌ Failed: {failed_downloads}/{total}")
        print(f"   📂 Firmware saved to: {os.path.abspath(fetch_dir)}")

    return 0 if failed_downloads == 0 else 1


if __name__ == "__main__":
    exit(main())
