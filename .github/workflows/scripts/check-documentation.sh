#!/bin/bash

echo "🔍 Checking documentation files..."

# Check if DOC directory exists
if [ ! -d "DOC" ]; then
    echo "⚠️ DOC directory not found, creating it..."
    mkdir -p DOC
fi

cd DOC

# List all documentation files
echo "📋 Available documentation files:"
ls -la || echo "No files found"

# Check critical documentation  
if [ -f "Getting_Started.md" ]; then
  echo "✅ Found: Getting_Started.md"
  wc -l "Getting_Started.md" || echo "Could not count lines"
else
  echo "⚠️ Missing: Getting_Started.md"
fi

if [ -f "Erste_Schritte.md" ]; then
  echo "✅ Found: Erste_Schritte.md"
  wc -l "Erste_Schritte.md" || echo "Could not count lines"
else
  echo "⚠️ Missing: Erste_Schritte.md"
fi

if [ -f "Hardware Description.md" ]; then
  echo "✅ Found: Hardware Description.md"
  wc -l "Hardware Description.md" || echo "Could not count lines"
else
  echo "⚠️ Missing: Hardware Description.md"
fi

echo "✅ Documentation check completed"
