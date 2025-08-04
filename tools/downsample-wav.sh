#!/bin/bash
# downsample_wav.sh — converts WAV files from 96kHz to 48kHz

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 file1.wav [file2.wav ...]"
  echo "Output files will be named <original>_48k.wav"
  exit 1
fi

for FILE in "$@"; do
  BASENAME="${FILE%.*}"
  OUT="${BASENAME}_48k.wav"

  echo "Converting $FILE -> $OUT"

  ffmpeg -y -i "$FILE" -ar 48000 "$OUT"
done

echo "✅ Done."
