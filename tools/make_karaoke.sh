#!/bin/bash
# Usage: ./make_karaoke_videos.sh path/to/ALBUM/*/

BAND="The Suicidal Kennedys"

for DIR in "$@"; do
  if [[ ! -d "$DIR" ]]; then
    echo "❌ Skipping '$DIR' (not a directory)"
    continue
  fi

  cd "$DIR" || continue
  echo "🎬 Processing: $DIR"

  if [[ ! -f "karaoke.wav" || ! -f "lyrics.ass" || ! -f "art.mp4" ]]; then
    echo "⚠️  Missing one or more required files — skipping"
    cd - >/dev/null
    continue
  fi

  SONG_DIR=$(basename "$PWD")
  SONG_TITLE="${SONG_DIR#[0-9]*_}"
  SONG_TITLE="${SONG_TITLE//_/ }"
  TITLECARD="titlecard.png"
  OUTPUT="karaoke.mp4"

  echo "📼 Generating titlecard..."
  magick -size 1920x1080 canvas:black \
    -fill white -stroke none -gravity center \
    -pointsize 72 -annotate +0-60 "$BAND" \
    -pointsize 48 -annotate +0+40 "$SONG_TITLE" \
    "$TITLECARD"

  echo "⏱️  Measuring duration..."
  DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 karaoke.wav)

  echo "🎥 Building karaoke video..."
  ffmpeg -y \
    -loop 1 -t 3 -i "$TITLECARD" \
    -stream_loop -1 -i art.mp4 \
    -i karaoke.wav \
    -filter_complex "\
      [1:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=20[bg]; \
      [bg]fade=in:st=2:d=1:alpha=1[animated]; \
      [0:v]fade=out:st=2:d=1:alpha=1[title]; \
      [title][animated]overlay[combined]; \
      [combined]ass=lyrics.ass[subbed]" \
    -map "[subbed]" -map 2:a \
    -t "$DURATION" \
    -c:v libx264 -preset veryfast -pix_fmt yuv420p \
    -c:a aac -b:a 192k -movflags +faststart \
    "$OUTPUT"

  echo "✅ Finished: $OUTPUT"
  echo ""

  cd - >/dev/null
done

echo "🎉 All videos complete!"
