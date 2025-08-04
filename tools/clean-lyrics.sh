#!/bin/bash
# Usage: ./clean-lyrics.sh */lyrics.txt
# Removes lines that contain any [BRACKETED] text

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 lyrics_file1 [lyrics_file2 ...]"
  exit 1
fi

for FILE in "$@"; do
  echo "🧽 Cleaning $FILE"
  # Filter lines that don't contain square-bracketed content
  grep -vE '\[.*\]' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
done

echo "✅ All files cleaned"

