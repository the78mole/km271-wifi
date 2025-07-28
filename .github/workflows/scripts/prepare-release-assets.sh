#!/bin/bash
set -e

VERSION="$1"

echo "📦 Preparing release assets..."

# Create release directory
mkdir -p final-release

# Package hardware releases dynamically
cd release-artifacts

# Create ZIP files for each hardware project
for project_dir in *-release-${VERSION}/; do
  if [ -d "$project_dir" ]; then
    project_name=$(basename "$project_dir" | sed "s/-release-${VERSION}$//")
    
    # Skip documentation directory (handled separately)
    if [ "$project_name" != "Documentation" ]; then
      echo "Packaging ${project_name}..."
      cd "$project_dir"
      zip -r "../../final-release/${project_name}-HardwareRelease-${VERSION}.zip" . -x "*.DS_Store"
      cd ..
    fi
  fi
done

# Package documentation
if [ -d "Documentation-release-${VERSION}" ]; then
  echo "Packaging Documentation..."
  cd "Documentation-release-${VERSION}"
  zip -r "../../final-release/KM271-WiFi-Documentation-${VERSION}.zip" . -x "*.DS_Store"
  cd ..
fi

cd ../final-release
echo "📋 Final release assets:"
ls -la

# Calculate checksums
echo "🔐 Generating checksums..."
for file in *.zip; do
  if [ -f "$file" ]; then
    sha256sum "$file" >> checksums.txt
  fi
done

echo "📋 Checksums:"
cat checksums.txt
