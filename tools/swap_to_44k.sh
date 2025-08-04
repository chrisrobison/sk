#!/bin/bash
# swap_to_44k.sh — renames song.wav -> song_oem.wav and song-44k.wav -> song.wav

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 path/to/*/song.wav [more paths...]"
  exit 1
fi

for FILE in "$@"; do
  DIR=$(dirname "$FILE")
  ORIGINAL="$DIR/song.wav"
  BACKUP="$DIR/song_oem.wav"
  NEW="$DIR/song-44k.wav"

  # Rename song.wav -> song_oem.wav
  if [ -f "$ORIGINAL" ]; then
    echo "Renaming $ORIGINAL -> $BACKUP"
    cp "$ORIGINAL" "$BACKUP"
  else
    echo "❌ $ORIGINAL not found, skipping"
    continue
  fi

  # Rename song_44k.wav -> song.wav
  if [ -f "$NEW" ]; then
    echo "Renaming $NEW -> $ORIGINAL"
    cp "$NEW" "$ORIGINAL"
  else
    echo "⚠️ $NEW not found, skipping restore"
  fi
done

echo "✅ All done."
