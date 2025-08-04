#!/bin/bash
# Usage: ./make-video.sh */song.wav
# Creates videos for multiple audio files, using art.png in each directory

# Check if any arguments provided
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 audio_file1 [audio_file2 ...]"
  echo "Example: $0 */song.wav"
  echo "Expected: art.mp4, art.gif, or art.png file in same directory as each audio file"
  echo "Priority: art.mp4 > art.gif > art.png (uses first found)"
  exit 1
fi

# Function to process a single audio file
process_audio_file() {
  local AUDIO="$1"

  # Get the directory and filename
  local DIR=$(dirname "$AUDIO")
  local BASENAME=$(basename "$AUDIO")
  local NAME_WITHOUT_EXT="${BASENAME%.*}"

  # Strip leading digits+underscore from the folder name for the song title
  local DIR_NAME=$(basename "$DIR")
  local SONG_TITLE="${DIR_NAME#[0-9]*_}"
  SONG_TITLE="${SONG_TITLE//_/ }"

  # Extract album title (parent directory), convert underscores to spaces
  local ALBUM_TITLE=$(basename "$(dirname "$DIR")")
  ALBUM_TITLE="${ALBUM_TITLE//_/ }"

  local BAND_NAME="The Suicidal Kennedys"

  # Define paths
  local BACKGROUND_IMAGE="$DIR/art.png"  # required for background
  local OUTPUT="$DIR/${NAME_WITHOUT_EXT}-mobile.mp4"

  # Look for art file in order of preference: MP4, GIF, PNG (fallback)
  local IMAGE=""
  if [[ -f "$DIR/art.mp4" ]]; then
    IMAGE="$DIR/art.mp4"
  elif [[ -f "$DIR/art.gif" ]]; then
    IMAGE="$DIR/art.gif"
  elif [[ -f "$DIR/art.png" ]]; then
    IMAGE="$DIR/art.png"
  fi

  echo "Processing: $AUDIO"

  # Check if audio file exists
  if [[ ! -f "$AUDIO" ]]; then
    echo "  ❌ Error: Audio file '$AUDIO' not found"
    return 1
  fi

  # Check if art.png exists (required for background)
  if [[ ! -f "$BACKGROUND_IMAGE" ]]; then
    echo "  ❌ Error: Background image '$BACKGROUND_IMAGE' not found (required)"
    return 1
  fi

  # Check if foreground art file exists
  if [[ -z "$IMAGE" ]]; then
    echo "  ❌ Error: No foreground art file found (looking for art.mp4, art.gif, or art.png in '$DIR')"
    return 1
  fi

  # Warn if output exists
  if [[ -f "$OUTPUT" ]]; then
    echo "  ⚠️  Warning: '$OUTPUT' already exists, overwriting..."
  fi

  # Get duration of the audio
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
  echo "  📹 Creating: $OUTPUT"

local DRAW_TEXT=$(cat <<EOF
${BAND_NAME}
${ALBUM_TITLE}
${SONG_TITLE}
EOF
)

# Escape for ffmpeg
DRAW_TEXT=${DRAW_TEXT//\\/\\\\}
DRAW_TEXT=${DRAW_TEXT//\'/\\\'}
DRAW_TEXT=${DRAW_TEXT//:/\\:}

# Detect if image/video is animated
  local IS_ANIMATED=false
  local IMAGE_EXT=${IMAGE##*.}
  IMAGE_EXT=$(printf '%s' "$IMAGE_EXT" | tr '[:upper:]' '[:lower:]')

  if [[ "$IMAGE_EXT" == "mp4" ]]; then
    # mp4 with video stream
    if ffprobe -v error -select_streams v:0 -show_entries stream=codec_type \
        -of csv=p=0 "$IMAGE" 2>/dev/null | grep -q video; then
      IS_ANIMATED=true
    fi
  else
    # GIF or PNG: check frame count
    local FRAME_COUNT
    FRAME_COUNT=$(ffprobe -v error -select_streams v:0 -count_frames \
      -show_entries stream=nb_read_frames -of csv=p=0 "$IMAGE" 2>/dev/null)
    if [[ "$FRAME_COUNT" -gt 1 ]]; then
      IS_ANIMATED=true
    fi
  fi

  # Common drawtext options
  local FONTFILE="/Users/cdr/Library/Fonts/DejaVuSans-Bold.ttf"
  local FONT_COLOR="white"
  local FONTSIZE=36
  local BORDERW=2
  local BORDERCOLOR="black"
  local TEXT_POSITION="x=w-tw-30:y=h-th-30"

  if [[ "$IS_ANIMATED" == true ]]; then
    ffmpeg -y \
      -loop 1 -i "$BACKGROUND_IMAGE" \
      -stream_loop -1 -i "$IMAGE" \
      -i "$AUDIO" \
      -filter_complex "
        [0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,gblur=sigma=20[bg];
        [1:v]scale=1080:1920:force_original_aspect_ratio=decrease[fg];
        [bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto[base];
        [base]drawtext=fontfile=${FONTFILE}:\
text='${DRAW_TEXT}':\
fontcolor=${FONT_COLOR}:fontsize=${FONTSIZE}:borderw=${BORDERW}:bordercolor=${BORDERCOLOR}:\
${TEXT_POSITION}
      " \
      -map 2:a \
      -c:v libx264 -preset veryfast -pix_fmt yuv420p \
      -c:a aac -b:a 192k \
      -t "$DURATION" -movflags +faststart \
      "$OUTPUT" -v error -stats

  else
    ffmpeg -y \
      -loop 1 -i "$BACKGROUND_IMAGE" \
      -loop 1 -i "$IMAGE" \
      -i "$AUDIO" \
      -filter_complex "
        [0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,gblur=sigma=20[bg];
        [1:v]scale=1080:1920:force_original_aspect_ratio=decrease[fg];
        [bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto[base];
        [base]drawtext=fontfile=${FONTFILE}:\
text='${DRAW_TEXT}':\
fontcolor=${FONT_COLOR}:fontsize=${FONTSIZE}:borderw=${BORDERW}:bordercolor=${BORDERCOLOR}:\
${TEXT_POSITION}
      " \
      -map 2:a \
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
