#!/bin/bash

echo "🔧 DevContainer Pre-Launch Validation"
echo "=====================================  "

echo ""
echo "✅ Docker Image Check:"
docker images | grep "ghcr.io/the78mole/kicaddev" | head -1

echo ""
echo "📋 DevContainer Configuration Check:"
if [ -f ".devcontainer/devcontainer.json" ]; then
    echo "✅ devcontainer.json exists"
    echo "Image: $(grep '"image"' .devcontainer/devcontainer.json | cut -d'"' -f4)"
else
    echo "❌ devcontainer.json not found"
fi

echo ""
echo "📋 Documentation Check:"
if [ -f ".devcontainer/README.md" ]; then
    echo "✅ DevContainer documentation exists"
    echo "Lines: $(wc -l < .devcontainer/README.md)"
else
    echo "❌ DevContainer documentation not found"
fi

echo ""
echo "🐳 Container Quick Test:"
echo "Testing if container can start and run basic commands..."
docker run --rm ghcr.io/the78mole/kicaddev:1.3.0 bash -c "
echo 'Container startup: ✅'
echo 'KiCad version:' \$(kicad-cli version 2>/dev/null | head -1 || echo 'KiCad CLI not found')
echo 'Python version:' \$(python3 --version)
echo 'Available tools:'
which pandoc >/dev/null && echo '  - pandoc: ✅' || echo '  - pandoc: ❌'
which asciidoctor >/dev/null && echo '  - asciidoctor: ✅' || echo '  - asciidoctor: ❌'
which pcbdraw >/dev/null && echo '  - pcbdraw: ✅' || echo '  - pcbdraw: ❌'
which kikit >/dev/null && echo '  - kikit: ✅' || echo '  - kikit: ❌'
"

echo ""
echo "🎯 DevContainer Ready!"
echo "Run 'code .' and open in DevContainer to start developing."
