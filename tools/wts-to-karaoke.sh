#!/bin/bash
# Usage: ./wts_to_karaoke.sh path/to/vocals.wts

set -e

WTS_FILE="$1"
[[ -f "$WTS_FILE" ]] || { echo "❌ No such file: $WTS_FILE"; exit 1; }

SONG_DIR=$(dirname "$(dirname "$WTS_FILE")")
AUDIO_FILE="$SONG_DIR/karaoke.wav"
[[ -f "$AUDIO_FILE" ]] || { echo "❌ Missing karaoke.wav at $AUDIO_FILE"; exit 1; }

# Determine background
if [[ -f "$SONG_DIR/art.mp4" ]]; then
  BG_INPUT="-i \"$SONG_DIR/art.mp4\""
  BG_INDEX=1
elif [[ -f "$SONG_DIR/art.gif" ]]; then
  BG_INPUT="-ignore_loop 0 -i \"$SONG_DIR/art.gif\""
  BG_INDEX=1
elif [[ -f "$SONG_DIR/art.png" ]]; then
  BG_INPUT="-loop 1 -i \"$SONG_DIR/art.png\""
  BG_FILTER=",scale=1920:1080,zoompan=z='zoom+0.0005':d=1"
  BG_INDEX=1
else
  echo "❌ No art file found in $SONG_DIR"
  exit 1
fi

# Read the ffmpeg command from WTS
FFMPEG_CMD=$(cat "$WTS_FILE")

# Replace inputs
FFMPEG_CMD=$(echo "$FFMPEG_CMD" \
  | sed -E "s|-f lavfi -i \"color=s=[0-9]+x[0-9]+:c=black(:r=[0-9]+)?\"|$BG_INPUT|" \
  | sed -E "s|\"[^\"]+\.wav\"|\"$AUDIO_FILE\"|" \
  | sed -E "s|\[1:v\]|\[${BG_INDEX}:v\]$BG_FILTER|g")


# Force output filename
OUTFILE="$SONG_DIR/karaoke-lyricvideo.mp4"

# Force output filename
FFMPEG_CMD=$(echo "$FFMPEG_CMD" | sed -E "s|\"[^ ]+\.mp4\"|\"$OUTFILE\"|")

echo "▶️ Rendering lyric video: $OUTFILE"
eval "$FFMPEG_CMD"
