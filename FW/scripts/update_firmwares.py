#!/usr/bin/env python3
"""
Firmware Downloader for KM271 Projects

Usage:
  update_firmwares.py [--sources=<yaml>] [--fetchdir=<dir>] [--no-progress] [--quiet]
  update_firmwares.py (-h | --help)
  update_firmwares.py --version

Options:
  --sources=<yaml>   YAML file with sources [default: sources.yaml]
  --fetchdir=<dir>   Target directory for downloads [default: ./tmpfw]
  --no-progress      Don't show progress bar
  --quiet            Show only error messages and summary
  -h --help          Show this help
  --version          Show version

Examples:
  update_firmwares.py
  update_firmwares.py --sources=sources.yaml --fetchdir=./firmware
  update_firmwares.py --quiet
"""

import os

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

    if not quiet:
        print("🚀 Firmware Downloader started")
        print(f"📁 Sources file: {sources_file}")
        print(f"📂 Target directory: {fetch_dir}")
        print(f"📊 Progress bar: {'On' if show_progress else 'Off'}")
        print(f"🔇 Quiet mode: {'On' if quiet else 'Off'}")

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

    # Process each source
    successful_downloads = 0
    failed_downloads = 0

    for source_config in sources_list:
        try:
            source = create_source(source_config)
            if source.download(fetch_dir, show_progress, quiet):
                successful_downloads += 1
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

    # Summary
    total = successful_downloads + failed_downloads
    if not quiet:
        print(f"\n🎉 Processing complete!")
        print(f"   ✅ Successful: {successful_downloads}/{total}")
        if failed_downloads > 0:
            print(f"   ❌ Failed: {failed_downloads}/{total}")
        print(f"   📂 Firmware saved to: {os.path.abspath(fetch_dir)}")

    return 0 if failed_downloads == 0 else 1


if __name__ == "__main__":
    exit(main())
