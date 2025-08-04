#!/usr/bin/env bash
# convert-44k.sh — convert one or more 48 kHz WAVs to 44.1 kHz WAVs named "<orig>-44k.wav"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 path/to/*.wav"
  exit 1
fi

for input in "$@"; do
  dir="$(dirname "$input")"
  base="$(basename "$input" .wav)"
  ffmpeg -y -i "$input" -ar 44100 "$dir/${base}-44k.wav"
done
