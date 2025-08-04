#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <image1.png> [image2.png ...]"
  exit 1
fi

for img in "$@"; do
  if [[ ! -f "$img" ]]; then
    echo "File not found: $img" >&2
    continue
  fi
  # resize and convert to JPG (3000×3000), output as .jpg then remove original .png
  mogrify -format jpg -resize 3000x3000\! "$img"
done
