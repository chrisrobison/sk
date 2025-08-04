#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 file1 [file2 ...]"
  exit 1
fi

for src in "$@"; do
  dir=$(dirname "$src")
  name=$(basename "${src%.*}")
  out="$dir/$name.ogg"
  ffmpeg -loglevel error -y -i "$src" -c:a libvorbis -qscale:a 5 -map_metadata 0 "$out"
  echo "Converted: $out"
done
