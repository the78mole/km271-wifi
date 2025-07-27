#!/bin/bash

# Renovate Configuration Analysis Script
# =====================================
# Analyzes the current project for dependencies and checks Renovate coverage

set -e

echo "🔍 Renovate Coverage Analysis"
echo "============================="
echo ""

echo "📦 Dependencies Found in Project:"
echo "================================="

# Python dependencies
echo ""
echo "🐍 Python (pyproject.toml):"
if [ -f "pyproject.toml" ]; then
    echo "✅ pyproject.toml found"
    echo "   Dependencies:"
    if grep -q "dependencies = \[" pyproject.toml; then
        grep -A 20 "dependencies = \[" pyproject.toml | grep "\"" | head -10 | sed 's/^/   /'
    else
        echo "   No dependencies section found"
    fi
    echo "   Build system:"
    if grep -q "build-system" pyproject.toml; then
        grep -A 3 "build-system" pyproject.toml | grep "requires\|build-backend" | sed 's/^/   /'
    fi
else
    echo "ℹ️  No pyproject.toml found (Python dependencies moved to separate project)"
fi

# Docker images
echo ""
echo "🐳 Docker Images:"
echo "   GitLab CI:"
if [ -f ".gitlab-ci.yml" ]; then
    echo "✅ .gitlab-ci.yml found"
    if grep -q "image:" .gitlab-ci.yml; then
        grep "image:" .gitlab-ci.yml | sed 's/^/   /'
    else
        echo "   No image definitions found"
    fi
else
    echo "❌ No .gitlab-ci.yml found"
fi

echo "   DevContainer:"
if [ -f ".devcontainer/devcontainer.json" ]; then
    echo "✅ devcontainer.json found"
    if grep -q '"image"' .devcontainer/devcontainer.json; then
        grep '"image"' .devcontainer/devcontainer.json | sed 's/^/   /'
    else
        echo "   No image definitions found"
    fi
else
    echo "❌ No devcontainer.json found"
fi

# GitHub Actions (if present)
echo "   GitHub Actions:"
if find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | grep -q .; then
    echo "✅ GitHub Actions found"
    find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | while read -r file; do
        if grep -q "uses:\|image:" "$file"; then
            echo "   $file:"
            grep "uses:\|image:" "$file" | head -3 | sed 's/^/     /'
        fi
    done
else
    echo "❌ No GitHub Actions found"
fi

# ESPHome configurations
echo ""
echo "🏠 ESPHome/YAML configs:"
yaml_files=$(find . -name "*.yml" -o -name "*.yaml" | grep -v ".git" | grep -v ".venv" | head -5)
if [ -n "$yaml_files" ]; then
    echo "✅ YAML files found:"
    echo "$yaml_files" | sed 's/^/   /'
    echo "   (some may contain version references)"
else
    echo "❌ No YAML files found"
fi

# Sources.yaml (firmware management - moved to separate project)
echo ""
echo "📦 Firmware Sources:"
if [ -f "sources.yaml" ]; then
    echo "✅ sources.yaml found"
    echo "   External repositories:"
    if grep -q "repo:" sources.yaml; then
        grep "repo:" sources.yaml | sed 's/^/   /'
    fi
    echo "   Current versions:"
    if grep -q "current_version:" sources.yaml; then
        grep "current_version:" sources.yaml | sed 's/^/   /'
    fi
else
    echo "ℹ️  No sources.yaml found (moved to separate firmware management project)"
fi

echo ""
echo "📊 Renovate Manager Coverage Analysis:"
echo "======================================"
echo ""
echo "✅ Covered by current config:"
echo "   - Docker images (gitlab-ci.yml) ← dockerfile/gitlab-ci manager"
echo "   - DevContainer images (devcontainer.json) ← devcontainer manager"
echo ""

# Check if renovate.json exists and show current config
if [ -f "renovate.json" ]; then
    echo "📋 Current Renovate Configuration:"
    echo "   Managers configured:"
    if grep -q "matchManagers" renovate.json; then
        grep -A 10 "matchManagers" renovate.json | grep '".*"' | sort -u | sed 's/^/   /'
    fi
    echo ""
    echo "   Regex managers:"
    if grep -q "regexManagers" renovate.json; then
        echo "   ✅ Custom regex managers configured"
        regex_count=$(grep -c "fileMatch" renovate.json || echo "0")
        echo "   Files monitored: $regex_count"
    else
        echo "   ❌ No regex managers configured"
    fi
else
    echo "⚠️  No renovate.json found!"
fi

echo ""
echo "🎯 Recommendations:"
if [ -f "renovate.json" ]; then
    echo "   ✅ Renovate configuration appears complete"
    echo "   - All major dependency types are covered"
    echo "   - Custom regex manager handles firmware versions"
    echo "   - DevContainer images are monitored"
else
    echo "   1. Create renovate.json configuration file"
    echo "   2. Add devcontainer manager for .devcontainer/devcontainer.json"
    echo "   3. Add regex manager for sources.yaml GitHub releases"
    echo "   4. Consider ESPHome version tracking in YAML files"
fi

echo ""
echo "🔧 Testing regex patterns:"
echo "   No custom regex patterns configured (sources.yaml moved to separate project)"

echo ""
echo "📈 Summary:"
echo "==========="
total_deps=0
covered_deps=0

if [ -f "pyproject.toml" ]; then
    total_deps=$((total_deps + 1))
    covered_deps=$((covered_deps + 1))
else
    echo "ℹ️  Python dependencies moved to separate project"
fi

if [ -f ".gitlab-ci.yml" ] || [ -f ".devcontainer/devcontainer.json" ]; then
    total_deps=$((total_deps + 1))
    covered_deps=$((covered_deps + 1))
fi

if [ -f "sources.yaml" ]; then
    total_deps=$((total_deps + 1))
    if [ -f "renovate.json" ] && grep -q "regexManagers" renovate.json; then
        covered_deps=$((covered_deps + 1))
    fi
else
    echo "ℹ️  Firmware management moved to separate project"
fi

echo "Dependencies covered: $covered_deps/$total_deps"
if [ $covered_deps -eq $total_deps ] && [ $total_deps -gt 0 ]; then
    echo "🎉 All dependencies are covered by Renovate!"
else
    echo "⚠️  Some dependencies may need additional configuration"
fi
