#!/bin/bash
set -e

VERSION="$1"
GITHUB_REPOSITORY="$2"

echo "🧪 Local Build Test Summary (act environment)"
echo "=============================================="
echo ""
echo "✅ Hardware builds completed successfully!"
echo "✅ Documentation build completed successfully!"
echo ""
echo "📋 Build artifacts would be created in production:"

# List hardware packages dynamically
if [ -d "release-artifacts" ]; then
  for project_dir in release-artifacts/*-release-${VERSION}/; do
    if [ -d "$project_dir" ]; then
      project_name=$(basename "$project_dir" | sed "s/-release-${VERSION}$//")
      if [ "$project_name" != "Documentation" ]; then
        echo "- $project_name hardware release package"
      fi
    fi
  done
else
  echo "- Hardware release packages (artifacts not available in local test)"
fi

echo "- Complete documentation package"
echo ""
echo "ℹ️  Note: Artifact upload/download skipped in local testing"
echo "ℹ️  Note: GitHub release creation skipped in local testing"
echo ""
echo "🎉 Local workflow test completed successfully!"
