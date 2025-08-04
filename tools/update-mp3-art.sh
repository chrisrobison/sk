#!/bin/bash
# update-mp3-art.sh — Update MP3 with album art and lyrics based on directory structure
# Usage: ./update-mp3-art.sh */*/song.wav

set -euo pipefail

BAND="The Suicidal Kennedys"

for WAV_FILE in "$@"; do
  SONG_DIR=$(dirname "${WAV_FILE}")
  SONG_NAME=$(basename "${SONG_DIR}")
  ALBUM_DIR=$(dirname "${SONG_DIR}")
  ALBUM_NAME=$(basename "${ALBUM_DIR}")

  MP3_TMP="$SONG_DIR/song_tmp.mp3"
  MP3_OUT="$SONG_DIR/song.mp3"

  ART_FILE=""
  for ext in jpg png jpeg; do
    if [[ -f "$SONG_DIR/art.$ext" ]]; then
      ART_FILE="$SONG_DIR/art.$ext"
      break
    fi
  done
  if [[ -z "$ART_FILE" ]]; then
    echo "No album art found for $SONG_NAME, skipping." >&2
    continue
  fi

  LYRICS_FILE="$SONG_DIR/lyrics.txt"
  LYRICS=""
  if [[ -f "$LYRICS_FILE" ]]; then
    LYRICS=$(<"$LYRICS_FILE")
  fi

  TRACK_NUMBER="${SONG_NAME%%_*}"
  SONG_TITLE="${SONG_NAME#*_}"
  SONG_TITLE=${SONG_TITLE//_/ }
  ALBUM_NAME=${ALBUM_NAME//_/ }

  ffmpeg -loglevel error -y \
    -i "$WAV_FILE" \
    -i "$ART_FILE" \
    -map 0:a -map 1 \
    -ar 44100 \
    -c:a libmp3lame -b:a 320k \
    -c:v mjpeg \
    -id3v2_version 3 \
    -metadata artist="$BAND" \
    -metadata album="$ALBUM_NAME" \
    -metadata title="$SONG_TITLE" \
    -metadata track="$TRACK_NUMBER" \
    -metadata:s:v title="Album cover" \
    -metadata:s:v comment="Cover (front)" \
    ${LYRICS:+-metadata lyrics="$LYRICS"} \
    "$MP3_TMP"

  mv "$MP3_TMP" "$MP3_OUT"
  echo "Processed: $MP3_OUT"
done
