#!/bin/bash
# swap_96k_48k.sh — renames song.wav -> song_96k.wav and song_48k.wav -> song.wav

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 path/to/*/song.wav [more paths...]"
  exit 1
fi

for FILE in "$@"; do
  DIR=$(dirname "$FILE")
  ORIGINAL="$DIR/song.wav"
  BACKUP="$DIR/song_96k.wav"
  NEW="$DIR/song_48k.wav"

  # Rename song.wav -> song_96k.wav
  if [ -f "$ORIGINAL" ]; then
    echo "Renaming $ORIGINAL -> $BACKUP"
    mv "$ORIGINAL" "$BACKUP"
  else
    echo "❌ $ORIGINAL not found, skipping"
    continue
  fi

  # Rename song_48k.wav -> song.wav
  if [ -f "$NEW" ]; then
    echo "Renaming $NEW -> $ORIGINAL"
    mv "$NEW" "$ORIGINAL"
  else
    echo "⚠️ $NEW not found, skipping restore"
  fi
done

echo "✅ All done."
