#!/bin/bash
# Usage: ./make-karaoke.sh ALBUM/*/

set -e

FONT="/System/Library/Fonts/Supplemental/Arial.ttf"

for DIR in "$@"; do
  echo "🎬 Processing: $DIR"

  VOCALS="$DIR/stems/vocals.wav"
  AUDIO="$DIR/karaoke.wav"
  SRT="$DIR/lyrics.srt"
  BG="$DIR/art.png"
  FG="$DIR/art.mp4"
  OUTPUT="$DIR/karaoke.mp4"

  # Generate lyrics.srt using whisper-cli
  if [[ ! -f "$SRT" && -f "$VOCALS" ]]; then
    echo "📝 Generating lyrics.srt with whisper-cli..."
    whisper-cli "$VOCALS" --model /Users/cdr/.local/models/ggml-medium.en.bin -osrt --output_file "$DIR/lyrics"
  fi

  # Create karaoke.wav if missing
  if [[ ! -f "$AUDIO" ]]; then
    echo "🎧 Creating karaoke.wav by mixing stems (excluding vocals)..."
    STEMS=()
    for STEM in "$DIR"/stems/*.wav; do
      [[ "$STEM" == "$VOCALS" ]] && continue
      STEMS+=("-i" "$STEM")
    done
    FILTERS=$(for i in $(seq 0 $(( ${#STEMS[@]}/2 - 1 ))); do echo -n "[$i:0]"; done)
    ffmpeg "${STEMS[@]}" -filter_complex "${FILTERS}amix=inputs=$(( ${#STEMS[@]}/2 )):normalize=0" -y "$AUDIO"
  fi

  # Set fallback foreground
  if [[ ! -f "$FG" ]]; then
    FG="$BG"
    LOOP_IMAGE="-loop 1"
  else
    LOOP_IMAGE="-stream_loop -1"
  fi

  DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO")
  echo "⏱️  Duration: ${DURATION}s"

  ffmpeg -y \
    -loop 1 -i "$BG" \
    $LOOP_IMAGE -i "$FG" \
    -i "$AUDIO" \
    -filter_complex "
      [0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=20[bg];
      [1:v]scale=1920:1080:force_original_aspect_ratio=decrease[fg];
      [bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto[base];
      [base]subtitles='$SRT':force_style='FontName=Arial,FontSize=40,PrimaryColour=&HFFFFFF&,OutlineColour=&H000000&,BorderStyle=1,Outline=2'
    " \
    -map 2:a \
    -c:v libx264 -preset fast -t "$DURATION" \
    -c:a aac -b:a 192k -pix_fmt yuv420p -movflags +faststart \
    "$OUTPUT"

  echo "✅ Created: $OUTPUT"
done

echo "🎉 All done."
