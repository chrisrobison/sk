#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <wav-file1> [wav-file2 ...]"
  exit 1
fi

for src in "$@"; do
  dir=$(dirname "$src")
  name=$(basename "$src" .wav)
  ffmpeg -y -i "$src" -ar 44100 -c:a flac "$dir/${name}.flac"
done
