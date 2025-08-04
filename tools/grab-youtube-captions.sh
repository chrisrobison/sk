#!/bin/bash
# Usage: ./grab-youtube-captions.sh "https://www.youtube.com/playlist?list=YOUR_PLAYLIST_ID"

PLAYLIST_URL="$1"
if [[ -z "$PLAYLIST_URL" ]]; then
  echo "Usage: $0 <YouTube Playlist URL>"
  exit 1
fi

# Create a working directory
WORKDIR="captions_$(date +%s)"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

# Get list of video URLs from playlist
echo "Fetching video URLs from playlist..."
yt-dlp --flat-playlist --get-id "$PLAYLIST_URL" | while read -r VIDEO_ID; do
  VIDEO_URL="https://www.youtube.com/watch?v=$VIDEO_ID"
  echo "Processing $VIDEO_URL"

  # Download auto-generated captions (VTT format)
  yt-dlp --write-auto-sub --sub-lang en --skip-download  --no-continue --no-overwrites --force-overwrites "$VIDEO_URL"

  # Convert .vtt to .srt
  for VTT in *.vtt; do
    [[ -f "$VTT" ]] || continue
    SRT="${VTT%.vtt}.srt"
    ffmpeg -y -i "$VTT" "$SRT"
    echo "Converted $VTT → $SRT"
  done

done

echo "All done. Captions saved in: $WORKDIR"
