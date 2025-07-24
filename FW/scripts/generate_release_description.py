#!/usr/bin/env python3
"""
Generate Release Description from versions.json

This script reads the versions.json file and generates a markdown description
for GitHub releases.

Usage:
  generate_release_description.py [--versions=<json>] [--output=<md>]
  generate_release_description.py (-h | --help)

Options:
  --versions=<json>  Path to versions.json file [default: tmpfw/versions.json]
  --output=<md>      Output markdown file [default: release_description.md]
  -h --help          Show this help
"""

import json
import sys

from docopt import docopt


def main():
    """Generate release description from versions.json."""
    args = docopt(__doc__)

    versions_file = args["--versions"]
    output_file = args["--output"]

    try:
        # Read version information
        with open(versions_file) as f:
            data = json.load(f)

        sources = data.get("sources", {})
        build_time = data.get("build_timestamp", "unknown")

        # Generate markdown content
        content = ["## Firmware Versions", ""]
        content.append(f"Build timestamp: {build_time}")
        content.append("")

        if sources:
            for name, info in sources.items():
                repo = info.get("repo", "unknown")
                version = info.get("target_version", "unknown")
                latest = info.get("latest_version", "unknown")

                content.append(
                    f"- **{name}**: `{version}` from [{repo}](https://github.com/{repo})"
                )
                if version != latest and latest != "unknown":
                    content.append(f"  - Latest available: `{latest}`")
        else:
            content.append("No version information available")

        # Write markdown file
        with open(output_file, "w") as f:
            f.write("\n".join(content))

        print(f"✅ Release description written to: {output_file}")

        # Also print to stdout for verification
        print("\nGenerated description:")
        print("\n".join(content))

    except FileNotFoundError:
        print(f"❌ Versions file not found: {versions_file}")
        return 1
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in versions file: {e}")
        return 1
    except Exception as e:
        print(f"❌ Error generating release description: {e}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
