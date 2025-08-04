#!/bin/bash
# Usage: ./make-video.sh */song.wav
# Creates videos for multiple audio files, using art.png in each directory
# and overlays a static qr.png in the bottom-left corner

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 audio_file1 [audio_file2 ...]"
  echo "Example: $0 */song.wav"
  echo "Expected: art.mp4, art.gif, or art.png file in same directory as each audio file"
  echo "Priority: art.mp4 > art.gif > art.png (uses first found)"
  echo "          and qr.png (for QR overlay)"
  exit 1
fi

process_audio_file() {
  local AUDIO="$1"

  local DIR=$(dirname "$AUDIO")
  local BASENAME=$(basename "$AUDIO")
  local NAME_WITHOUT_EXT="${BASENAME%.*}"

  local DIR_NAME=$(basename "$DIR")
  local SONG_TITLE="${DIR_NAME#[0-9]*_}"
  SONG_TITLE="${SONG_TITLE//_/ }"

  local ALBUM_TITLE=$(basename "$(dirname "$DIR")")
  ALBUM_TITLE="\"${ALBUM_TITLE//_/ }\""

  local BAND_NAME="The Suicidal Kennedys"

  local BACKGROUND_IMAGE="$DIR/art.png"
  local OUTPUT="$DIR/${NAME_WITHOUT_EXT}.mp4"
  
  local QR_IMAGE="$DIR/qr.png"
  if [[ -f "$DIR/qr.png" ]]; then
    QR_IMAGE="$DIR/qr.png"
  elif [[ -f "/Users/cdr/Downloads/qr.png" ]]; then
    QR_IMAGE="/Users/cdr/Downloads/qr.png"
  fi

  local IMAGE=""
  if [[ -f "$DIR/art.mp4" ]]; then
    IMAGE="$DIR/art.mp4"
  elif [[ -f "$DIR/art.gif" ]]; then
    IMAGE="$DIR/art.gif"
  elif [[ -f "$DIR/art.png" ]]; then
    IMAGE="$DIR/art.png"
  fi

  echo "Processing: $AUDIO"

  if [[ ! -f "$AUDIO" ]]; then
    echo "  ❌ Error: Audio file '$AUDIO' not found"
    return 1
  fi

  if [[ ! -f "$BACKGROUND_IMAGE" ]]; then
    echo "  ❌ Error: Background image '$BACKGROUND_IMAGE' not found (required)"
    return 1
  fi

  if [[ -z "$IMAGE" ]]; then
    echo "  ❌ Error: No foreground art file found (looking for art.mp4, art.gif, or art.png in '$DIR')"
    return 1
  fi

  if [[ ! -f "$QR_IMAGE" ]]; then
    echo "  ⚠️  Warning: QR image '$QR_IMAGE' not found. Using placeholder."
    QR_IMAGE="/tmp/blank.png"
    convert -size 1x1 xc:none "$QR_IMAGE"
  fi

  if [[ -f "$OUTPUT" ]]; then
    echo "  ⚠️  Warning: '$OUTPUT' already exists, overwriting..."
  fi

  local DURATION
  DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$AUDIO" 2>/dev/null)
  if [[ -z "$DURATION" || "$DURATION" == "N/A" ]]; then
    echo "  ❌ Error: Could not determine audio duration for '$AUDIO'"
    return 1
  fi

  echo "  🎵 Duration: ${DURATION}s"
  echo "  🌫️  Background: $(basename "$BACKGROUND_IMAGE") (blurred)"
  echo "  🖼️  Foreground: $(basename "$IMAGE")"
  echo "  📌 QR Code: $(basename "$QR_IMAGE")"
  echo "  📹 Creating: $OUTPUT"

local DRAW_TEXT=$(cat <<EOF
${BAND_NAME}
${ALBUM_TITLE}
${SONG_TITLE}
EOF
)
  DRAW_TEXT=${DRAW_TEXT//\\/\\\\}
  DRAW_TEXT=${DRAW_TEXT//\'/\\\'}
  DRAW_TEXT=${DRAW_TEXT//:/\\:}

  local IS_ANIMATED=false
  local IMAGE_EXT=${IMAGE##*.}
  IMAGE_EXT=$(printf '%s' "$IMAGE_EXT" | tr '[:upper:]' '[:lower:]')

  if [[ "$IMAGE_EXT" == "mp4" ]]; then
    if ffprobe -v error -select_streams v:0 -show_entries stream=codec_type \
        -of csv=p=0 "$IMAGE" 2>/dev/null | grep -q video; then
      IS_ANIMATED=true
    fi
  else
    local FRAME_COUNT
    FRAME_COUNT=$(ffprobe -v error -select_streams v:0 -count_frames \
      -show_entries stream=nb_read_frames -of csv=p=0 "$IMAGE" 2>/dev/null)
    if [[ "$FRAME_COUNT" -gt 1 ]]; then
      IS_ANIMATED=true
    fi
  fi

  local FONTFILE="/Users/cdr/Library/Fonts/DejaVuSans-Bold.ttf"
  local FONT_COLOR="white"
  local FONTSIZE=36
  local BORDERW=2
  local BORDERCOLOR="black"
  local TEXT_POSITION="x=w-tw-30:y=h-th-30"

  local MAP_AUDIO_INDEX=3

  if [[ "$IS_ANIMATED" == true ]]; then
    ffmpeg -y \
      -loop 1 -i "$BACKGROUND_IMAGE" \
      -stream_loop -1 -i "$IMAGE" \
      -loop 1 -i "$QR_IMAGE" \
      -i "$AUDIO" \
      -filter_complex "
        [0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=20[bg];
        [1:v]scale=1920:1080:force_original_aspect_ratio=decrease[fg];
        [2:v]scale=350:-1[qr];
        [bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto[tmp];
        [tmp][qr]overlay=30:H-h-30:format=auto[base];
        [base]drawtext=fontfile=${FONTFILE}:\
text='${DRAW_TEXT}':\
fontcolor=${FONT_COLOR}:fontsize=${FONTSIZE}:borderw=${BORDERW}:bordercolor=${BORDERCOLOR}:\
${TEXT_POSITION}
      " \
      -map ${MAP_AUDIO_INDEX}:a \
      -c:v libx264 -preset veryfast -pix_fmt yuv420p \
      -c:a aac -b:a 192k \
      -t "$DURATION" -movflags +faststart \
      "$OUTPUT" -v error -stats
  else
    ffmpeg -y \
      -loop 1 -i "$BACKGROUND_IMAGE" \
      -loop 1 -i "$IMAGE" \
      -loop 1 -i "$QR_IMAGE" \
      -i "$AUDIO" \
      -filter_complex "
        [0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=20[bg];
        [1:v]scale=1920:1080:force_original_aspect_ratio=decrease[fg];
        [2:v]scale=350:-1[qr];
        [bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto[tmp];
        [tmp][qr]overlay=30:H-h-30:format=auto[base];
        [base]drawtext=fontfile=${FONTFILE}:\
text='${DRAW_TEXT}':\
fontcolor=${FONT_COLOR}:fontsize=${FONTSIZE}:borderw=${BORDERW}:bordercolor=${BORDERCOLOR}:\
${TEXT_POSITION}
      " \
      -map ${MAP_AUDIO_INDEX}:a \
      -c:v libx264 -preset veryfast -pix_fmt yuv420p \
      -c:a aac -b:a 192k \
      -t "$DURATION" -movflags +faststart \
      "$OUTPUT" -v error -stats
  fi

  if [[ $? -eq 0 ]]; then
    echo "  ✅ Success: $OUTPUT"
    echo ""
    return 0
  else
    echo "  ❌ Failed to create: $OUTPUT"
    echo ""
    return 1
  fi
}

# Main execution
echo "🎬 Starting batch video creation..."
echo "Found $# audio files to process"
echo ""

SUCCESS_COUNT=0
FAILURE_COUNT=0

# Process each audio file
for AUDIO_FILE in "$@"; do
  if process_audio_file "$AUDIO_FILE"; then
    ((SUCCESS_COUNT++))
  else
    ((FAILURE_COUNT++))
  fi
done

# Summary
echo "📊 Batch processing complete!"
echo "✅ Successful: $SUCCESS_COUNT"
echo "❌ Failed: $FAILURE_COUNT"
echo "📁 Total processed: $((SUCCESS_COUNT + FAILURE_COUNT))"

if [[ $FAILURE_COUNT -gt 0 ]]; then
  exit 1
fi
