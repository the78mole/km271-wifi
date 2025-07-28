#!/bin/bash

echo "🔗 Checking documentation links..."
cd DOC

# Check for broken internal links in Markdown files
for file in *.md; do
  if [ -f "$file" ]; then
    echo "Checking links in $file..."
    
    # Extract markdown links and check if referenced files exist
    grep -o '\[.*\](.*\.md)' "$file" | sed 's/.*(\(.*\))/\1/' | while read -r link; do
      if [ ! -f "$link" ] && [ ! -f "../$link" ]; then
        echo "⚠️ Potential broken link in $file: $link"
      fi
    done
    
    # Check image references
    grep -o '!\[.*\](.*\.(jpg\|png\|gif\|svg))' "$file" | sed 's/.*(\(.*\))/\1/' | while read -r img; do
      if [ ! -f "$img" ] && [ ! -f "../$img" ]; then
        echo "⚠️ Missing image in $file: $img"
      fi
    done
  fi
done

echo "✅ Link check completed"
