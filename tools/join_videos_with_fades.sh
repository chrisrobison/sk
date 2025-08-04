#!/bin/bash
# join_videos_with_fades.sh — Combine MP4s with pre-song titlecards, crossfades, and proper sync

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 output.mp4 input1.mp4 input2.mp4 [input3.mp4 ...]"
  exit 1
fi

OUTPUT="$1"
shift
INPUTS=("$@")

TMP_DIR=$(mktemp -d)
FONT="/Users/cdr/Library/Fonts/DejaVuSans-Bold.ttf"
LOGO="/Users/cdr/Downloads/sk/logo.png"
BAND="The Suicidal Kennedys"
TRANSITION_DUR=1
TITLECARD_DUR=6

make_title_card() {
  local OUTFILE="$1"
  local ALBUM="$2"
  local SONG="$3"

  ffmpeg -y \
    -f lavfi -i color=black:s=1920x1080:d=$TITLECARD_DUR \
    -f lavfi -i anullsrc=r=48000:cl=stereo \
    -loop 1 -i "$LOGO" \
    -filter_complex "
      [0:v]fps=30,format=yuv420p,settb=1/30,setpts=N/30/TB[base];
      [2:v]scale=200:-1[logo];
      [base][logo]overlay=x=100:y=((H-h)/2)-200[bg];
      [bg]drawtext=fontfile=${FONT}:text='${SONG}':fontcolor=white:fontsize=64:x=320:y=240:borderw=2:bordercolor=black,\
           drawtext=fontfile=${FONT}:text='\"${ALBUM}\"':fontcolor=white:fontsize=42:x=320:y=320:borderw=1:bordercolor=black,\
           drawtext=fontfile=${FONT}:text='${BAND}':fontcolor=white:fontsize=36:x=320:y=380:borderw=1:bordercolor=black[v]
    " \
    -map "[v]" -map 1:a \
    -shortest -t $TITLECARD_DUR \
    -c:v libx264 -c:a aac -b:a 192k -pix_fmt yuv420p "$OUTFILE"
}

SEGMENTS=()
DURATIONS=()
i=0

for VIDEO in "${INPUTS[@]}"; do
  DIR=$(dirname "$VIDEO")
  SONG_DIR=$(basename "$DIR")
  ALBUM_DIR=$(basename "$(dirname "$DIR")")

  SONG_TITLE="${SONG_DIR#[0-9]*_}"
  SONG_TITLE="${SONG_TITLE//_/ }"
  ALBUM_TITLE="${ALBUM_DIR//_/ }"

  TITLE="$TMP_DIR/title_${i}.mp4"
  make_title_card "$TITLE" "$ALBUM_TITLE" "$SONG_TITLE"
  SEGMENTS+=("$TITLE")
  DURATIONS+=("$TITLECARD_DUR")

  VID="$TMP_DIR/video_${i}.mp4"
  ffmpeg -y -i "$VIDEO" \
    -vf "fps=30,format=yuv420p,settb=1/30,setpts=N/30/TB,scale=1920:1080" \
    -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k "$VID"

  SEGMENTS+=("$VID")

  # Get duration of video part
  DURATION=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VID")
  DURATION_INT=$(printf "%.0f" "$DURATION")
  DURATIONS+=("$DURATION_INT")

  ((i++))
done

INPUT_ARGS=()
for SEG in "${SEGMENTS[@]}"; do
  INPUT_ARGS+=("-i" "$SEG")
done

NUM_SEGMENTS=${#SEGMENTS[@]}
FILTER=""
OFFSET=0

for ((i=0; i<NUM_SEGMENTS-1; i++)); do
  A=$i
  B=$((i+1))
  OUT="v$B"
  AOUT="a$B"

  OFFSET=$((OFFSET + DURATIONS[$A] - TRANSITION_DUR))

  if [ "$i" -eq 0 ]; then
    FILTER="[${A}:v][${B}:v]xfade=transition=fade:duration=$TRANSITION_DUR:offset=$OFFSET[$OUT]; \
            [${A}:a][${B}:a]acrossfade=d=$TRANSITION_DUR[$AOUT]"
  else
    FILTER="$FILTER;[v$A][${B}:v]xfade=transition=fade:duration=$TRANSITION_DUR:offset=$OFFSET[v$B]; \
             [a$A][${B}:a]acrossfade=d=$TRANSITION_DUR[a$B]"
  fi
done

LAST_IDX=$((NUM_SEGMENTS - 1))
FINAL_V="v$LAST_IDX"
FINAL_A="a$LAST_IDX"

echo "🎞️  Rendering final video: $OUTPUT"
ffmpeg "${INPUT_ARGS[@]}" -filter_complex "$FILTER" \
  -map "[$FINAL_V]" -map "[$FINAL_A]" \
  -c:v libx264 -preset fast -crf 22 -c:a aac -b:a 192k \
  -pix_fmt yuv420p -movflags +faststart "$OUTPUT"

rm -rf "$TMP_DIR"
echo "✅ Done! Output saved to: $OUTPUT"
