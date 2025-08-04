#!/bin/bash
# update-mp3-and-flac-art.sh — Update MP3 and FLAC with album art and lyrics based on directory structure
# Usage: ./update-mp3-and-flac-art.sh */*/song.wav

set -euo pipefail

BAND="The Suicidal Kennedys"

for WAV_FILE in "$@"; do
  SONG_DIR=$(dirname "$WAV_FILE")
  SONG_NAME=$(basename "$SONG_DIR")
  ALBUM_DIR=$(dirname "$SONG_DIR")
  ALBUM_NAME=$(basename "$ALBUM_DIR")

  ART_FILE=""
  for ext in jpg png jpeg; do
    if [[ -f "$SONG_DIR/art.$ext" ]]; then
      ART_FILE="$SONG_DIR/art.$ext"
      break
    fi
  done
  [[ -n "$ART_FILE" ]] || { echo "No album art for $SONG_NAME, skipping." >&2; continue; }

  LYRICS=""
  [[ -f "$SONG_DIR/lyrics.txt" ]] && LYRICS=$(<"$SONG_DIR/lyrics.txt")

  TRACK_NUMBER="${SONG_NAME%%_*}"
  SONG_TITLE="${SONG_NAME#*_}"
  SONG_TITLE=${SONG_TITLE//_/ }
  ALBUM_NAME=${ALBUM_NAME//_/ }

  # MP3
  MP3_TMP="$SONG_DIR/song_tmp.mp3"
  MP3_OUT="$SONG_DIR/song.mp3"
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

  # FLAC
  FLAC_OUT="$SONG_DIR/song.flac"
  ffmpeg -loglevel error -y \
    -i "$WAV_FILE" \
    -i "$ART_FILE" \
    -map 0:a -map 1 \
    -c:a flac \
    -c:v png \
    -disposition:v:0 attached_pic \
    -metadata:s:v:0 title="Album cover" \
    -metadata:s:v:0 comment="Cover (front)" \
    -metadata artist="$BAND" \
    -metadata album="$ALBUM_NAME" \
    -metadata title="$SONG_TITLE" \
    -metadata track="$TRACK_NUMBER" \
    ${LYRICS:+-metadata lyrics="$LYRICS"} \
    "$FLAC_OUT"
  echo "Processed: $FLAC_OUT"
done
